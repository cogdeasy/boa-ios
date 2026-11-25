import SwiftUI
import BoAFoundation

struct PaymentsHubView: View {

    @StateObject private var model = PaymentsViewModel()

    var body: some View {
        NavigationView {
            List {
                Section {
                    NavigationLink(destination: BillPayView(model: model)) {
                        HubRow(icon: "doc.text.fill", title: "Pay bills",
                               subtitle: "\(model.payees.count) saved payees")
                    }
                    .accessibilityIdentifier("pay.billPay")
                    NavigationLink(destination: SendMoneyView(model: model)) {
                        HubRow(icon: "paperplane.fill", title: "Send money",
                               subtitle: "To anyone with an email or US mobile number")
                    }
                    .accessibilityIdentifier("pay.sendMoney")
                }
                Section(header: Text("Recent payments")) {
                    if model.history.isEmpty {
                        Text(model.isLoading ? "Loading…" : "No recent payments")
                            .foregroundColor(.secondary)
                    }
                    ForEach(model.history) { payment in
                        PaymentRow(payment: payment)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Pay & Send")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: model.load)
        }
        .navigationViewStyle(.stack)
    }
}

private struct HubRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.white)
                .frame(width: 38, height: 38)
                .background(Color.boaNavy)
                .clipShape(RoundedRectangle(cornerRadius: 9))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct PaymentRow: View {
    let payment: Payment

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(payment.title).font(.subheadline).fontWeight(.medium)
                Text("\(payment.type == "P2P" ? "Send money" : "Bill pay") · \(payment.status.capitalized) · \(payment.paymentId)")
                    .font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Text(payment.amount.formatted)
                .font(.system(.subheadline, design: .rounded)).fontWeight(.semibold)
        }
    }
}

struct FromAccountPicker: View {
    @Binding var selection: String
    @ObservedObject private var store = AccountsStore.shared

    var body: some View {
        Picker("Pay from", selection: $selection) {
            ForEach(store.accounts, id: \.accountNumber) { account in
                Text("\(account.displayName) \(AccountNumbers.shortMask(account.accountNumber))")
                    .tag(account.accountNumber)
            }
        }
        .onAppear {
            if selection.isEmpty, let checking = store.accounts.first(where: { $0.isChecking }) {
                selection = checking.accountNumber
            }
        }
    }
}

struct PaymentSuccessView: View {
    let title: String
    let detail: String
    let paymentId: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 60))
                .foregroundColor(.boaCredit)
            Text(title).font(.title3).bold()
            Text(detail).multilineTextAlignment(.center).foregroundColor(.secondary)
            Text("Confirmation \(paymentId)")
                .font(.footnote.monospacedDigit())
                .padding(8)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
        }
        .padding()
    }
}
