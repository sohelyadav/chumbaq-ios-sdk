import Foundation

/// Typed errors surfaced by the Chumbaq SDK.
///
/// Mirrors the `ChumbaqError` sealed class hierarchy on Android. Every
/// case carries a `localizedDescription` so it can be logged without
/// manual unwrapping.
public enum ChumbaqError: Error, CustomStringConvertible, Sendable {

    /// The SDK has not been initialized via `Chumbaq.shared.initialize`.
    case notInitialized(String = "Chumbaq SDK not initialized")

    /// The SDK was configured with invalid parameters.
    case invalidConfig(String)

    /// A transport-level network failure — no response received, or a
    /// response whose status we could not interpret.
    case networkError(message: String, statusCode: Int? = nil, underlying: Error? = nil)

    /// The server returned a non-success HTTP status.
    case apiError(message: String, statusCode: Int, responseBody: String? = nil)

    public var description: String {
        switch self {
        case .notInitialized(let msg):
            return "ChumbaqError.notInitialized: \(msg)"
        case .invalidConfig(let msg):
            return "ChumbaqError.invalidConfig: \(msg)"
        case .networkError(let msg, let code, _):
            return "ChumbaqError.networkError: \(msg)\(code.map { " (status \($0))" } ?? "")"
        case .apiError(let msg, let code, _):
            return "ChumbaqError.apiError: \(msg) (status \(code))"
        }
    }
}

extension ChumbaqError: LocalizedError {
    public var errorDescription: String? { description }
}
