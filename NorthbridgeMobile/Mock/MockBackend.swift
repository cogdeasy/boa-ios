//
//  MockBackend.swift
//  NorthbridgeMobile
//
//  In-process stand-in for core-banking (:8080) and the payments hub (:8081).
//  Implements the subset of the platform API contract used by the app, with the
//  local-profile seed users and accounts. State lives in memory for the app run.
//

import Foundation
import NBFoundation

final class MockBackend {

    static let shared = MockBackend()

    struct Reply {
        let status: Int
        let body: Data
    }

    private struct User {
        let username: String
        let password: String
        let role: String
        let cif: String?
    }

    private let users: [User] = [
        User(username: "dana.whitfield", password: "Welcome1!", role: "CUSTOMER", cif: "100000001"),
        User(username: "marcus.oyelaran", password: "Welcome1!", role: "CUSTOMER", cif: "100000002"),
        User(username: "teller01", password: "Teller#2019", role: "TELLER", cif: nil),
        User(username: "ops.batch", password: "Ops#Batch1", role: "OPS", cif: nil)
    ]

    static let suspenseGL = "307000555010"

    private let queue = DispatchQueue(label: "com.northbridge.mobile.mockbackend")
    private var customers: [String: Customer] = [:]
    private var accounts: [String: MockAccount] = [:]
    private var transactions: [String: [Transaction]] = [:]
    private var payees: [String: [Payee]] = [:]
    private var payments: [String: [Payment]] = [:]
    private var transfers: [String: [String: String]] = [:]
    private var idempotencyKeys: Set<String> = []
    private var nextTransactionId = 99_900
    private var transferSequence = 230
    private var paymentSequence = 4_410

    static let dailyTransferLimit = Decimal(10_000)

    init(seed: Bool = true) {
        if seed { MockSeedData.load(into: self) }
    }

    func reset() {
        queue.sync {
            customers = [:]; accounts = [:]; transactions = [:]; payees = [:]; payments = [:]
            transfers = [:]; idempotencyKeys = []
        }
        MockSeedData.load(into: self)
    }

    // MARK: - Seeding

    func seedCustomer(_ customer: Customer) { queue.sync { customers[customer.cif] = customer } }
    func seedAccount(_ account: MockAccount) { queue.sync { accounts[account.accountNumber] = account } }
    func seedPayees(_ list: [Payee], cif: String) { queue.sync { payees[cif] = list } }
    func seedPayments(_ list: [Payment], cif: String) { queue.sync { payments[cif] = list } }

    /// Seeds history ending at the account's current ledger balance (newest first).
    func seedTransactions(accountNumber: String, entries: [MockSeedData.Entry]) {
        queue.sync {
            guard let account = accounts[accountNumber] else { return }
            var balance = account.ledger
            var list: [Transaction] = []
            for entry in entries.sorted(by: { $0.daysAgo < $1.daysAgo }) {
                nextTransactionId += 1
                let date = Calendar.current.date(byAdding: .day, value: -entry.daysAgo, to: Date())!
                let posted = Calendar.current.date(bySettingHour: entry.hour, minute: (nextTransactionId * 7) % 60,
                                                   second: 11, of: date)!
                list.append(Transaction(id: nextTransactionId, accountNumber: accountNumber,
                                        postedAt: BankDates.timestampString(posted),
                                        businessDate: BankDates.businessDateString(date),
                                        type: entry.amount < 0 ? "DEBIT" : "CREDIT",
                                        channel: entry.channel,
                                        amount: Money(amount: entry.amount),
                                        runningBalance: Money(amount: balance),
                                        description: entry.description,
                                        status: entry.daysAgo == 0 && entry.channel == .card ? "PENDING" : "POSTED"))
                balance -= entry.amount
            }
            transactions[accountNumber] = list
        }
    }

    // MARK: - Routing

    func handle(method: String, url: URL, headers: [String: String], body: Data?) -> Reply {
        queue.sync { route(method: method, url: url, headers: headers, body: body) }
    }

