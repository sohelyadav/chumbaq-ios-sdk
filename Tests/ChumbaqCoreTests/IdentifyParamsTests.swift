import XCTest
@testable import ChumbaqCore

final class IdentifyParamsTests: XCTestCase {
    func testWhatsappOptInIsCarriedByBuilder() {
        let params = IdentifyParams.Builder().whatsappOptIn(false).build()
        XCTAssertEqual(params.whatsappOptIn, false)
    }

    func testWhatsappOptInDefaultsToNil() {
        let params = IdentifyParams.Builder().externalUserId("u_1").build()
        XCTAssertNil(params.whatsappOptIn)
    }
}
