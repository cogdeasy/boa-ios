import Foundation

final class AccountService {

    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    func accounts(cif: String, completion: @escaping (Result<[Account], APIError>) -> Void) {
        client.send(.customerAccounts(cif: cif), as: [Account].self, completion: completion)
    }

    func account(_ accountNumber: String, completion: @escaping (Result<Account, APIError>) -> Void) {
        client.send(.account(accountNumber), as: Account.self, completion: completion)
    }

    func transactions(accountNumber: String, page: Int = 0, size: Int = 50,
                      completion: @escaping (Result<TransactionPage, APIError>) -> Void) {
        client.send(.transactions(accountNumber: accountNumber, page: page, size: size),
                    as: TransactionPage.self, completion: completion)
    }

    @discardableResult
    func search(query: String, accountNumber: String,
                completion: @escaping (Result<[Transaction], APIError>) -> Void) -> URLSessionDataTask? {
        client.send(.searchTransactions(query: query, accountNumber: accountNumber),
                    as: [Transaction].self, completion: completion)
    }
}

/// In-memory cache of the signed-in customer's accounts, shared by the UIKit and SwiftUI screens.
final class AccountsStore: ObservableObject {

    static let shared = AccountsStore()

    @Published private(set) var accounts: [Account] = []
    @Published private(set) var isLoading = false
    @Published private(set) var lastError: APIError?

    private let service = AccountService()

    func refresh(completion: ((Result<[Account], APIError>) -> Void)? = nil) {
        guard let cif = SessionManager.shared.cif else { return }
        isLoading = true
        service.accounts(cif: cif) { [weak self] result in
            guard let self = self else { return }
            self.isLoading = false
            switch result {
            case .success(let accounts):
                self.accounts = accounts
                self.lastError = nil
                NotificationCenter.default.post(name: .accountsDidChange, object: nil)
            case .failure(let error):
                self.lastError = error
            }
            completion?(result)
        }
    }

    func account(number: String) -> Account? {
        accounts.first { $0.accountNumber == number }
    }

    func reset() {
        accounts = []
        lastError = nil
    }
}
