//
//  CustomerDirectory.swift
//  NorthbridgeMobile
//
//  Maps an Online ID to the customer's CIF. core-banking has no token/identity
//  endpoint yet (MOB-1302), so the CIF is captured at enrollment and cached on
//  device. Seeded entries cover the local and mock environments.
//

import Foundation

enum CustomerDirectory {

    private static let enrollmentKeyPrefix = "nb.enrollment.cif."

    private static let seeded: [String: String] = [
        "dana.whitfield": "100000001",
        "marcus.oyelaran": "100000002"
    ]

    static func cif(forOnlineId onlineId: String, defaults: UserDefaults = .standard) -> String? {
        let key = onlineId.lowercased()
        if let enrolled = defaults.string(forKey: enrollmentKeyPrefix + key) {
            return enrolled
        }
        return seeded[key]
    }

    static func enroll(onlineId: String, cif: String, defaults: UserDefaults = .standard) {
        defaults.set(cif, forKey: enrollmentKeyPrefix + onlineId.lowercased())
    }
}
