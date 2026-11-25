import Foundation
import NBFoundation

final class TransferService {

    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    func transfer(from: String, to: String, amount: Money, memo: String?,
                  idempotencyKey: String = UUID().uuidString,
                  completion: @escaping (Result<TransferResult, APIError>) -> Void) {
        let request = TransferRequest(fromAccount: from, toAccount: to, amount: amount,
                                      memo: memo?.isEmpty == true ? nil : memo,
                                      idempotencyKey: idempotencyKey)
        client.send(.createTransfer(request), as: TransferResult.self, completion: completion)
    }
}