    private func route(method: String, url: URL, headers: [String: String], body: Data?) -> Reply {
        guard let user = authenticate(headers) else {
            return error(401, "UNAUTHORIZED", "Full authentication is required to access this resource")
        }
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let query = Dictionary((components?.queryItems ?? []).map { ($0.name, $0.value ?? "") },
                               uniquingKeysWith: { first, _ in first })
        var path = url.path
        if path.hasPrefix("/api/v1/payments") {
            path = "/payments" + path.dropFirst("/api/v1/payments".count)
        } else if path.hasPrefix("/api/v1") {
            path = String(path.dropFirst("/api/v1".count))
        }
        let parts = path.split(separator: "/").map(String.init)

        switch (method, parts.count, parts.first) {
        case ("GET", 2, "customers") where parts[1] == "me":
            return getCurrentCustomer(user: user)
        case ("GET", 2, "customers"):
            return getCustomer(parts[1], user: user)
        case ("GET", 3, "customers") where parts[2] == "accounts":
            return getCustomerAccounts(parts[1], user: user)
        case ("GET", 2, "accounts"):
            return getAccount(parts[1], user: user)
        case ("GET", 3, "accounts") where parts[2] == "transactions":
            return getTransactions(parts[1], query: query, user: user)
        case ("GET", 2, "transactions") where parts[1] == "search":
            return searchTransactions(query: query, user: user)
        case ("POST", 1, "transfers"):
            return postTransfer(body: body, user: user)
        case ("GET", 2, "transfers"):
            guard let record = transfers[parts[1]] else { return error(404, "TRANSFER_NOT_FOUND", "Transfer not found") }
            return ok(record)
        case ("GET", 2, "payments") where parts[1] == "payees":
            return ok(payees[query["cif"] ?? ""] ?? [])
        case ("POST", 2, "payments") where parts[1] == "bill":
            return postBill(body: body, user: user)
        case ("POST", 2, "payments") where parts[1] == "p2p":
            return postP2P(body: body, user: user)
        case ("GET", 2, "payments") where parts[1] == "history":
            return ok((payments[query["cif"] ?? ""] ?? []).sorted { $0.createdAt > $1.createdAt })
        default:
            return error(404, "NOT_FOUND", "No handler for \(method) \(path)")
        }
    }

    // MARK: - core-banking

    private func getCurrentCustomer(user: User) -> Reply {
        guard user.role == "CUSTOMER", let cif = user.cif else { return error(403, "FORBIDDEN", "Access is denied") }
        guard let customer = customers[cif] else { return error(404, "CUSTOMER_NOT_FOUND", "Customer not found") }
        return ok(customer)
    }

    private func getCustomer(_ cif: String, user: User) -> Reply {
        guard canAccess(cif: cif, user: user) else { return error(403, "FORBIDDEN", "Access is denied") }
        guard let customer = customers[cif] else { return error(404, "CUSTOMER_NOT_FOUND", "Customer not found") }
        return ok(customer)
    }

    private func getCustomerAccounts(_ cif: String, user: User) -> Reply {
        guard canAccess(cif: cif, user: user) else { return error(403, "FORBIDDEN", "Access is denied") }
        let list = accounts.values.filter { $0.cif == cif }.sorted { $0.accountNumber < $1.accountNumber }
        return ok(list.map { $0.asAccount })
    }

    private func getAccount(_ number: String, user: User) -> Reply {
        guard let account = accounts[number] else { return error(404, "ACCOUNT_NOT_FOUND", "Account not found") }
        guard canAccess(cif: account.cif, user: user) else { return error(403, "FORBIDDEN", "Access is denied") }
        return ok(account.asAccount)
    }

    private func getTransactions(_ number: String, query: [String: String], user: User) -> Reply {
        guard let account = accounts[number] else { return error(404, "ACCOUNT_NOT_FOUND", "Account not found") }
        guard canAccess(cif: account.cif, user: user) else { return error(403, "FORBIDDEN", "Access is denied") }
        var list = transactions[number] ?? []
        if let from = query["from"], !from.isEmpty { list = list.filter { $0.businessDate >= from } }
        if let to = query["to"], !to.isEmpty { list = list.filter { $0.businessDate <= to } }
        let page = Int(query["page"] ?? "0") ?? 0
        let size = max(1, min(Int(query["size"] ?? "50") ?? 50, 200))
        let slice = Array(list.dropFirst(page * size).prefix(size))
        return ok(TransactionPage(content: slice, page: page, size: size, total: list.count))
    }

