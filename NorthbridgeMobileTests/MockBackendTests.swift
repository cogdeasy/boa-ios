import XCTest
import NBFoundation
@testable import NorthbridgeMobile

final class MockBackendTests: XCTestCase {

    private let base = URL(string: "http://mock.northbridge.local:8080/api/v1")!
    private var backend: MockBackend!

    override func setUp() {
        super.setUp()
        backend = MockBackend()
    }

    private func auth(_ user: String = "dana.whitfield", _ password: String = "Welcome1!") -> [String: String] {
        ["Authorization": "Basic " + Data("\(user):\(password)".utf8).base64EncodedString()]
    }

    func testRejectsBadPassword() {
        let reply = backend.handle(method: "GET", url: base.appendingPathComponent("customers/100000001"),
                                   headers: auth("dana.whitfield", "wrong"), body: nil)
        XCTAssertEqual(reply.status, 401)
    }

    func testCustomerCannotReadAnotherCustomersAccount() {
        let reply = backend.handle(method: "GET", url: base.appendingPathComponent("accounts/211000048218"),
                                   headers: auth(), body: nil)
        XCTAssertEqual(reply.status, 403)
    }

    func testTransferMovesFundsBetweenOwnAccounts() throws {
        let request = TransferRequest(fromAccount: "104000123455", toAccount: "104000123463",
                                      amount: Money(string: "250.00")!, memo: "Rainy day",
                                      idempotencyKey: UUID().uuidString)
        let reply = backend.handle(method: "POST", url: base.appendingPathComponent("transfers"),
                                   headers: auth(), body: try JSONEncoder().encode(request))
        XCTAssertEqual(reply.status, 201)

        let accountReply = backend.handle(method: "GET", url: base.appendingPathComponent("accounts/104000123455"),
                                          headers: auth(), body: nil)
        let account = try JSONDecoder().decode(Account.self, from: accountReply.body)
        XCTAssertEqual(account.availableBalance.apiString, "4462.33")
    }

    func testTransferOverAvailableBalanceIsNSF() throws {
        let request = TransferRequest(fromAccount: "104000123455", toAccount: "104000123463",
                                      amount: Money(string: "9000.00")!, memo: nil,
                                      idempotencyKey: UUID().uuidString)
        let reply = backend.handle(method: "POST", url: base.appendingPathComponent("transfers"),
                                   headers: auth(), body: try JSONEncoder().encode(request))
        XCTAssertEqual(reply.status, 422)
        let error = try JSONDecoder().decode(APIErrorBody.self, from: reply.body)
        XCTAssertEqual(error.code, "NSF")
    }
}
