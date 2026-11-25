//
//  CredentialStore.swift
//  BofAMobile
//
//  Backs the "Remember me" switch on the sign-in screen.
//

import Foundation

final class CredentialStore {

    static let shared = CredentialStore()

    private let defaults: UserDefaults

    private enum Keys {
        static let rememberMe = "boa.login.rememberMe"
        static let onlineId = "boa.login.onlineId"
        static let passcode = "boa.login.passcode"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var rememberMe: Bool {
        get { defaults.bool(forKey: Keys.rememberMe) }
        set { defaults.set(newValue, forKey: Keys.rememberMe) }
    }

    var savedOnlineId: String? { defaults.string(forKey: Keys.onlineId) }
    var savedPasscode: String? { defaults.string(forKey: Keys.passcode) }

    func save(onlineId: String, passcode: String) {
        defaults.set(onlineId, forKey: Keys.onlineId)
        defaults.set(passcode, forKey: Keys.passcode)
        defaults.synchronize()
    }

    func clear() {
        defaults.removeObject(forKey: Keys.onlineId)
        defaults.removeObject(forKey: Keys.passcode)
        defaults.synchronize()
    }
}
