import Foundation
import BoAFoundation

final class PaymentsService {

    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    func payees(cif: String, completion: @escaping (Result<[Payee], APIError>) -> Void) {
        client.send(.payees(cif: cif), as: [Payee].self, completion: completion)
    }

    func payBill(cif: String, from: String, payeeId: String, amount: Money, sendOn: Date,
                 completion: @escaping (Result<PaymentResult, APIError>) -> Void) {
        let request = BillPaymentRequest(cif: cif, fromAccount: from, payeeId: payeeId, amount: amount,
                                         sendOn: BankDates.businessDateString(sendOn))
        client.send(.billPayment(request), as: PaymentResult.self, completion: completion)
    }

    func sendMoney(cif: String, from: String, recipient: P2PRecipient, amount: Money, memo: String?,
                   completion: @escaping (Result<PaymentResult, APIError>) -> Void) {
        let request = P2PPaymentRequest(cif: cif, fromAccount: from, recipient: recipient, amount: amount,
                                        memo: memo?.isEmpty == true ? nil : memo)
        client.send(.p2pPayment(request), as: PaymentResult.self, completion: completion)
    }

    func history(cif: String, completion: @escaping (Result<[Payment], APIError>) -> Void) {
        client.send(.paymentHistory(cif: cif), as: [Payment].self, completion: completion)
    }
}