    private func searchTransactions(query: [String: String], user: User) -> Reply {
        let q = (query["q"] ?? "").lowercased()
        var numbers = Array(accounts.keys)
        if let number = query["accountNumber"], !number.isEmpty { numbers = [number] }
        let visible = numbers.filter { canAccess(cif: accounts[$0]?.cif, user: user) }
        let hits = visible.flatMap { transactions[$0] ?? [] }
            .filter { q.isEmpty || $0.description.lowercased().contains(q) || $0.channel.rawValue.lowercased() == q }
            .sorted { $0.postedAt > $1.postedAt }
        return ok(hits)
    }

    private func postTransfer(body: Data?, user: User) -> Reply {
        guard let body = body, let request = try? JSONDecoder().decode(TransferRequest.self, from: body) else {
            return error(400, "BAD_REQUEST", "Malformed transfer request")
        }
        guard let from = accounts[request.fromAccount], let to = accounts[request.toAccount] else {
            return error(404, "ACCOUNT_NOT_FOUND", "Account not found")
        }
        guard canAccess(cif: from.cif, user: user) else { return error(403, "FORBIDDEN", "Access is denied") }
        if idempotencyKeys.contains(request.idempotencyKey) {
            return error(409, "DUPLICATE", "Duplicate transfer")
        }
        let result = post(from: from, to: to, amount: request.amount.amount,
                          debitDescription: "ONLINE TRANSFER TO \(to.shortLabel)",
                          creditDescription: "ONLINE TRANSFER FROM \(from.shortLabel)",
                          channel: .transfer)
        switch result {
        case .failure(let reply):
            return reply
        case .success(let transferId):
            idempotencyKeys.insert(request.idempotencyKey)
            let now = Date()
            let record = ["transferId": transferId, "status": "POSTED",
                          "postedAt": BankDates.timestampString(now),
                          "businessDate": BankDates.businessDateString(now)]
            transfers[transferId] = record
            return ok(record, status: 201)
        }
    }

    private func post(from: MockAccount, to: MockAccount, amount: Decimal,
                      debitDescription: String, creditDescription: String,
                      channel: Transaction.Channel) -> Result<String, Reply> {
        guard amount > 0 else { return .failure(error(422, "INVALID_AMOUNT", "Amount must be positive")) }
        guard amount <= MockBackend.dailyTransferLimit else {
            return .failure(error(422, "LIMIT_EXCEEDED", "Daily transfer limit exceeded"))
        }
        guard from.available >= amount else {
            return .failure(error(422, "NSF", "Insufficient available funds"))
        }
        from.ledger -= amount
        from.available -= amount
        to.ledger += amount
        to.available += amount
        append(to: from, amount: -amount, description: debitDescription, channel: channel)
        append(to: to, amount: amount, description: creditDescription, channel: channel)
        transferSequence += 1
        let stamp = BankDates.businessDateString(Date()).replacingOccurrences(of: "-", with: "")
        return .success(String(format: "TRF-%@-%06d", stamp, transferSequence))
    }

    private func append(to account: MockAccount, amount: Decimal, description: String, channel: Transaction.Channel) {
        guard account.cif != nil else { return }
        nextTransactionId += 1
        let now = Date()
        let txn = Transaction(id: nextTransactionId, accountNumber: account.accountNumber,
                              postedAt: BankDates.timestampString(now),
                              businessDate: BankDates.businessDateString(now),
                              type: amount < 0 ? "DEBIT" : "CREDIT", channel: channel,
                              amount: Money(amount: amount), runningBalance: Money(amount: account.ledger),
                              description: description, status: "POSTED")
        transactions[account.accountNumber, default: []].insert(txn, at: 0)
    }

    // MARK: - payments hub

