//
//  MockSeedData.swift
//  BofAMobile
//
//  Local-profile seed data (matches the core-banking local profile).
//

import Foundation
import BoAFoundation

enum MockSeedData {

    struct Entry {
        let daysAgo: Int
        let hour: Int
        let description: String
        let channel: Transaction.Channel
        let amount: Decimal

        init(_ daysAgo: Int, _ hour: Int, _ description: String, _ channel: Transaction.Channel, _ amount: String) {
            self.daysAgo = daysAgo
            self.hour = hour
            self.description = description
            self.channel = channel
            self.amount = Decimal(string: amount, locale: Locale(identifier: "en_US_POSIX"))!
        }
    }

    static func load(into backend: MockBackend) {
        backend.seedCustomer(Customer(cif: "100000001", firstName: "Dana", lastName: "Whitfield",
                                      email: "dana.whitfield@example.com", segment: "PREFERRED", kycStatus: "VERIFIED"))
        backend.seedCustomer(Customer(cif: "100000002", firstName: "Marcus", lastName: "Oyelaran",
                                      email: "marcus.oyelaran@example.com", segment: "MASS", kycStatus: "VERIFIED"))

        backend.seedAccount(MockAccount(accountNumber: "104000123455", cif: "100000001", productCode: "DDA-CHK",
                                        nickname: "Advantage Checking", ledger: dec("4812.33"), hold: dec("100.00"),
                                        openedOn: "2014-03-11"))
        backend.seedAccount(MockAccount(accountNumber: "104000123463", cif: "100000001", productCode: "DDA-SAV",
                                        nickname: "Advantage Savings", ledger: dec("22150.00"), openedOn: "2014-03-11"))
        backend.seedAccount(MockAccount(accountNumber: "211000048218", cif: "100000002", productCode: "DDA-CHK",
                                        nickname: "Advantage Checking", ledger: dec("1045.12"), openedOn: "2019-07-22"))
        backend.seedAccount(MockAccount(accountNumber: "211000048226", cif: "100000002", productCode: "DDA-SAV",
                                        nickname: "Advantage Savings", ledger: dec("9300.00"), openedOn: "2019-07-22"))
        backend.seedAccount(MockAccount(accountNumber: MockBackend.suspenseGL, cif: nil, productCode: "GL-SUSP",
                                        nickname: "Payments Suspense", ledger: 0, openedOn: "2009-01-01"))

        backend.seedTransactions(accountNumber: "104000123455", entries: danaChecking)
        backend.seedTransactions(accountNumber: "104000123463", entries: danaSavings)
        backend.seedTransactions(accountNumber: "211000048218", entries: [
            Entry(1, 9, "STARBUCKS STORE 11842", .card, "-6.45"),
            Entry(3, 8, "PAYROLL HARBORVIEW HEALTH ACH", .ach, "1680.40"),
            Entry(5, 18, "SHELL OIL 57444", .card, "-48.10"),
            Entry(9, 12, "CVS/PHARMACY #04411", .card, "-23.89")
        ])

        backend.seedPayees([
            Payee(payeeId: "PY-1001", name: "Con Edison", category: "UTILITY", accountRef: "****7781"),
            Payee(payeeId: "PY-1002", name: "Verizon Wireless", category: "TELECOM", accountRef: "****0423"),
            Payee(payeeId: "PY-1003", name: "BofA Card Services", category: "CREDIT_CARD", accountRef: "****9921"),
            Payee(payeeId: "PY-1004", name: "Hudson Valley Water", category: "UTILITY", accountRef: "****5560")
        ], cif: "100000001")
        backend.seedPayees([
            Payee(payeeId: "PY-2001", name: "PSE&G", category: "UTILITY", accountRef: "****3310")
        ], cif: "100000002")

        backend.seedPayments([
            Payment(paymentId: "BP-4402", type: "BILL", fromAccount: "104000123455", amount: Money(string: "142.67")!,
                    status: "COMPLETED", createdAt: stamp(daysAgo: 12), payeeId: "PY-1001", payeeName: "Con Edison",
                    recipient: nil, memo: nil, sendOn: day(daysAgo: 11)),
            Payment(paymentId: "P2P-4405", type: "P2P", fromAccount: "104000123455", amount: Money(string: "60.00")!,
                    status: "SENT", createdAt: stamp(daysAgo: 6), payeeId: nil, payeeName: nil,
                    recipient: P2PRecipient(email: "j.alvarez@example.com", phone: nil), memo: "Concert tickets",
                    sendOn: nil),
            Payment(paymentId: "BP-4409", type: "BILL", fromAccount: "104000123455", amount: Money(string: "89.99")!,
                    status: "COMPLETED", createdAt: stamp(daysAgo: 4), payeeId: "PY-1002", payeeName: "Verizon Wireless",
                    recipient: nil, memo: nil, sendOn: day(daysAgo: 3))
        ], cif: "100000001")
    }

