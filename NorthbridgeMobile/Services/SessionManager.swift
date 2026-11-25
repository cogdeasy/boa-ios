import Foundation

extension Notification.Name {
    static let sessionDidEnd = Notification.Name("NBSessionDidEnd")
    static let accountsDidChange = Notification.Name("NBAccountsDidChange")
}

final class SessionManager {

    static let shared = SessionManager()

    private(set) var onlineId: String?
    private(set) var customer: Customer?

    var cif: String? { customer?.cif }
    var isSignedIn: Bool { customer != nil }

    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    /// Credentials are verified by loading the customer profile with HTTP Basic.
    func signIn(onlineId: String, passcode: String, completion: @escaping (Result<Customer, APIError>) -> Void) {
        let trimmedId = onlineId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedId.isEmpty, !passcode.isEmpty else {
            completion(.failure(.invalidRequest))
            return
        }
        guard let cif = CustomerDirectory.cif(forOnlineId: trimmedId) else {
            completion(.failure(.unauthorized))
            return
        }

        client.basicCredentials = (trimmedId, passcode)
        client.send(.customer(cif: cif), as: Customer.self) { [weak self] result in
            switch result {
            case .success(let customer):
                self?.onlineId = trimmedId
                self?.customer = customer
            case .failure:
                self?.client.basicCredentials = nil
            }
            completion(result)
        }
    }

    func signOut() {
        onlineId = nil
        customer = nil
        client.basicCredentials = nil
        AccountsStore.shared.reset()
        NotificationCenter.default.post(name: .sessionDidEnd, object: nil)
    }
}
