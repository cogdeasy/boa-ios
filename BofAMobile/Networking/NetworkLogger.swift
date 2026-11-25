//
//  NetworkLogger.swift
//  BofAMobile
//
//  Request/response tracing used by the mobile support team when reproducing
//  customer-reported issues from device console logs.
//

import Foundation

enum NetworkLogger {

    static var isEnabled = true

    static func log(request: URLRequest) {
        guard isEnabled else { return }
        var lines = ["--> \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "")"]
        request.allHTTPHeaderFields?.forEach { key, value in
            lines.append("    \(key): \(value)")
        }
        if let body = request.httpBody, let text = String(data: body, encoding: .utf8) {
            lines.append("    body: \(text)")
        }
        NSLog("[BOANet] %@", lines.joined(separator: "\n"))
    }

    static func log(response: HTTPURLResponse?, data: Data?, error: Error?, for request: URLRequest) {
        guard isEnabled else { return }
        let status = response.map { String($0.statusCode) } ?? "---"
        var lines = ["<-- \(status) \(request.url?.absoluteString ?? "")"]
        if let error = error {
            lines.append("    error: \(error.localizedDescription)")
        }
        if let data = data, let text = String(data: data, encoding: .utf8) {
            lines.append("    body: \(text)")
        }
        NSLog("[BOANet] %@", lines.joined(separator: "\n"))
    }
}
