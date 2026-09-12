import CloudBackup
import FirebaseAuth
import Foundation
import GoogleSignIn
#if canImport(UIKit)
    import UIKit

@MainActor
public final class AuthManager: BackupAuthenticationProtocol {
    private let authentication: Auth
    private let googleSignIn: GIDSignIn
    private let presenter: @MainActor () -> UIViewController?
    private var isPerformingOperation = false
    private var observers: [UUID: (AuthStateDidChangeListenerHandle, AsyncStream<BackupAccount?>.Continuation)] = [:]

    public init(
        clients: FirebaseServiceClients,
        googleSignIn: GIDSignIn,
        presenter: @escaping @MainActor () -> UIViewController?
    ) throws {
        authentication = clients.authentication
        self.googleSignIn = googleSignIn
        self.presenter = presenter
        guard let clientID = authentication.app?.options.clientID else { throw BackupFailure.unavailable }
        googleSignIn.configuration = GIDConfiguration(clientID: clientID)
    }

    public var currentAccount: BackupAccount? {
        guard let user = authentication.currentUser else { return nil }
        return BackupAccount(
            id: user.uid, email: user.email, isAnonymous: user.isAnonymous,
            providers: user.providerData.map(\.providerID), isEmailVerified: user.isEmailVerified
        )
    }

    public func observeAccounts() -> AsyncStream<BackupAccount?> {
        let id = UUID()
        return AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            let handle = authentication.addStateDidChangeListener { [weak self] _, _ in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.observers[id]?.1.yield(self.currentAccount)
                }
            }
            observers[id] = (handle, continuation)
            continuation.yield(currentAccount)
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor [weak self] in self?.removeObserver(id) }
            }
        }
    }

    private func removeObserver(_ id: UUID) {
        guard let observer = observers.removeValue(forKey: id) else { return }
        authentication.removeStateDidChangeListener(observer.0)
    }

    public func signInAnonymously() async throws {
        guard authentication.currentUser == nil else { return }
        try await perform { _ = try await self.authentication.signInAnonymously() }
    }

    public func linkEmail(email: String, password: String) async throws {
        guard let user = authentication.currentUser, user.isAnonymous else { throw BackupFailure.sessionChanged }
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        try await perform {
            do {
                try await self.link(user: user, credential: credential)
            } catch {
                guard FirebaseFailureMapper.map(error) == .emailAlreadyInUse else { throw error }
                _ = try await self.authentication.signIn(withEmail: email, password: password)
            }
        }
    }

    public func signInEmail(email: String, password: String) async throws {
        try await perform { _ = try await self.authentication.signIn(withEmail: email, password: password) }
    }

    public func signInGoogle(linkAnonymous: Bool) async throws {
        try await perform {
            let credential = try await self.googleCredential()
            if linkAnonymous, let user = self.authentication.currentUser, user.isAnonymous {
                do {
                    try await self.link(user: user, credential: credential)
                } catch {
                    let failure = error as NSError
                    guard failure.domain == AuthErrorDomain,
                          failure.code == AuthErrorCode.credentialAlreadyInUse.rawValue else { throw error }
                    _ = try await self.authentication.signIn(with: credential)
                }
            } else {
                _ = try await self.authentication.signIn(with: credential)
            }
        }
    }

    public func resetPassword(email: String) async throws {
        try await perform { try await self.authentication.sendPasswordReset(withEmail: email) }
    }

    public func sendVerification() async throws {
        guard let user = authentication.currentUser, !user.isAnonymous else { throw BackupFailure.credentials }
        try await perform {
            try await self.complete { user.sendEmailVerification(completion: $0) }
        }
    }

    public func reauthenticate(password: String) async throws {
        guard let user = authentication.currentUser else { throw BackupFailure.credentials }
        try await perform {
            let credential: AuthCredential
            if user.providerData.contains(where: { $0.providerID == "google.com" }) {
                credential = try await self.googleCredential()
            } else {
                guard let email = user.email, !password.isEmpty else { throw BackupFailure.recentLoginRequired }
                credential = EmailAuthProvider.credential(withEmail: email, password: password)
            }
            let expectedID = user.uid
            try await self.complete { completion in
                user.reauthenticate(with: credential) { result, error in
                    completion(error ?? (result?.user.uid == expectedID ? nil : BackupFailure.sessionChanged))
                }
            }
        }
    }

    public func signOut() throws {
        guard !isPerformingOperation else { throw BackupFailure.sessionChanged }
        do {
            try authentication.signOut()
            googleSignIn.signOut()
        } catch { throw FirebaseFailureMapper.map(error) }
    }

    public func deleteAccount() async throws {
        guard let user = authentication.currentUser else { throw BackupFailure.credentials }
        try await perform { try await self.complete { user.delete(completion: $0) } }
        googleSignIn.signOut()
    }

    private func link(user: User, credential: AuthCredential) async throws {
        let expectedID = user.uid
        try await complete { completion in
            user.link(with: credential) { result, error in
                completion(error ?? (result?.user.uid == expectedID ? nil : BackupFailure.sessionChanged))
            }
        }
        try await complete { completion in
            user.getIDTokenForcingRefresh(true) { _, error in completion(error) }
        }
    }

    private func complete(_ start: (@escaping @Sendable (Error?) -> Void) -> Void) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            start { error in
                if let error { continuation.resume(throwing: FirebaseFailureMapper.map(error)) }
                else { continuation.resume() }
            }
        }
    }

    private func googleCredential() async throws -> AuthCredential {
        guard let viewController = presenter() else { throw BackupFailure.unavailable }
        do {
            let result = try await googleSignIn.signIn(withPresenting: viewController)
            guard let idToken = result.user.idToken?.tokenString else { throw BackupFailure.credentials }
            return GoogleAuthProvider.credential(withIDToken: idToken, accessToken: result.user.accessToken.tokenString)
        } catch {
            if (error as NSError).domain == kGIDSignInErrorDomain,
               (error as NSError).code == GIDSignInError.canceled.rawValue {
                throw BackupFailure.cancelled
            }
            throw FirebaseFailureMapper.map(error)
        }
    }

    private func perform(_ operation: () async throws -> Void) async throws {
        guard !isPerformingOperation else { throw BackupFailure.sessionChanged }
        isPerformingOperation = true
        defer { isPerformingOperation = false }
        try Task.checkCancellation()
        do { try await operation() } catch { throw FirebaseFailureMapper.map(error) }
    }
}
#endif
