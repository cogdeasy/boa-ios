import SwiftUI
import BoAFoundation

struct SendMoneyView: View {

    enum RecipientKind: String, CaseIterable, Identifiable {
        case email = "Email"
        case phone = "Mobile"
        var id: String { rawValue }
    }

    @ObservedObject var model: PaymentsViewModel
    @State private var kind: RecipientKind = .email
    @State private var recipient = ""
    @State private var fromAccount = ""
    @State private var amountText = ""
    @State private var memo = ""
    @State private var submitting = false
    @State private var confirmation: PaymentResult?
    @State private var error: String?

    private var amount: Money? {
        Money(string: amountText.replacingOccurrences(of: ",", with: "")).flatMap { $0.isPositive ? $0 : nil }
    }

    private var isRecipientValid: Bool {
        let value = recipient.trimmingCharacters(in: .whitespaces)
        switch kind {
        case .email: return value.contains("@") && value.contains(".")
        case .phone: return value.filter(\.isNumber).count == 10
        }
    }

    var body: some View {
        Group {
            if let confirmation = confirmation {
                PaymentSuccessView(title: "Money sent",
                                   detail: "\(amount?.formatted ?? "") to \(recipient)",
                                   paymentId: confirmation.paymentId)
            } else {
                form
            }
        }
        .navigationTitle("Send money")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var form: some View {
        Form {
            Section(header: Text("Recipient")) {
                Picker("Send to", selection: $kind) {
                    ForEach(RecipientKind.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                TextField(kind == .email ? "name@example.com" : "(201) 555-0142", text: $recipient)
                    .keyboardType(kind == .email ? .emailAddress : .phonePad)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .accessibilityIdentifier("p2p.recipient")
            }
            Section(header: Text("Payment")) {
                FromAccountPicker(selection: $fromAccount)
                HStack {
                    Text("Amount")
                    Spacer()
                    TextField("$0.00", text: $amountText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .accessibilityIdentifier("p2p.amount")
                }
                TextField("What's it for?", text: $memo)
            }
            if let error = error {
                Section { Text(error).foregroundColor(.red) }
            }
            Section {
                Button(action: submit) {
                    HStack {
                        Spacer()
                        if submitting { ProgressView().padding(.trailing, 6) }
                        Text("Send").fontWeight(.semibold)
                        Spacer()
                    }
                }
                .disabled(!isRecipientValid || amount == nil || fromAccount.isEmpty || submitting)
                .accessibilityIdentifier("p2p.submit")
            }
        }
    }

    private func submit() {
        guard let amount = amount else { return }
        let value = recipient.trimmingCharacters(in: .whitespaces)
        let target = kind == .email ? P2PRecipient(email: value, phone: nil)
                                    : P2PRecipient(email: nil, phone: value.filter(\.isNumber))
        submitting = true
        error = nil
        model.sendMoney(from: fromAccount, recipient: target, amount: amount, memo: memo) { result in
            submitting = false
            switch result {
            case .success(let payment): confirmation = payment
            case .failure(let failure): error = failure.userMessage
            }
        }
    }
}
