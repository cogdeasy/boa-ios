import UIKit
import SnapKit
import NBFoundation

final class AccountsViewController: UITableViewController {

    private let store = AccountsStore.shared
    private let headerView = AccountsHeaderView()

    init() {
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Accounts"
        navigationController?.navigationBar.prefersLargeTitles = false
        tableView.register(AccountCell.self, forCellReuseIdentifier: AccountCell.reuseIdentifier)
        tableView.rowHeight = 84
        tableView.accessibilityIdentifier = "accounts.table"

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(reload), for: .valueChanged)

        NotificationCenter.default.addObserver(self, selector: #selector(accountsChanged),
                                               name: .accountsDidChange, object: nil)
        headerView.configure(customer: SessionManager.shared.customer, accounts: [])
        reload()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let width = tableView.bounds.width
        if tableView.tableHeaderView == nil || tableView.tableHeaderView?.frame.width != width {
            headerView.frame = CGRect(x: 0, y: 0, width: width, height: 132)
            tableView.tableHeaderView = headerView
        }
    }

    @objc private func reload() {
        store.refresh { [weak self] result in
            self?.refreshControl?.endRefreshing()
            if case .failure(let error) = result {
                self?.showError(error, title: "Couldn't load accounts")
            }
        }
    }

    @objc private func accountsChanged() {
        headerView.configure(customer: SessionManager.shared.customer, accounts: store.accounts)
        tableView.reloadData()
    }

    // MARK: - Table

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        store.accounts.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        store.accounts.isEmpty ? nil : "Banking"
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AccountCell.reuseIdentifier, for: indexPath) as! AccountCell
        cell.configure(with: store.accounts[indexPath.row])
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let detail = TransactionsViewController(account: store.accounts[indexPath.row])
        navigationController?.pushViewController(detail, animated: true)
    }
}

final class AccountsHeaderView: UIView {

    private let greetingLabel = UILabel()
    private let totalCaption = UILabel()
    private let totalLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        let card = UIView()
        card.backgroundColor = Theme.navy
        card.layer.cornerRadius = 14
        addSubview(card)
        [greetingLabel, totalCaption, totalLabel].forEach(card.addSubview)

        greetingLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        greetingLabel.textColor = .white
        totalCaption.text = "Total available across deposit accounts"
        totalCaption.font = UIFont.preferredFont(forTextStyle: .footnote)
        totalCaption.textColor = UIColor.white.withAlphaComponent(0.75)
        totalLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 28, weight: .bold)
        totalLabel.textColor = Theme.accent
        totalLabel.accessibilityIdentifier = "accounts.total"

        card.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().inset(4)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        greetingLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(16)
        }
        totalCaption.snp.makeConstraints { make in
            make.top.equalTo(greetingLabel.snp.bottom).offset(10)
            make.leading.trailing.equalTo(greetingLabel)
        }
        totalLabel.snp.makeConstraints { make in
            make.top.equalTo(totalCaption.snp.bottom).offset(2)
            make.leading.trailing.equalTo(greetingLabel)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(customer: Customer?, accounts: [Account]) {
        greetingLabel.text = "\(AccountsHeaderView.greeting()), \(customer?.firstName ?? "")"
        let total = accounts.reduce(Money.zero) { $0 + $1.availableBalance }
        totalLabel.text = total.formatted
    }

    static func greeting(at date: Date = Date()) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone.current
        switch calendar.component(.hour, from: date) {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }
}

final class AccountCell: UITableViewCell {

    static let reuseIdentifier = "AccountCell"

    private let iconView = UIImageView()
    private let nameLabel = UILabel()
    private let numberLabel = UILabel()
    private let balanceLabel = UILabel()
    private let balanceCaption = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        accessoryType = .disclosureIndicator
        iconView.tintColor = Theme.navyLight
        iconView.contentMode = .scaleAspectFit
        nameLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        numberLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
        numberLabel.textColor = .secondaryLabel
        balanceLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 17, weight: .semibold)
        balanceLabel.textAlignment = .right
        balanceCaption.font = UIFont.preferredFont(forTextStyle: .caption2)
        balanceCaption.textColor = .secondaryLabel
        balanceCaption.textAlignment = .right
        balanceCaption.text = "Available"

        [iconView, nameLabel, numberLabel, balanceLabel, balanceCaption].forEach(contentView.addSubview)
        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(28)
        }
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(14)
            make.bottom.equalTo(contentView.snp.centerY).offset(-1)
        }
        numberLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.top.equalTo(contentView.snp.centerY).offset(3)
        }
        balanceLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(8)
            make.bottom.equalTo(nameLabel)
            make.leading.greaterThanOrEqualTo(nameLabel.snp.trailing).offset(8)
        }
        balanceCaption.snp.makeConstraints { make in
            make.trailing.equalTo(balanceLabel)
            make.top.equalTo(numberLabel)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with account: Account) {
        nameLabel.text = account.displayName
        numberLabel.text = "\(Account.productName(for: account.productCode)) \(account.maskedNumber)"
        balanceLabel.text = account.availableBalance.formatted
        iconView.image = UIImage(systemName: account.isSavings ? "banknote" : "creditcard")
        accessibilityLabel = "\(account.displayName), ending \(account.accountNumber.suffix(4)), available \(account.availableBalance.formatted)"
    }
}
