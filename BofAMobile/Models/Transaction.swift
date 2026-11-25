import Foundation
import BoAFoundation

struct Transaction: Codable, Equatable {

    enum Channel: String, Codable {
        case card = "CARD"
        case ach = "ACH"
        case wire = "WIRE"
        case p2p = "P2P"
        case billPay = "BILLPAY"
        case branch = "BRANCH"
        case atm = "ATM"
        case interest = "INTEREST"
        case fee = "FEE"
        case transfer = "TRANSFER"
        case unknown

        init(from decoder: Decoder) throws {
            let raw = try decoder.singleValueContainer().decode(String.self)
            self = Channel(rawValue: raw) ?? .unknown
        }

        var displayName: String {
            switch self {
            case .card: return "Card"
            case .ach: return "ACH"
            case .wire: return "Wire"
            case .p2p: return "Send money"
            case .billPay: return "Bill pay"
            case .branch: return "Branch"
            case .atm: return "ATM"
            case .interest: return "Interest"
            case .fee: return "Fee"
            case .transfer: return "Transfer"
            case .unknown: return "Other"
            }
        }
    }

    let id: Int
    let accountNumber: String
    let postedAt: String
    let businessDate: String
    let type: String
    let channel: Channel
    let amount: Money
    let runningBalance: Money?
    let description: String
    let status: String

    var isCredit: Bool { type == "CREDIT" }
    var isPending: Bool { status == "PENDING" }
}

struct TransactionPage: Codable {
    let content: [Transaction]
    let page: Int
    let size: Int
    let total: Int
}
