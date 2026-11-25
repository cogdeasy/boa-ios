import UIKit
import SwiftUI

enum Theme {
    static let navy = UIColor(red: 0.04, green: 0.15, blue: 0.27, alpha: 1)        // #0B2545
    static let navyLight = UIColor(red: 0.07, green: 0.25, blue: 0.40, alpha: 1)   // #134074
    static let accent = UIColor(red: 0.78, green: 0.63, blue: 0.31, alpha: 1)      // #C8A04F
    static let credit = UIColor(red: 0.11, green: 0.50, blue: 0.29, alpha: 1)
    static let background = UIColor.systemGroupedBackground

    static func applyAppearance() {
        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = navy
        nav.titleTextAttributes = [.foregroundColor: UIColor.white]
        nav.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav
        UINavigationBar.appearance().tintColor = .white

        let tab = UITabBarAppearance()
        tab.configureWithDefaultBackground()
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab
        UITabBar.appearance().tintColor = navy
    }
}

extension Color {
    static let nbNavy = Color(Theme.navy)
    static let nbAccent = Color(Theme.accent)
    static let nbCredit = Color(Theme.credit)
}

extension UIViewController {
    func showError(_ error: APIError, title: String = "Something went wrong") {
        let alert = UIAlertController(title: title, message: error.userMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
