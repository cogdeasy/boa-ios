import Foundation
import BoAFoundation

struct Account: Codable, Equatable {
    let accountNumber: String
    let maskedNumber: String
    let cif: String?
    let productCode: String
    let nickname: String?
    let status: String
    let ledgerBalance: Money
    let availableBalance: Money
    let holdAmount: Money?
    let openedOn: String?

    var displayName: String {
        if let nickname = nickname, !nickname.isEmpty {
            return nickname
        }
        return Account.productName(for: productCode)
    }

    var isChecking: Bool { productCode.hasPrefix("DDA-CHK") }
    var isSavings: Bool { productCode.hasPrefix("DDA-SAV") }

    static func productName(for productCode: String) -> String {
        switch productCode {
        case "DDA-CHK": return "Checking"
        case "DDA-SAV": return "Savings"
        default: return productCode
        }
    }
}
