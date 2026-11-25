import XCTest
@testable import BofAMobile

final class EndpointTests: XCTestCase {

    func testTransactionsRequestUsesContractPathAndPaging() {
        let client = APIClient(environment: .local)
        let request = client.makeRequest(for: .transactions(accountNumber: "104000123455", page: 0, size: 50))

        XCTAssertEqual(request?.url?.path, "/api/v1/accounts/104000123455/transactions")
        XCTAssertEqual(request?.url?.query, "page=0&size=50")
    }

    func testPaymentsRequestsGoToPaymentsHub() {
        let client = APIClient(environment: .local)
        let request = client.makeRequest(for: .payees(cif: "100000001"))

        XCTAssertEqual(request?.url?.port, 8081)
        XCTAssertEqual(request?.url?.path, "/api/v1/payments/payees")
    }
}
