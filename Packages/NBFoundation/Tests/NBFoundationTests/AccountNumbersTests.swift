import XCTest
@testable import NBFoundation

final class AccountNumbersTests: XCTestCase {

    func testSeedAccountsPassLuhn() {
        XCTAssertTrue(AccountNumbers.isValid("104000123455"))
        XCTAssertTrue(AccountNumbers.isValid("104000123463"))
    }

    func testRejectsBadCheckDigit() {
        XCTAssertFalse(AccountNumbers.isValid("104000123456"))
    }

    func testMask() {
        XCTAssertEqual(AccountNumbers.mask("104000123455"), "********3455")
        XCTAssertEqual(AccountNumbers.shortMask("104000123455"), "...3455")
    }
}
