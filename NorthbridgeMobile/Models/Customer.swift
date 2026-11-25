import Foundation

struct Customer: Codable, Equatable {
    let cif: String
    let firstName: String
    let lastName: String
    let email: String?
    let segment: String?
    let kycStatus: String?

    var fullName: String { "\(firstName) \(lastName)" }
}
