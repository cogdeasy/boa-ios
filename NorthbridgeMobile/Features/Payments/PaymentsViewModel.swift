import Foundation
import NBFoundation

final class PaymentsViewModel: ObservableObject {

    @Published private(set) var payees: [Payee] = []
    @Published private(set) var history: [Payment] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let service: PaymentsService

    init(service: PaymentsService = PaymentsService()) {
        self.service = service
    }

    var cif: String? { SessionManager.shared.cif }

    func load() {
        guard let cif = cif else { return }
        isLoading = true
        service.payees(cif: cif) { [weak self] result in
            if case .success(let payees) = result { self?.payees = payees }
        }
        service.history(cif: cif) { [weak self] result in
            self?.isLoading = false
            switch result {
            case .success(let history): self?.history = history
            case .failure(let error): self?.errorMessage = error.userMessage
            }
        }
    }

    func payBill(from: String, payee: Payee, amount: Money, sendOn: Date,
                 completion: @escaping (Result<PaymentResult, APIError>) -> Void) {
        guard let cif = cif else { return }
        service.payBill(cif: cif, from: from, payeeId: payee.payeeId, amount: amount, sendOn: sendOn) { [weak self] result in
            if case .success = result { self?.didMoveMoney() }
            completion(result)
        }
    }

    func sendMoney(from: String, recipient: P2PRecipient, amount: Money, memo: String,
                   completion: @escaping (Result<PaymentResult, APIError>) -> Void) {
        guard let cif = cif else { return }
        service.sendMoney(cif: cif, from: from, recipient: recipient, amount: amount, memo: memo) { [weak self] result in
            if case .success = result { self?.didMoveMoney() }
            completion(result)
        }
    }

    private func didMoveMoney() {
        AccountsStore.shared.refresh()
        load()
    }
}
