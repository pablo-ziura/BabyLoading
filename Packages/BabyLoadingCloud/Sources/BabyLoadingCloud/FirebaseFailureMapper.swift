import CloudBackup
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Foundation

enum FirebaseFailureMapper {
    static func map(_ error: Error) -> BackupFailure {
        if let failure = error as? BackupFailure { return failure }
        if error is CancellationError { return .cancelled }
        let value = error as NSError
        switch value.domain {
        case AuthErrorDomain: return authenticationFailure(value.code)
        case FirestoreErrorDomain: return firestoreFailure(value.code)
        case StorageErrorDomain: return storageFailure(value.code)
        case NSURLErrorDomain: return .network
        default: return .unavailable
        }
    }

    private static func authenticationFailure(_ code: Int) -> BackupFailure {
        switch AuthErrorCode(rawValue: code) {
        case .networkError: return .network
        case .emailAlreadyInUse, .credentialAlreadyInUse, .accountExistsWithDifferentCredential:
            return .emailAlreadyInUse
        case .weakPassword: return .weakPassword
        case .requiresRecentLogin: return .recentLoginRequired
        case .tooManyRequests, .quotaExceeded: return .quotaExceeded
        case .operationNotAllowed: return .unavailable
        default: return .credentials
        }
    }

    private static func firestoreFailure(_ code: Int) -> BackupFailure {
        switch FirestoreErrorCode.Code(rawValue: code) {
        case .unavailable, .deadlineExceeded, .aborted: return .network
        case .permissionDenied, .unauthenticated: return .permissionDenied
        case .resourceExhausted: return .quotaExceeded
        case .cancelled: return .cancelled
        default: return .invalidData
        }
    }

    private static func storageFailure(_ code: Int) -> BackupFailure {
        switch StorageErrorCode(rawValue: code) {
        case .retryLimitExceeded, .unknown: return .network
        case .unauthorized, .unauthenticated: return .permissionDenied
        case .quotaExceeded: return .quotaExceeded
        case .objectNotFound: return .missingImage
        case .cancelled: return .cancelled
        default: return .storage
        }
    }
}
