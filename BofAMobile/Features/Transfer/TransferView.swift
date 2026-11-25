import SwiftUI
import BoAFoundation

struct TransferView: View {

    @StateObject private var model = TransferViewModel()
    @ObservedObject private var store = AccountsStore.shared

    var body: some View {
        NavigationView {
            Group {
                if let result = model.result {
                    TransferConfirmationView(result: result,
                                             amount: model.amount,
                                             from: model.source,
                                             to: model.destination,
                                             onDone: model.reset)
                } else {
                    form
                }
            }
            .navigationTitle("Transfer")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
    }

    private var form: some View {
        Form {
            Section(header: Text("From")) {
                accountPicker(selection: $model.fromAccount, label: "From account")
            }
            Section(header: Text("To")) {
                accountPicker(selection: $model.toAccount, label: "To account")
            }
            Section(header: Text("Amount"), footer: footer) {
                HStack {
                    Text("$").foregroundColor(.secondary)
                    TextField("0.00", text: $model.amountText)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .accessibilityIdentifier("transfer.amount")
                }
                TextField("Memo (optional)", text: $model.memo)
                    .accessibilityIdentifier("transfer.memo")
            }
            if let error = model.errorMessage {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                }
            }
            Section {
                Button(action: { model.showConfirm = true }) {
                    HStack {
                        Spacer()
                        if model.isSubmitting { ProgressView().padding(.trailing, 6) }
                        Text("Review transfer").fontWeight(.semibold)
                        Spacer()
                    }
                }
                .disabled(!model.canReview)
                .accessibilityIdentifier("transfer.review")
            }
        }
        .alert(isPresented: $model.showConfirm) {
            Alert(title: Text("Confirm transfer"),
                  message: Text(confirmText),
                  primaryButton: .default(Text("Transfer now"), action: model.submit),
                  secondaryButton: .cancel())
        }
    }

    private var footer: some View {
        Group {
            if let message = model.validationMessage, !model.amountText.isEmpty {
                Text(message)
            } else {
                Text("Transfers between your Bank of America accounts post immediately.")
            }
        }
    }

    private var confirmText: String {
        let amount = model.amount?.formatted ?? ""
        let from = model.source.map { "\($0.displayName) \($0.maskedNumber.suffix(4))" } ?? ""
        let to = model.destination.map { "\($0.displayName) \($0.maskedNumber.suffix(4))" } ?? ""
        return "Move \(amount) from \(from) to \(to)?"
    }

    private func accountPicker(selection: Binding<String>, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Picker(label, selection: selection) {
                ForEach(store.accounts, id: \.accountNumber) { account in
                    Text("\(account.displayName) \(AccountNumbers.shortMask(account.accountNumber))")
                        .tag(account.accountNumber)
                }
            }
            .pickerStyle(.menu)
            if let account = store.account(number: selection.wrappedValue) {
                Text("Available \(account.availableBalance.formatted)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct TransferConfirmationView: View {
    let result: TransferResult
    let amount: Money?
    let from: Account?
    let to: Account?
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.boaCredit)
            Text("Transfer complete")
                .font(.title2).bold()
            Text(amount?.formatted ?? "")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundColor(.boaNavy)
            VStack(spacing: 6) {
                if let from = from { row("From", "\(from.displayName) \(from.maskedNumber.suffix(4))") }
                if let to = to { row("To", "\(to.displayName) \(to.maskedNumber.suffix(4))") }
                row("Confirmation", result.transferId)
                row("Status", result.status.capitalized)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
            Spacer()
            Button(action: onDone) {
                Text("Make another transfer")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.boaNavy)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).foregroundColor(.secondary)
            Spacer()
            Text(value).fontWeight(.medium)
        }
        .font(.subheadline)
    }
}
