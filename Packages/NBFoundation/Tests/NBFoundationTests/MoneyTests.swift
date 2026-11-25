import XCTest
@testable import NBFoundation

final class MoneyTests: XCTestCase {

    func testParsesApiString() {
        let money = Money(string: "4812.33")
        XCTAssertEqual(money?.apiString, "4812.33")
        XCTAssertEqual(money?.formatted, "$4,812.33")
    }

    func testNegativeAmountsFormatWithSign() {
        let money = Money(string: "-42.18")
        XCTAssertTrue(money?.isNegative ?? false)
        XCTAssertEqual(money?.formatted, "-$42.18")
    }

    func testRejectsGarbage() {
        XCTAssertNil(Money(string: ""))
        XCTAssertNil(Money(string: "abc"))
    }

    func testArithmetic() {
        let a = Money(string: "100.00")!
        let b = Money(string: "42.18")!
        XCTAssertEqual((a - b).apiString, "57.82")
    }
}
