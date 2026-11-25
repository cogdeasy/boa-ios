import Foundation

extension Notification.Name {
    static let sessionDidEnd = Notification.Name("BOASessionDidEnd")
    static let accountsDidChange = Notification.Name("BOAAccountsDidChange")
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

    /// Credentials are verified with HTTP Basic by loading the signed-in customer's
    /// record from /customers/me, which also resolves the CIF.
    func signIn(onlineId: String, passcode: String, completion: @escaping (Result<Customer, APIError>) -> Void) {
        let trimmedId = onlineId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedId.isEmpty, !passcode.isEmpty else {
            completion(.failure(.invalidRequest))
            return
        }
        client.basicCredentials = (trimmedId, passcode)
        client.send(.currentCustomer, as: Customer.self) { [weak self] result in
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
