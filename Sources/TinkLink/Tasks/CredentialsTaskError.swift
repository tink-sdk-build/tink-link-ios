import Foundation

/// Error that the `AddCredentialsTask` can throw.
public struct CredentialsTaskError: Swift.Error, CustomStringConvertible {
    public struct Code: Hashable {
        enum Value {
            case authenticationFailed
            case temporaryFailure
            case permanentFailure
            case credentialsAlreadyExists
            case credentialsDeleted
            case credentialsSessionExpired
            case cancelled
        }

        var value: Value

        /// The authentication failed.
        public static let authenticationFailed = Self(value: .authenticationFailed)
        /// A temporary failure occurred.
        public static let temporaryFailure = Self(value: .temporaryFailure)
        /// A permanent failure occurred.
        public static let permanentFailure = Self(value: .permanentFailure)
        /// The credentials already exists.
        public static let credentialsAlreadyExists = Self(value: .credentialsAlreadyExists)
        /// The credentials are deleted.
        public static let credentialsDeleted = Self(value: .credentialsDeleted)
        /// The credentials session was expired.
        public static let credentialsSessionExpired = Self(value: .credentialsSessionExpired)
        /// The task was cancelled.
        public static let cancelled = Self(value: .cancelled)

        public static func ~=(lhs: Self, rhs: Swift.Error) -> Bool {
            lhs == (rhs as? AddCredentialsTask.Error)?.code
        }
    }

    public let code: Code
    public let message: String?

    init(code: Code, message: String? = nil) {
        self.code = code
        self.message = message
    }

    public var description: String {
        return "CredentialsTaskError.\(code.value)"
    }

    /// The authentication failed.
    ///
    /// The payload from the backend can be found in the message property.
    public static let authenticationFailed: Code = .authenticationFailed
    /// A temporary failure occurred.
    ///
    /// The payload from the backend can be found in the message property.
    public static let temporaryFailure: Code = .temporaryFailure
    /// A permanent failure occurred.
    ///
    /// The payload from the backend can be found in the message property.
    public static let permanentFailure: Code = .permanentFailure
    /// The credentials already exists.
    ///
    /// The payload from the backend can be found in the message property.
    public static let credentialsAlreadyExists: Code = .credentialsAlreadyExists
    /// The credentials are deleted.
    ///
    /// The payload from the backend can be found in the message property.
    public static let credentialsDeleted: Code = .credentialsDeleted
    /// The credentials session was expired.
    ///
    /// The payload from the backend can be found in the message property.
    public static let credentialsSessionExpired: Code = .credentialsSessionExpired
    /// The task was cancelled.
    public static let cancelled: Code = .cancelled

    static func authenticationFailed(_ message: String?) -> Self {
        .init(code: .authenticationFailed, message: message)
    }

    static func temporaryFailure(_ message: String?) -> Self {
        .init(code: .temporaryFailure, message: message)
    }

    static func permanentFailure(_ message: String?) -> Self {
        .init(code: .permanentFailure, message: message)
    }

    static func credentialsAlreadyExists(_ message: String?) -> Self {
        .init(code: .credentialsAlreadyExists, message: message)
    }

    static func credentialsDeleted(_ message: String?) -> Self {
        .init(code: .credentialsDeleted, message: message)
    }

    static func credentialsSessionExpired(_ message: String?) -> Self {
        .init(code: .credentialsSessionExpired, message: message)
    }

    init?(addCredentialsError error: Swift.Error) {
        switch error {
        case ServiceError.alreadyExists(let payload):
            self = .credentialsAlreadyExists(payload)
        default:
            return nil
        }
    }
}

