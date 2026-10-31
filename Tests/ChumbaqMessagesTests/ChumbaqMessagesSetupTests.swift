#if canImport(UIKit)
import XCTest
@testable import ChumbaqCore
@testable import ChumbaqMessages

/// Covers the order a host app may set things up in.
///
/// Registering the listener used to build the message manager as a side
/// effect of the property's `didSet`. An app that did it before
/// `Chumbaq.shared.initialize` — in `init()`, or at the top of
/// `didFinishLaunching`, which is the obvious place — got a manager carrying
/// an empty project id and an empty device fingerprint, cached for the
/// lifetime of the process. Every check it made was a 403, and a failed
/// check is indistinguishable from nobody being eligible, so in-app
/// messaging was off with nothing anywhere to say so.
final class ChumbaqMessagesSetupTests: XCTestCase {

    private final class ListenerSpy: MessageListener {}

    private var listener: ListenerSpy!

    override func setUp() {
        super.setUp()
        listener = ListenerSpy()
        resetEverything()
    }

    override func tearDown() {
        resetEverything()
        listener = nil
        super.tearDown()
    }

    /// `Chumbaq.resetForTesting` leaves the config bridge alone — it is what
    /// the optional modules read, and a project id left in it from the test
    /// before would look exactly like an initialized SDK here.
    private func resetEverything() {
        ChumbaqMessages.shared.resetForTesting()
        Chumbaq.shared.resetForTesting()
        ChumbaqConfigBridge.projectId = ""
        ChumbaqConfigBridge.deviceFingerprint = ""
        ChumbaqConfigBridge.distinctId = ""
    }

    private func initializeSDK(projectId: String = "project-1") throws {
        let config = try ChumbaqConfig.Builder(
            // Nothing should reach the network; a refused port fails fast.
            baseUrl: "http://127.0.0.1:9",
            apiKey: "k",
            projectId: projectId
        )
        .enableAutoSessionTracking(false)
        .flushInterval(3600)
        .build()
        Chumbaq.shared.initialize(config: config)
    }

    func testTheListenerCanBeSetBeforeInitialize() throws {
        ChumbaqMessages.shared.messageListener = listener

        try initializeSDK()

        let manager = try XCTUnwrap(ChumbaqMessages.shared.manager())
        XCTAssertEqual(manager.projectId, "project-1")
        XCTAssertFalse(manager.deviceFingerprint.isEmpty)
        XCTAssertTrue(manager.messageListener === listener)
    }

    func testTheListenerCanBeSetAfterInitialize() throws {
        try initializeSDK()
        // Builds the manager, as a check would.
        _ = ChumbaqMessages.shared.manager()

        ChumbaqMessages.shared.messageListener = listener

        let manager = try XCTUnwrap(ChumbaqMessages.shared.manager())
        XCTAssertTrue(manager.messageListener === listener)
    }

    /// Nothing is built from a configuration that does not exist yet — the
    /// manager reads the project id and fingerprint once and bakes them into
    /// every request it makes.
    func testNoManagerIsBuiltBeforeInitialize() {
        ChumbaqMessages.shared.messageListener = listener

        XCTAssertNil(ChumbaqMessages.shared.manager())
    }

    func testTheSameManagerIsReusedWhileTheConfigurationHoldsStill() throws {
        try initializeSDK()

        let first = try XCTUnwrap(ChumbaqMessages.shared.manager())
        let second = try XCTUnwrap(ChumbaqMessages.shared.manager())

        XCTAssertTrue(first === second)
    }

    /// Initializing again with another project must not keep sending the old
    /// one's id — which is the same 403, arrived at the other way round.
    func testInitializingAgainWithAnotherProjectRebuildsTheManager() throws {
        try initializeSDK(projectId: "project-1")
        let first = try XCTUnwrap(ChumbaqMessages.shared.manager())

        Chumbaq.shared.resetForTesting()
        try initializeSDK(projectId: "project-2")
        let second = try XCTUnwrap(ChumbaqMessages.shared.manager())

        XCTAssertFalse(first === second)
        XCTAssertEqual(second.projectId, "project-2")
    }
}
#endif
