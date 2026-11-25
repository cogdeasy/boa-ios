import SwiftUI
import BoAFoundation

struct BillPayView: View {

    @ObservedObject var model: PaymentsViewModel
    @State private var payeeId = ""
    @State private var fromAccount = ""
    @State private var amountText = ""
    @State private var sendOn = Date()
    @State private var submitting = false
    @State private var confirmation: PaymentResult?
    @State private var error: String?

    private var payee: Payee? { model.payees.first { $0.payeeId == payeeId } }
    private var amount: Money? {
        Money(string: amountText.replacingOccurrences(of: ",", with: "")).flatMap { $0.isPositive ? $0 : nil }
    }

    var body: some View {
        Group {
            if let confirmation = confirmation, let payee = payee {
                PaymentSuccessView(title: "Payment scheduled",
                                   detail: "\(amount?.formatted ?? "") to \(payee.name) on \(BankDates.displayDateFormatter.string(from: sendOn))",
                                   paymentId: confirmation.paymentId)
            } else {
                form
            }
        }
        .navigationTitle("Pay bills")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var form: some View {
        Form {
            Section(header: Text("Payee")) {
                Picker("Pay to", selection: $payeeId) {
                    ForEach(model.payees) { payee in
                        Text("\(payee.name) \(payee.accountRef)").tag(payee.payeeId)
                    }
                }
                .accessibilityIdentifier("bill.payee")
            }
            Section(header: Text("Payment")) {
                FromAccountPicker(selection: $fromAccount)
                HStack {
                    Text("Amount")
                    Spacer()
                    TextField("$0.00", text: $amountText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .accessibilityIdentifier("bill.amount")
                }
                DatePicker("Send on", selection: $sendOn, in: Date()..., displayedComponents: .date)
            }
            if let error = error {
                Section { Text(error).foregroundColor(.red) }
            }
            Section {
                Button(action: submit) {
                    HStack {
                        Spacer()
                        if submitting { ProgressView().padding(.trailing, 6) }
                        Text("Schedule payment").fontWeight(.semibold)
                        Spacer()
                    }
                }
                .disabled(payee == nil || amount == nil || fromAccount.isEmpty || submitting)
                .accessibilityIdentifier("bill.submit")
            }
        }
        .onAppear {
            if payeeId.isEmpty { payeeId = model.payees.first?.payeeId ?? "" }
        }
    }

    private func submit() {
        guard let payee = payee, let amount = amount else { return }
        submitting = true
        error = nil
        model.payBill(from: fromAccount, payee: payee, amount: amount, sendOn: sendOn) { result in
            submitting = false
            switch result {
            case .success(let payment): confirmation = payment
            case .failure(let failure): error = failure.userMessage
            }
        }
    }
}
