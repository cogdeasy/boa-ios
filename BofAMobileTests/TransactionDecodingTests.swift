import XCTest
import BoAFoundation
@testable import BofAMobile

final class TransactionDecodingTests: XCTestCase {

    func testDecodesContractTransaction() throws {
        let json = """
        { "id": 99812, "accountNumber": "104000123455", "postedAt": "2026-11-02T14:03:11",
          "businessDate": "2026-11-02", "type": "DEBIT", "channel": "CARD", "amount": "-42.18",
          "runningBalance": "4812.33", "description": "WHOLE FDS MKT #10233", "status": "POSTED" }
        """.data(using: .utf8)!

        let txn = try JSONDecoder().decode(Transaction.self, from: json)

        XCTAssertEqual(txn.id, 99812)
        XCTAssertEqual(txn.channel, .card)
        XCTAssertEqual(txn.amount.apiString, "-42.18")
        XCTAssertFalse(txn.isCredit)
    }

    func testUnknownChannelDoesNotFailDecoding() throws {
        let json = """
        { "id": 1, "accountNumber": "104000123455", "postedAt": "2026-11-02T14:03:11",
          "businessDate": "2026-11-02", "type": "CREDIT", "channel": "RTP", "amount": "10.00",
          "description": "INSTANT PAYMENT", "status": "POSTED" }
        """.data(using: .utf8)!

        let txn = try JSONDecoder().decode(Transaction.self, from: json)

        XCTAssertEqual(txn.channel, .unknown)
        XCTAssertNil(txn.runningBalance)
    }

    func testDecodesAccount() throws {
        let json = """
        { "accountNumber": "104000123455", "maskedNumber": "********3455", "cif": "100000001",
          "productCode": "DDA-CHK", "nickname": "Advantage Checking", "status": "OPEN",
          "ledgerBalance": "4812.33", "availableBalance": "4712.33", "holdAmount": "100.00",
          "openedOn": "2014-03-11" }
        """.data(using: .utf8)!

        let account = try JSONDecoder().decode(Account.self, from: json)

        XCTAssertEqual(account.displayName, "Advantage Checking")
        XCTAssertTrue(account.isChecking)
        XCTAssertEqual(account.availableBalance.formatted, "$4,712.33")
    }
}
