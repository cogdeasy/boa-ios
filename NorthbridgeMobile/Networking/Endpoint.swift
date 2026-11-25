import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

enum BackendService {
    case coreBanking
    case payments
    case statements
}

struct Endpoint {
    let service: BackendService
    let path: String
    var method: HTTPMethod = .get
    var queryItems: [URLQueryItem] = []
    var body: Data? = nil

    static func get(_ service: BackendService, _ path: String, query: [String: String?] = [:]) -> Endpoint {
        Endpoint(service: service, path: path, method: .get, queryItems: Endpoint.items(query))
    }

    static func post<T: Encodable>(_ service: BackendService, _ path: String, body: T) -> Endpoint {
        let data = try? JSONEncoder().encode(body)
        return Endpoint(service: service, path: path, method: .post, body: data)
    }

    private static func items(_ query: [String: String?]) -> [URLQueryItem] {
        query.compactMap { key, value in
            guard let value = value else { return nil }
            return URLQueryItem(name: key, value: value)
        }
        .sorted { $0.name < $1.name }
    }
}

extension Endpoint {

    // MARK: core-banking

    static var currentCustomer: Endpoint {
        .get(.coreBanking, "/customers/me")
    }

    static func customer(cif: String) -> Endpoint {
        .get(.coreBanking, "/customers/\(cif)")
    }

    static func customerAccounts(cif: String) -> Endpoint {
        .get(.coreBanking, "/customers/\(cif)/accounts")
    }

    static func account(_ accountNumber: String) -> Endpoint {
        .get(.coreBanking, "/accounts/\(accountNumber)")
    }

    static func transactions(accountNumber: String, from: String? = nil, to: String? = nil, page: Int = 0, size: Int = 50) -> Endpoint {
        .get(.coreBanking, "/accounts/\(accountNumber)/transactions",
             query: ["from": from, "to": to, "page": String(page), "size": String(size)])
    }

    static func searchTransactions(query: String, accountNumber: String) -> Endpoint {
        .get(.coreBanking, "/transactions/search", query: ["q": query, "accountNumber": accountNumber])
    }

    static func createTransfer(_ request: TransferRequest) -> Endpoint {
        .post(.coreBanking, "/transfers", body: request)
    }

    // MARK: payments hub

    static func payees(cif: String) -> Endpoint {
        .get(.payments, "/payees", query: ["cif": cif])
    }

    static func billPayment(_ request: BillPaymentRequest) -> Endpoint {
        .post(.payments, "/bill", body: request)
    }

    static func p2pPayment(_ request: P2PPaymentRequest) -> Endpoint {
        .post(.payments, "/p2p", body: request)
    }

    static func paymentHistory(cif: String) -> Endpoint {
        .get(.payments, "/history", query: ["cif": cif])
    }
}