    static let danaChecking: [Entry] = [
        Entry(0, 8, "BLUE BOTTLE COFFEE #118", .card, "-5.75"),
        Entry(0, 7, "WHOLE FDS MKT #10233", .card, "-42.18"),
        Entry(1, 19, "UBER *TRIP HELP.UBER.COM", .card, "-18.32"),
        Entry(1, 12, "SWEETGREEN BROOKFIELD PL", .card, "-14.95"),
        Entry(2, 9, "BLUE BOTTLE COFFEE #118", .card, "-6.25"),
        Entry(2, 6, "NETFLIX.COM", .card, "-15.49"),
        Entry(3, 10, "BILLPAY VERIZON WIRELESS", .billPay, "-89.99"),
        Entry(3, 8, "ATM WITHDRAWAL 0412 HOBOKEN NJ", .atm, "-100.00"),
        Entry(4, 13, "AMAZON MKTPL*2K4QZ81", .card, "-37.60"),
        Entry(5, 17, "TRADER JOE'S #507", .card, "-64.22"),
        Entry(5, 8, "STARBUCKS STORE 08812", .card, "-4.95"),
        Entry(6, 15, "P2P TO J.ALVAREZ@EXAMPLE.COM", .p2p, "-60.00"),
        Entry(7, 6, "PAYROLL NORTHWIND LOGISTICS ACH", .ach, "3245.18"),
        Entry(7, 11, "NJ TRANSIT MOBILE TIX", .card, "-11.50"),
        Entry(8, 20, "SPOTIFY USA", .card, "-11.99"),
        Entry(9, 9, "BLUE BOTTLE COFFEE #118", .card, "-5.75"),
        Entry(9, 18, "SHOPRITE HOBOKEN", .card, "-88.41"),
        Entry(10, 14, "CVS/PHARMACY #08123", .card, "-21.37"),
        Entry(11, 9, "BILLPAY CON EDISON", .billPay, "-142.67"),
        Entry(12, 16, "ONLINE TRANSFER TO ADVANTAGE SAVINGS ...3463", .transfer, "-500.00"),
        Entry(13, 12, "CHIPOTLE 2291", .card, "-12.85"),
        Entry(14, 6, "PAYROLL NORTHWIND LOGISTICS ACH", .ach, "3245.18"),
        Entry(14, 10, "RENT PAYMENT HARBOR POINT ACH", .ach, "-2650.00"),
        Entry(15, 19, "HOME DEPOT #0918", .card, "-73.04"),
        Entry(16, 8, "STARBUCKS STORE 08812", .card, "-5.45"),
        Entry(17, 13, "APPLE.COM/BILL", .card, "-2.99"),
        Entry(18, 11, "BRANCH DEPOSIT HOBOKEN WASHINGTON ST", .branch, "250.00"),
        Entry(19, 17, "WHOLE FDS MKT #10233", .card, "-58.70"),
        Entry(20, 21, "DOORDASH*THAI VILLA", .card, "-34.12"),
        Entry(21, 6, "PAYROLL NORTHWIND LOGISTICS ACH", .ach, "3245.18"),
        Entry(22, 10, "GEICO AUTO PMT", .ach, "-118.40"),
        Entry(23, 9, "BLUE BOTTLE COFFEE #118", .card, "-6.25"),
        Entry(24, 15, "MONTHLY MAINTENANCE FEE REFUND", .fee, "12.00"),
        Entry(24, 14, "MONTHLY MAINTENANCE FEE", .fee, "-12.00"),
        Entry(26, 18, "TARGET T-2391", .card, "-46.83"),
        Entry(28, 6, "PAYROLL NORTHWIND LOGISTICS ACH", .ach, "3245.18"),
        Entry(28, 10, "RENT PAYMENT HARBOR POINT ACH", .ach, "-2650.00"),
        Entry(30, 12, "INCOMING WIRE REF 20261026-88142", .wire, "1200.00")
    ]

    static let danaSavings: [Entry] = [
        Entry(5, 3, "INTEREST PAYMENT", .interest, "18.42"),
        Entry(12, 16, "ONLINE TRANSFER FROM ADVANTAGE CHECKING ...3455", .transfer, "500.00"),
        Entry(26, 16, "ONLINE TRANSFER FROM ADVANTAGE CHECKING ...3455", .transfer, "500.00"),
        Entry(35, 3, "INTEREST PAYMENT", .interest, "17.96")
    ]

    private static func dec(_ value: String) -> Decimal {
        Decimal(string: value, locale: Locale(identifier: "en_US_POSIX"))!
    }

    private static func day(daysAgo: Int) -> String {
        BankDates.businessDateString(Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!)
    }

    private static func stamp(daysAgo: Int) -> String {
        BankDates.timestampString(Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!)
    }
}
