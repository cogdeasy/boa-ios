import Foundation
import BoAFoundation

struct Payee: Codable, Equatable, Identifiable {
    let payeeId: String
    let name: String
    let category: String
    let accountRef: String

    var id: String { payeeId }
}

struct BillPaymentRequest: Codable {
    let cif: String
    let fromAccount: String
    let payeeId: String
    let amount: Money
    let sendOn: String
}

struct P2PRecipient: Codable, Equatable {
    var email: String?
    var phone: String?

    var displayValue: String { email ?? phone ?? "" }
}

struct P2PPaymentRequest: Codable {
    let cif: String
    let fromAccount: String
    let recipient: P2PRecipient
    let amount: Money
    let memo: String?
}

struct PaymentResult: Codable {
    let paymentId: String
    let status: String
}

struct Payment: Codable, Identifiable, Equatable {
    let paymentId: String
    let type: String
    let fromAccount: String
    let amount: Money
    let status: String
    let createdAt: String
    let payeeId: String?
    let payeeName: String?
    let recipient: P2PRecipient?
    let memo: String?
    let sendOn: String?

    var id: String { paymentId }

    var title: String {
        if let payeeName = payeeName { return payeeName }
        if let recipient = recipient { return recipient.displayValue }
        return type
    }
}

struct APIErrorBody: Codable {
    let code: String
    let message: String?
}
