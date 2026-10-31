import Foundation
import ChumbaqCore

/// Entry point for Chumbaq in-app messages.
///
/// Requires `Chumbaq.shared.initialize` first.
///
/// ```swift
/// // On app foreground:
/// ChumbaqMessages.shared.onAppOpen()
///
/// // On screen change:
/// ChumbaqMessages.shared.onScreenView("HomeScreen")
///
/// // On custom event:
/// ChumbaqMessages.shared.onEvent("purchase_complete")
/// ```
public final class ChumbaqMessages: @unchecked Sendable {
    public static let shared = ChumbaqMessages()

    private let apiClient = MessageApiClient()
    private let lock = NSLock()

    #if canImport(UIKit)
    private var _manager: MessageManager?
    #endif

    private weak var _messageListener: MessageListener?

    /// Protocol-based listener for message interactions.
    ///
    /// Can be set in any order relative to `Chumbaq.shared.initialize` —
    /// which is worth saying because it could not be. Setting it used to
    /// build the message manager as a side effect, so an app that registered
    /// its listener in `init()` or `didFinishLaunching` before initializing
    /// the SDK — the obvious order, and the one the docs' own snippet
    /// suggests — got a manager carrying an empty project id and an empty
    /// fingerprint, cached for the lifetime of the process. Every check it
    /// then made was a 403, and a failed check is indistinguishable from
    /// nobody being eligible, so in-app messaging was simply off with
    /// nothing anywhere to say so.
    public var messageListener: MessageListener? {
        get {
            lock.lock(); defer { lock.unlock() }
            return _messageListener
        }
        set {
            lock.lock()
            _messageListener = newValue
            #if canImport(UIKit)
            // Only if one exists. Never builds one.
            _manager?.messageListener = newValue
            #endif
            lock.unlock()
        }
    }

    private init() {}

    // ── Trigger points ─────────────────────────────────────────────────

    /// Check for and display `on_app_open` / `scheduled` messages.
    /// Call from your app's foreground lifecycle callback.
    public func onAppOpen() {
        checkAndShow(.init())
    }

    /// Check for and display `on_screen` messages targeting `screen`.
    public func onScreenView(_ screen: String) {
        checkAndShow(.init(screen: screen))
    }

    /// Check for and display `on_event` messages targeting `event`.
    public func onEvent(_ event: String) {
        checkAndShow(.init(event: event))
    }

    // ── Internal ───────────────────────────────────────────────────────

    private func checkAndShow(_ context: MessageApiClient.CheckContext) {
        precondition(Chumbaq.shared.isInitialized,
                     "Chumbaq.shared.initialize(config:) must be called before using ChumbaqMessages")
        #if canImport(UIKit)
        guard let manager = manager() else { return }
        Task {
            await manager.checkAndShow(context: context)
        }
        #endif
    }

    #if canImport(UIKit)
    /// The manager for the project the SDK is initialized with, or `nil`
    /// while it is not initialized at all.
    ///
    /// Built on first use and rebuilt whenever the configuration it was
    /// built from has changed — the project id and the device fingerprint
    /// are read once and baked into every request the manager makes, so a
    /// manager outliving them sends the wrong ones forever.
    internal func manager() -> MessageManager? {
        lock.lock(); defer { lock.unlock() }

        let projectId = ChumbaqConfigBridge.projectId
        let fingerprint = ChumbaqConfigBridge.deviceFingerprint
        guard !projectId.isEmpty else { return nil }

        if let existing = _manager,
           existing.projectId == projectId,
           existing.deviceFingerprint == fingerprint {
            return existing
        }

        let manager = MessageManager(
            apiClient: apiClient,
            projectId: projectId,
            deviceFingerprint: fingerprint,
            distinctIdProvider: { ChumbaqConfigBridge.distinctId.isEmpty ? nil : ChumbaqConfigBridge.distinctId }
        )
        manager.messageListener = _messageListener
        _manager = manager
        return manager
    }
    #endif

    /// Test-only reset, so one test's listener and manager are not the next
    /// test's. Mirrors `Chumbaq.resetForTesting`.
    internal func resetForTesting() {
        lock.lock()
        _messageListener = nil
        #if canImport(UIKit)
        _manager = nil
        #endif
        lock.unlock()
    }
}
