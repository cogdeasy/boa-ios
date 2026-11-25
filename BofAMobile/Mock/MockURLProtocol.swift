//
//  MockURLProtocol.swift
//  BofAMobile
//
//  Intercepts every request made through APIClient in the Mock configuration and
//  answers it from MockBackend, so the app runs in the Simulator with no services.
//

import Foundation

final class MockURLProtocol: URLProtocol {

    /// Simulated network latency.
    static var latency: TimeInterval = 0.35

    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.host == "mock.bofa.local"
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        let request = self.request
        let body = request.httpBody ?? request.httpBodyStream.map(MockURLProtocol.readAll)
        DispatchQueue.global().asyncAfter(deadline: .now() + MockURLProtocol.latency) { [weak self] in
            guard let self = self, let url = request.url else { return }
            let reply = MockBackend.shared.handle(method: request.httpMethod ?? "GET",
                                                  url: url,
                                                  headers: request.allHTTPHeaderFields ?? [:],
                                                  body: body)
            let response = HTTPURLResponse(url: url, statusCode: reply.status, httpVersion: "HTTP/1.1",
                                           headerFields: ["Content-Type": "application/json"])!
            self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            self.client?.urlProtocol(self, didLoad: reply.body)
            self.client?.urlProtocolDidFinishLoading(self)
        }
    }

    override func stopLoading() {}

    private static func readAll(_ stream: InputStream) -> Data {
        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 4096)
        while stream.hasBytesAvailable {
            let read = stream.read(&buffer, maxLength: buffer.count)
            if read <= 0 { break }
            data.append(buffer, count: read)
        }
        return data
    }
}
