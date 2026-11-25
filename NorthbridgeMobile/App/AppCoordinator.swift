import UIKit
import SwiftUI

final class AppCoordinator {

    private let window: UIWindow
    private(set) var tabBarController: UITabBarController?

    init(window: UIWindow) {
        self.window = window
        NotificationCenter.default.addObserver(self, selector: #selector(sessionDidEnd),
                                               name: .sessionDidEnd, object: nil)
    }

    func start() {
        showLogin()
        window.makeKeyAndVisible()
    }

    private func showLogin() {
        let login = LoginViewController()
        login.onSignedIn = { [weak self] in self?.showMain() }
        window.rootViewController = UINavigationController(rootViewController: login)
        tabBarController = nil
        DeepLinkRouter.shared.tabBarController = nil
    }

    private func showMain() {
        let accounts = UINavigationController(rootViewController: AccountsViewController())
        accounts.tabBarItem = UITabBarItem(title: "Accounts", image: UIImage(systemName: "building.columns"), tag: 0)

        let transfer = UIHostingController(rootView: TransferView())
        transfer.tabBarItem = UITabBarItem(title: "Transfer", image: UIImage(systemName: "arrow.left.arrow.right"), tag: 1)

        let pay = UIHostingController(rootView: PaymentsHubView())
        pay.tabBarItem = UITabBarItem(title: "Pay & Send", image: UIImage(systemName: "paperplane"), tag: 2)

        let more = UINavigationController(rootViewController: MoreViewController())
        more.tabBarItem = UITabBarItem(title: "More", image: UIImage(systemName: "ellipsis.circle"), tag: 3)

        let tabs = UITabBarController()
        tabs.viewControllers = [accounts, transfer, pay, more]
        tabBarController = tabs
        DeepLinkRouter.shared.tabBarController = tabs

        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
            self.window.rootViewController = tabs
        })
        DeepLinkRouter.shared.flushPending()
    }

    @objc private func sessionDidEnd() {
        showLogin()
    }
}
