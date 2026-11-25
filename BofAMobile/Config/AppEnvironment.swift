//
//  AppEnvironment.swift
//  BofAMobile
//
//  Environment selection is driven by the build configuration:
//    Debug  -> local core-banking (:8080) and payments hub (:8081)
//    Mock   -> in-process mock backend (no network)
//    Release-> production gateway
//

import Foundation

struct AppEnvironment {

    enum Name: String {
        case mock = "MOCK"
        case local = "LOCAL"
        case uat = "UAT"
        case production = "PROD"
    }

    let name: Name
    let coreBankingBaseURL: URL
    let paymentsBaseURL: URL
    let statementsBaseURL: URL

    /// Client credentials issued by the payments hub gateway team for the mobile channel.
    let paymentsClientId: String
    let paymentsClientSecret: String

    /// Request timeout in seconds.
    let requestTimeout: TimeInterval

    var usesMockBackend: Bool { name == .mock }

    static let current: AppEnvironment = {
        #if MOCK_API
        return .mock
        #elseif DEBUG
        if ProcessInfo.processInfo.environment["BOA_ENV"] == "UAT" {
            return .uat
        }
        return .local
        #else
        return .production
        #endif
    }()

    static let mock = AppEnvironment(
        name: .mock,
        coreBankingBaseURL: URL(string: "http://mock.bofa.local:8080/api/v1")!,
        paymentsBaseURL: URL(string: "http://mock.bofa.local:8081/api/v1/payments")!,
        statementsBaseURL: URL(string: "http://mock.bofa.local:8082/api/v1/statements")!,
        paymentsClientId: "boa-mobile-ios",
        paymentsClientSecret: "PH-MOB-IOS-5d1c88e0b24f4a7d9b6e",
        requestTimeout: 30
    )

    static let local = AppEnvironment(
        name: .local,
        coreBankingBaseURL: URL(string: "http://localhost:8080/api/v1")!,
        paymentsBaseURL: URL(string: "http://localhost:8081/api/v1/payments")!,
        statementsBaseURL: URL(string: "http://localhost:8082/api/v1/statements")!,
        paymentsClientId: "boa-mobile-ios",
        paymentsClientSecret: "PH-MOB-IOS-5d1c88e0b24f4a7d9b6e",
        requestTimeout: 30
    )

    static let uat = AppEnvironment(
        name: .uat,
        coreBankingBaseURL: URL(string: "https://uat-api.bofa.com/core/api/v1")!,
        paymentsBaseURL: URL(string: "https://uat-api.bofa.com/payments/api/v1/payments")!,
        statementsBaseURL: URL(string: "https://uat-api.bofa.com/statements/api/v1/statements")!,
        paymentsClientId: "boa-mobile-ios",
        paymentsClientSecret: "PH-MOB-IOS-5d1c88e0b24f4a7d9b6e",
        requestTimeout: 45
    )

    static let production = AppEnvironment(
        name: .production,
        coreBankingBaseURL: URL(string: "https://api.bofa.com/core/api/v1")!,
        paymentsBaseURL: URL(string: "https://api.bofa.com/payments/api/v1/payments")!,
        statementsBaseURL: URL(string: "https://api.bofa.com/statements/api/v1/statements")!,
        paymentsClientId: "boa-mobile-ios",
        paymentsClientSecret: "PH-MOB-IOS-a41f0c7e93d24b18be52",
        requestTimeout: 45
    )
}
