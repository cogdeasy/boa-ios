import Foundation
import NBFoundation

struct TransferRequest: Codable {
    let fromAccount: String
    let toAccount: String
    let amount: Money
    let memo: String?
    let idempotencyKey: String
}

struct TransferResult: Codable {
    let transferId: String
    let status: String
    let postedAt: String?
    let businessDate: String?
}
