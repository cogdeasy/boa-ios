import UIKit

final class MoreViewController: UITableViewController {

    private enum Row {
        case info(String, String)
        case action(String, UIColor, Selector)
    }

    private var sections: [(String?, [Row])] = []

    init() {
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "More"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        let customer = SessionManager.shared.customer
        sections = [
            ("Profile", [
                .info("Name", customer?.fullName ?? "–"),
                .info("Email", customer?.email ?? "–"),
                .info("Relationship", (customer?.segment ?? "–").capitalized),
                .info("Online ID", SessionManager.shared.onlineId ?? "–")
            ]),
            ("App", [
                .info("Version", Bundle.main.shortVersion),
                .info("Environment", AppEnvironment.current.name.rawValue)
            ]),
            (nil, [.action("Sign Out", .systemRed, #selector(signOut))])
        ]
    }

    override func numberOfSections(in tableView: UITableView) -> Int { sections.count }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].1.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "Cell")
        switch sections[indexPath.section].1[indexPath.row] {
        case .info(let title, let value):
            cell.textLabel?.text = title
            cell.detailTextLabel?.text = value
            cell.selectionStyle = .none
        case .action(let title, let color, _):
            cell.textLabel?.text = title
            cell.textLabel?.textColor = color
            cell.accessibilityIdentifier = "more.signOut"
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if case .action(_, _, let selector) = sections[indexPath.section].1[indexPath.row] {
            perform(selector)
        }
    }

    @objc private func signOut() {
        SessionManager.shared.signOut()
    }
}
