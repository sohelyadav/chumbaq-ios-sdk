import Foundation

/// Verbosity of the Chumbaq SDK's internal logger.
///
/// Mirrors `com.chumbaq.sdk.internal.util.LogLevel` on Android. Values are
/// ordered from least to most verbose so simple ordinal comparisons
/// control which messages are emitted.
@objc public enum ChumbaqLogLevel: Int, Sendable {
    case none = 0
    case error = 1
    case warn = 2
    case info = 3
    case debug = 4
    case verbose = 5
}
