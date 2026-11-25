import UIKit
import SnapKit

final class LoginViewController: UIViewController, UITextFieldDelegate {

    var onSignedIn: (() -> Void)?

    private let logoPlate = UIView()
    private let logoView = UIImageView(image: UIImage(named: "BofALogo"))
    private let taglineLabel = UILabel()
    private let card = UIView()
    private let onlineIdField = UITextField()
    private let passcodeField = UITextField()
    private let rememberSwitch = UISwitch()
    private let rememberLabel = UILabel()
    private let signInButton = UIButton(type: .system)
    private let spinner = UIActivityIndicatorView(style: .medium)
    private let environmentLabel = UILabel()

    private let credentialStore = CredentialStore.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        view.backgroundColor = Theme.navy
        buildLayout()
        restoreSavedCredentials()

        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing(_:)))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    private func buildLayout() {
        logoPlate.backgroundColor = .white
        logoPlate.layer.cornerRadius = 14

        logoView.contentMode = .scaleAspectFit
        logoView.isAccessibilityElement = true
        logoView.accessibilityLabel = "Bank of America"
        logoView.accessibilityTraits = .image
        logoView.accessibilityIdentifier = "login.logo"

        taglineLabel.text = "MOBILE BANKING"
        taglineLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        taglineLabel.textColor = Theme.accent

        card.backgroundColor = .systemBackground
        card.layer.cornerRadius = 14

        configure(onlineIdField, placeholder: "Online ID")
        onlineIdField.autocapitalizationType = .none
        onlineIdField.autocorrectionType = .no
        onlineIdField.textContentType = .username
        onlineIdField.accessibilityIdentifier = "login.onlineId"
        onlineIdField.returnKeyType = .next

        configure(passcodeField, placeholder: "Passcode")
        passcodeField.isSecureTextEntry = true
        passcodeField.textContentType = .password
        passcodeField.accessibilityIdentifier = "login.passcode"
        passcodeField.returnKeyType = .go

        rememberLabel.text = "Remember me"
        rememberLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        rememberSwitch.onTintColor = Theme.navyLight

        signInButton.setTitle("Sign In", for: .normal)
        signInButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        signInButton.backgroundColor = Theme.navy
        signInButton.setTitleColor(.white, for: .normal)
        signInButton.layer.cornerRadius = 10
        signInButton.accessibilityIdentifier = "login.signIn"
        signInButton.addTarget(self, action: #selector(signInTapped), for: .touchUpInside)

        spinner.color = .white
        spinner.hidesWhenStopped = true

        environmentLabel.numberOfLines = 0
        environmentLabel.textAlignment = .center
        environmentLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
        environmentLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        if AppEnvironment.current.usesMockBackend {
            environmentLabel.text = "MOCK API · sign in as dana.whitfield / Welcome1!"
        } else if AppEnvironment.current.name != .production {
            environmentLabel.text = "\(AppEnvironment.current.name.rawValue) · \(AppEnvironment.current.coreBankingBaseURL.host ?? "")"
        }

        [logoPlate, taglineLabel, card, environmentLabel].forEach(view.addSubview)
        logoPlate.addSubview(logoView)
        [onlineIdField, passcodeField, rememberLabel, rememberSwitch, signInButton].forEach(card.addSubview)
        signInButton.addSubview(spinner)

        logoPlate.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(56)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        logoView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 22, left: 24, bottom: 22, right: 24))
            if let logo = logoView.image {
                make.height.equalTo(logoView.snp.width).multipliedBy(logo.size.height / logo.size.width)
            }
        }
        taglineLabel.snp.makeConstraints { make in
            make.top.equalTo(logoPlate.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
        }
        card.snp.makeConstraints { make in
            make.top.equalTo(taglineLabel.snp.bottom).offset(40)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        onlineIdField.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(48)
        }
        passcodeField.snp.makeConstraints { make in
            make.top.equalTo(onlineIdField.snp.bottom).offset(12)
            make.leading.trailing.height.equalTo(onlineIdField)
        }
        rememberSwitch.snp.makeConstraints { make in
            make.top.equalTo(passcodeField.snp.bottom).offset(16)
            make.trailing.equalTo(passcodeField)
        }
        rememberLabel.snp.makeConstraints { make in
            make.centerY.equalTo(rememberSwitch)
            make.leading.equalTo(passcodeField)
        }
        signInButton.snp.makeConstraints { make in
            make.top.equalTo(rememberSwitch.snp.bottom).offset(20)
            make.leading.trailing.equalTo(onlineIdField)
            make.height.equalTo(50)
            make.bottom.equalToSuperview().inset(20)
        }
        spinner.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(16)
        }
        environmentLabel.snp.makeConstraints { make in
            make.top.equalTo(card.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(24)
        }
    }

    private func configure(_ field: UITextField, placeholder: String) {
        field.placeholder = placeholder
        field.borderStyle = .none
        field.backgroundColor = .secondarySystemBackground
        field.layer.cornerRadius = 8
        field.font = UIFont.preferredFont(forTextStyle: .body)
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        field.leftViewMode = .always
        field.clearButtonMode = .whileEditing
        field.delegate = self
    }

    private func restoreSavedCredentials() {
        rememberSwitch.isOn = credentialStore.rememberMe
        guard credentialStore.rememberMe else { return }
        onlineIdField.text = credentialStore.savedOnlineId
        passcodeField.text = credentialStore.savedPasscode
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == onlineIdField {
            passcodeField.becomeFirstResponder()
        } else {
            signInTapped()
        }
        return true
    }

    @objc private func signInTapped() {
        view.endEditing(true)
        let onlineId = onlineIdField.text ?? ""
        let passcode = passcodeField.text ?? ""
        setLoading(true)

        SessionManager.shared.signIn(onlineId: onlineId, passcode: passcode) { [weak self] result in
            guard let self = self else { return }
            self.setLoading(false)
            switch result {
            case .success:
                self.credentialStore.rememberMe = self.rememberSwitch.isOn
                if self.rememberSwitch.isOn {
                    self.credentialStore.save(onlineId: onlineId, passcode: passcode)
                } else {
                    self.credentialStore.clear()
                }
                self.onSignedIn?()
            case .failure(let error):
                self.showError(error, title: "Unable to sign in")
            }
        }
    }

    private func setLoading(_ loading: Bool) {
        signInButton.isEnabled = !loading
        signInButton.alpha = loading ? 0.7 : 1
        loading ? spinner.startAnimating() : spinner.stopAnimating()
    }
}