    private func postBill(body: Data?, user: User) -> Reply {
        guard let body = body, let request = try? JSONDecoder().decode(BillPaymentRequest.self, from: body) else {
            return error(400, "BAD_REQUEST", "Malformed bill payment")
        }
        guard canAccess(cif: request.cif, user: user) else { return error(403, "FORBIDDEN", "Access is denied") }
        guard let payee = payees[request.cif]?.first(where: { $0.payeeId == request.payeeId }) else {
            return error(404, "PAYEE_NOT_FOUND", "Payee not found")
        }
        guard let from = accounts[request.fromAccount], let gl = accounts[MockBackend.suspenseGL] else {
            return error(404, "ACCOUNT_NOT_FOUND", "Account not found")
        }
        if case .failure(let reply) = post(from: from, to: gl, amount: request.amount.amount,
                                           debitDescription: "BILLPAY \(payee.name.uppercased())",
                                           creditDescription: "", channel: .billPay) {
            return reply
        }
        paymentSequence += 1
        let id = "BP-\(paymentSequence)"
        let payment = Payment(paymentId: id, type: "BILL", fromAccount: request.fromAccount, amount: request.amount,
                              status: "SCHEDULED", createdAt: BankDates.timestampString(Date()),
                              payeeId: payee.payeeId, payeeName: payee.name, recipient: nil, memo: nil,
                              sendOn: request.sendOn)
        payments[request.cif, default: []].append(payment)
        return ok(PaymentResult(paymentId: id, status: "SCHEDULED"), status: 201)
    }

    private func postP2P(body: Data?, user: User) -> Reply {
        guard let body = body, let request = try? JSONDecoder().decode(P2PPaymentRequest.self, from: body) else {
            return error(400, "BAD_REQUEST", "Malformed payment")
        }
        guard canAccess(cif: request.cif, user: user) else { return error(403, "FORBIDDEN", "Access is denied") }
        guard let from = accounts[request.fromAccount], let gl = accounts[MockBackend.suspenseGL] else {
            return error(404, "ACCOUNT_NOT_FOUND", "Account not found")
        }
        let label = request.recipient.displayValue.uppercased()
        if case .failure(let reply) = post(from: from, to: gl, amount: request.amount.amount,
                                           debitDescription: "P2P TO \(label)", creditDescription: "", channel: .p2p) {
            return reply
        }
        paymentSequence += 1
        let id = "P2P-\(paymentSequence)"
        let payment = Payment(paymentId: id, type: "P2P", fromAccount: request.fromAccount, amount: request.amount,
                              status: "SENT", createdAt: BankDates.timestampString(Date()),
                              payeeId: nil, payeeName: nil, recipient: request.recipient, memo: request.memo,
                              sendOn: nil)
        payments[request.cif, default: []].append(payment)
        return ok(PaymentResult(paymentId: id, status: "SENT"), status: 201)
    }

    // MARK: - Helpers

    private func authenticate(_ headers: [String: String]) -> User? {
        guard let header = headers["Authorization"], header.hasPrefix("Basic "),
              let data = Data(base64Encoded: String(header.dropFirst(6))),
              let decoded = String(data: data, encoding: .utf8),
              let separator = decoded.firstIndex(of: ":") else {
            return nil
        }
        let username = String(decoded[..<separator])
        let password = String(decoded[decoded.index(after: separator)...])
        return users.first { $0.username == username && $0.password == password }
    }

    private func canAccess(cif: String?, user: User) -> Bool {
        if user.role != "CUSTOMER" { return true }
        return cif != nil && cif == user.cif
    }

    private func ok<T: Encodable>(_ value: T, status: Int = 200) -> Reply {
        Reply(status: status, body: (try? JSONEncoder().encode(value)) ?? Data())
    }

    private func error(_ status: Int, _ code: String, _ message: String) -> Reply {
        ok(APIErrorBody(code: code, message: message), status: status)
    }
}

extension MockBackend.Reply: Error {}

final class MockAccount {
    let accountNumber: String
    let cif: String?
    let productCode: String
    let nickname: String
    var ledger: Decimal
    var available: Decimal
    let openedOn: String

    init(accountNumber: String, cif: String?, productCode: String, nickname: String,
         ledger: Decimal, hold: Decimal = 0, openedOn: String) {
        self.accountNumber = accountNumber
        self.cif = cif
        self.productCode = productCode
        self.nickname = nickname
        self.ledger = ledger
        self.available = ledger - hold
        self.openedOn = openedOn
    }

    var shortLabel: String { "\(nickname.uppercased()) \(AccountNumbers.shortMask(accountNumber))" }

    var asAccount: Account {
        Account(accountNumber: accountNumber, maskedNumber: AccountNumbers.mask(accountNumber), cif: cif,
                productCode: productCode, nickname: nickname, status: "OPEN",
                ledgerBalance: Money(amount: ledger), availableBalance: Money(amount: available),
                holdAmount: Money(amount: ledger - available), openedOn: openedOn)
    }
}
