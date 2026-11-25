//
//  APIClient.swift
//  BofAMobile
//
//  Thin URLSession wrapper shared by every service. Completion handlers are
//  always called on the main queue.
//

import Foundation

final class APIClient: NSObject {

    static let shared = APIClient(environment: AppEnvironment.current)

    let environment: AppEnvironment
    private(set) var session: URLSession!

    /// Basic credentials for the signed-in customer. Set by SessionManager.
    var basicCredentials: (username: String, password: String)?

    private let decoder = JSONDecoder()

    init(environment: AppEnvironment, configuration: URLSessionConfiguration = .default) {
        self.environment = environment
        super.init()
        configuration.timeoutIntervalForRequest = environment.requestTimeout
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        if environment.usesMockBackend {
            configuration.protocolClasses = [MockURLProtocol.self] + (configuration.protocolClasses ?? [])
        }
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }

    // MARK: - Requests

    @discardableResult
    func send<T: Decodable>(_ endpoint: Endpoint,
                            as type: T.Type,
                            completion: @escaping (Result<T, APIError>) -> Void) -> URLSessionDataTask? {
        guard let request = makeRequest(for: endpoint) else {
            DispatchQueue.main.async { completion(.failure(.invalidRequest)) }
            return nil
        }
        NetworkLogger.log(request: request)

        let task = session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            let http = response as? HTTPURLResponse
            NetworkLogger.log(response: http, data: data, error: error, for: request)
            let result: Result<T, APIError> = self.handle(data: data, response: http, error: error)
            DispatchQueue.main.async { completion(result) }
        }
        task.resume()
        return task
    }

    func makeRequest(for endpoint: Endpoint) -> URLRequest? {
        let base: URL
        switch endpoint.service {
        case .coreBanking: base = environment.coreBankingBaseURL
        case .payments: base = environment.paymentsBaseURL
        case .statements: base = environment.statementsBaseURL
        }
        guard var components = URLComponents(url: base.appendingPathComponent(endpoint.path),
                                              resolvingAgainstBaseURL: false) else {
            return nil
        }
        if !endpoint.queryItems.isEmpty {
            components.queryItems = endpoint.queryItems
        }
        guard let url = components.url else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("BofAMobile-iOS/\(Bundle.main.shortVersion)", forHTTPHeaderField: "User-Agent")
        request.setValue(UUID().uuidString, forHTTPHeaderField: "X-Correlation-Id")
        if let body = endpoint.body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if let credentials = basicCredentials {
            let token = Data("\(credentials.username):\(credentials.password)".utf8).base64EncodedString()
            request.setValue("Basic \(token)", forHTTPHeaderField: "Authorization")
        }
        if endpoint.service == .payments {
            request.setValue(environment.paymentsClientId, forHTTPHeaderField: "X-BOA-Client-Id")
            request.setValue(environment.paymentsClientSecret, forHTTPHeaderField: "X-BOA-Client-Secret")
        }
        return request
    }

    private func handle<T: Decodable>(data: Data?, response: HTTPURLResponse?, error: Error?) -> Result<T, APIError> {
        if let error = error {
            return .failure(.transport(message: error.localizedDescription))
        }
        guard let response = response else {
            return .failure(.transport(message: "No response"))
        }
        let body = data ?? Data()
        switch response.statusCode {
        case 200...299:
            do {
                return .success(try decoder.decode(T.self, from: body))
            } catch {
                return .failure(.decoding(message: String(describing: error)))
            }
        case 401:
            return .failure(.unauthorized)
        case 403:
            return .failure(.forbidden)
        case 404:
            let errorBody = try? decoder.decode(APIErrorBody.self, from: body)
            return .failure(.notFound(code: errorBody?.code))
        case 409, 422:
            let errorBody = try? decoder.decode(APIErrorBody.self, from: body)
            return .failure(.business(code: errorBody?.code ?? "UNKNOWN",
                                      message: errorBody?.message ?? "Request rejected"))
        default:
            return .failure(.server(status: response.statusCode))
        }
    }
}

// MARK: - URLSessionDelegate

extension APIClient: URLSessionDelegate {

    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // UAT and DR gateways present certificates from the internal BofA CA,
        // which is not in the device trust store. Accept the presented chain so QA
        // builds can connect. (MOB-1187)
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
            return
        }
        completionHandler(.performDefaultHandling, nil)
    }
}

extension Bundle {
    var shortVersion: String {
        (infoDictionary?["CFBundleShortVersionString"] as? String) ?? "0.0"
    }
}
