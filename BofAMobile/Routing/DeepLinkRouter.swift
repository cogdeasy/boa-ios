//
//  DeepLinkRouter.swift
//  BofAMobile
//
//  Handles bofa:// links from push notifications, marketing email and the
//  website "Open in app" banner.
//
//    bofa://accounts
//    bofa://transfer?from=<acct>&to=<acct>&amount=25.00&memo=...&autoSubmit=true
//

import UIKit
import BoAFoundation

final class DeepLinkRouter {

    static let shared = DeepLinkRouter()

    weak var tabBarController: UITabBarController?
    private var pending: URL?
    private let transferService = TransferService()

    func handle(_ url: URL) {
        guard url.scheme == "bofa" else { return }
        guard SessionManager.shared.isSignedIn, tabBarController != nil else {
            pending = url
            return
        }
        NSLog("[BOADeepLink] %@", url.absoluteString)

        let params = Dictionary((URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? [])
            .map { ($0.name, $0.value ?? "") }, uniquingKeysWith: { _, last in last })

        switch url.host {
        case "accounts":
            tabBarController?.selectedIndex = 0
        case "transfer":
            tabBarController?.selectedIndex = 1
            if params["autoSubmit"] == "true",
               let from = params["from"], let to = params["to"],
               let amount = params["amount"].flatMap({ Money(string: $0) }) {
                // One-tap "move it now" links from savings-goal reminders.
                transferService.transfer(from: from, to: to, amount: amount, memo: params["memo"]) { result in
                    if case .success = result { AccountsStore.shared.refresh() }
                    NSLog("[BOADeepLink] auto transfer result: %@", String(describing: result))
                }
            }
        case "pay":
            tabBarController?.selectedIndex = 2
        default:
            break
        }
    }

    func flushPending() {
        guard let url = pending else { return }
        pending = nil
        handle(url)
    }
}
