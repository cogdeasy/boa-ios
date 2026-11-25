import UIKit
import SnapKit
import NBFoundation

final class TransactionsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating {

    private var account: Account
    private let service = AccountService()

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let searchController = UISearchController(searchResultsController: nil)
    private let summaryView = AccountSummaryView()
    private let emptyLabel = UILabel()

    private var transactions: [Transaction] = []
    private var searchResults: [Transaction]?
    private var searchTask: URLSessionDataTask?
    private var searchWorkItem: DispatchWorkItem?
    private var total = 0

    private var rows: [Transaction] { searchResults ?? transactions }

    init(account: Account) {
        self.account = account
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = account.displayName
        view.backgroundColor = .systemBackground

        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search transactions"
        searchController.searchBar.searchTextField.backgroundColor = .white
        searchController.searchBar.searchTextField.accessibilityIdentifier = "transactions.search"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(TransactionCell.self, forCellReuseIdentifier: TransactionCell.reuseIdentifier)
        tableView.rowHeight = 64
        tableView.keyboardDismissMode = .onDrag
        tableView.accessibilityIdentifier = "transactions.table"
        view.addSubview(tableView)
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }

        emptyLabel.textAlignment = .center
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)

        summaryView.configure(with: account)
        summaryView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 108)
        tableView.tableHeaderView = summaryView

        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(load), for: .valueChanged)
        tableView.refreshControl = refresh
        load()
    }

    @objc private func load() {
        service.account(account.accountNumber) { [weak self] result in
            if case .success(let account) = result {
                self?.account = account
                self?.summaryView.configure(with: account)
            }
        }
        service.transactions(accountNumber: account.accountNumber) { [weak self] result in
            guard let self = self else { return }
            self.tableView.refreshControl?.endRefreshing()
            switch result {
            case .success(let page):
                self.transactions = page.content
                self.total = page.total
                self.tableView.reloadData()
            case .failure(let error):
                self.showError(error, title: "Couldn't load activity")
            }
        }
    }

    // MARK: - Search

    func updateSearchResults(for searchController: UISearchController) {
        let text = (searchController.searchBar.text ?? "").trimmingCharacters(in: .whitespaces)
        searchWorkItem?.cancel()
        searchTask?.cancel()
        guard text.count >= 2 else {
            searchResults = nil
            tableView.reloadData()
            return
        }
        let work = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.searchTask = self.service.search(query: text, accountNumber: self.account.accountNumber) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let hits):
                    self.searchResults = hits
                    self.tableView.reloadData()
                case .failure(.transport(let message)) where message.lowercased().contains("cancel"):
                    break
                case .failure(let error):
                    self.showError(error, title: "Search failed")
                }
            }
        }
        searchWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: work)
    }

    // MARK: - Table

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableView.backgroundView = rows.isEmpty && searchResults != nil ? emptyLabel : nil
        emptyLabel.text = "No matching transactions"
        return rows.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let results = searchResults {
            return "\(results.count) result\(results.count == 1 ? "" : "s")"
        }
        return transactions.isEmpty ? nil : "Recent activity"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TransactionCell.reuseIdentifier, for: indexPath) as! TransactionCell
        cell.configure(with: rows[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let txn = rows[indexPath.row]
        let message = """
        \(txn.amount.formatted)
        \(txn.channel.displayName) · \(BankDates.displayString(forBusinessDate: txn.businessDate))
        Status: \(txn.status.capitalized)
        Reference: \(txn.id)
        """
        let alert = UIAlertController(title: txn.description, message: message, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Done", style: .cancel))
        present(alert, animated: true)
    }
}

final class AccountSummaryView: UIView {

    private let availableLabel = UILabel()
    private let ledgerLabel = UILabel()
    private let holdLabel = UILabel()
    private let numberLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .secondarySystemBackground
        let caption = UILabel()
        caption.text = "Available balance"
        caption.font = UIFont.preferredFont(forTextStyle: .footnote)
        caption.textColor = .secondaryLabel
        availableLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 30, weight: .bold)
        availableLabel.textColor = Theme.navy
        availableLabel.accessibilityIdentifier = "account.available"
        [ledgerLabel, holdLabel, numberLabel].forEach {
            $0.font = UIFont.preferredFont(forTextStyle: .caption1)
            $0.textColor = .secondaryLabel
        }
        numberLabel.textAlignment = .right
        [caption, availableLabel, ledgerLabel, holdLabel, numberLabel].forEach(addSubview)

        caption.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.leading.equalToSuperview().offset(20)
        }
        numberLabel.snp.makeConstraints { make in
            make.centerY.equalTo(caption)
            make.trailing.equalToSuperview().inset(20)
        }
        availableLabel.snp.makeConstraints { make in
            make.top.equalTo(caption.snp.bottom).offset(2)
            make.leading.equalTo(caption)
        }
        ledgerLabel.snp.makeConstraints { make in
            make.top.equalTo(availableLabel.snp.bottom).offset(6)
            make.leading.equalTo(caption)
        }
        holdLabel.snp.makeConstraints { make in
            make.centerY.equalTo(ledgerLabel)
            make.leading.equalTo(ledgerLabel.snp.trailing).offset(16)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with account: Account) {
        availableLabel.text = account.availableBalance.formatted
        ledgerLabel.text = "Ledger \(account.ledgerBalance.formatted)"
        holdLabel.text = "Holds \((account.holdAmount ?? .zero).formatted)"
        numberLabel.text = account.maskedNumber
    }
}

final class TransactionCell: UITableViewCell {

    static let reuseIdentifier = "TransactionCell"

    private let descriptionLabel = UILabel()
    private let detailLabel = UILabel()
    private let amountLabel = UILabel()
    private let balanceLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        descriptionLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        descriptionLabel.lineBreakMode = .byTruncatingTail
        detailLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        detailLabel.textColor = .secondaryLabel
        amountLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 16, weight: .semibold)
        amountLabel.textAlignment = .right
        amountLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        balanceLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        balanceLabel.textColor = .tertiaryLabel
        balanceLabel.textAlignment = .right
        [descriptionLabel, detailLabel, amountLabel, balanceLabel].forEach(contentView.addSubview)

        descriptionLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.bottom.equalTo(contentView.snp.centerY).offset(-1)
            make.trailing.lessThanOrEqualTo(amountLabel.snp.leading).offset(-8)
        }
        detailLabel.snp.makeConstraints { make in
            make.leading.equalTo(descriptionLabel)
            make.top.equalTo(contentView.snp.centerY).offset(3)
        }
        amountLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(descriptionLabel)
        }
        balanceLabel.snp.makeConstraints { make in
            make.trailing.equalTo(amountLabel)
            make.top.equalTo(detailLabel)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with txn: Transaction) {
        descriptionLabel.text = txn.description
        var detail = "\(BankDates.displayString(forBusinessDate: txn.businessDate)) · \(txn.channel.displayName)"
        if txn.isPending { detail += " · Pending" }
        detailLabel.text = detail
        amountLabel.text = txn.isCredit ? "+\(txn.amount.formatted)" : txn.amount.formatted
        amountLabel.textColor = txn.isCredit ? Theme.credit : .label
        balanceLabel.text = txn.runningBalance.map { "Bal \($0.formatted)" }
    }
}
