import XCTest
@testable import ChumbaqCore

/// The server accepts an external user id only with the userHash the app's own server
/// made, so identify must send it exactly as given.
final class IdentifyBodyTests: XCTestCase {

    private func manager() throws -> IdentityManager {
        let config = try ChumbaqConfig.Builder(baseUrl: "http://127.0.0.1:9", apiKey: "k", projectId: "project-1").build()
        return IdentityManager(
            requestExecutor: RequestExecutor(apiClient: ApiClient(config: config), baseUrl: config.baseUrl, maxRetries: 0),
            fingerprintProvider: FingerprintProvider(
                preferences: ChumbaqPreferences(suiteName: "com.chumbaq.sdk.tests.\(UUID().uuidString)")
            ),
            deviceInfoCollector: DeviceInfoCollector(),
            projectId: "project-1",
            enableAutoDeviceInfo: false
        )
    }

    func testSendsTheUserHashWithTheExternalId() throws {
        let params = IdentifyParams.Builder().externalUserId("user-42").userHash("ab12").build()
        let body = try manager().buildIdentifyBody(params)
        XCTAssertEqual(body["externalUserId"] as? String, "user-42")
        XCTAssertEqual(body["userHash"] as? String, "ab12")
    }

    func testSendsNoUserHashWhenNoneIsGiven() throws {
        let body = try manager().buildIdentifyBody(IdentifyParams.Builder().build())
        XCTAssertNil(body["userHash"])
    }
}
