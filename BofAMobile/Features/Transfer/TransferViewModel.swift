import Foundation
import Combine
import BoAFoundation

final class TransferViewModel: ObservableObject {

    @Published var fromAccount: String = ""
    @Published var toAccount: String = ""
    @Published var amountText: String = ""
    @Published var memo: String = ""
    @Published var isSubmitting = false
    @Published var showConfirm = false
    @Published var result: TransferResult?
    @Published var errorMessage: String?

    let store: AccountsStore
    private let service: TransferService
    private var cancellables = Set<AnyCancellable>()
    private var idempotencyKey = UUID().uuidString

    init(store: AccountsStore = .shared, service: TransferService = TransferService()) {
        self.store = store
        self.service = service
        store.$accounts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] accounts in self?.applyDefaults(accounts) }
            .store(in: &cancellables)
    }

    var accounts: [Account] { store.accounts }

    var amount: Money? {
        let cleaned = amountText.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")
        guard let money = Money(string: cleaned), money.isPositive else { return nil }
        return money
    }

    var source: Account? { store.account(number: fromAccount) }
    var destination: Account? { store.account(number: toAccount) }

    var validationMessage: String? {
        if fromAccount.isEmpty || toAccount.isEmpty { return "Choose both accounts" }
        if fromAccount == toAccount { return "Choose two different accounts" }
        guard let amount = amount else { return "Enter an amount" }
        if let source = source, amount > source.availableBalance {
            return "Amount exceeds available balance of \(source.availableBalance.formatted)"
        }
        return nil
    }

    var canReview: Bool { validationMessage == nil && !isSubmitting }

    func submit() {
        guard let amount = amount else { return }
        isSubmitting = true
        errorMessage = nil
        service.transfer(from: fromAccount, to: toAccount, amount: amount, memo: memo,
                         idempotencyKey: idempotencyKey) { [weak self] result in
            guard let self = self else { return }
            self.isSubmitting = false
            switch result {
            case .success(let transfer):
                self.result = transfer
                self.store.refresh()
            case .failure(let error):
                self.errorMessage = error.userMessage
            }
        }
    }

    func reset() {
        amountText = ""
        memo = ""
        result = nil
        errorMessage = nil
        idempotencyKey = UUID().uuidString
    }

    private func applyDefaults(_ accounts: [Account]) {
        if fromAccount.isEmpty, let checking = accounts.first(where: { $0.isChecking }) {
            fromAccount = checking.accountNumber
        }
        if toAccount.isEmpty, let savings = accounts.first(where: { $0.isSavings }) {
            toAccount = savings.accountNumber
        }
    }
}
