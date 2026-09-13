import Foundation

@MainActor
public struct RegisterBackupAccountUseCase {
    private let operations: any BackupAccountOperationsProtocol
    public init(operations: any BackupAccountOperationsProtocol) { self.operations = operations }
    public func execute(email: String, password: String) async throws {
        try await operations.register(email: email, password: password)
    }
}

@MainActor
public struct SignInBackupAccountUseCase {
    private let operations: any BackupAccountOperationsProtocol
    public init(operations: any BackupAccountOperationsProtocol) { self.operations = operations }
    public func execute(email: String, password: String) async throws {
        try await operations.signIn(email: email, password: password)
    }
}

@MainActor
public struct SignInGoogleBackupUseCase {
    private let operations: any BackupAccountOperationsProtocol
    public init(operations: any BackupAccountOperationsProtocol) { self.operations = operations }
    public func execute() async throws { try await operations.signInGoogle() }
}

@MainActor
public struct ResetBackupPasswordUseCase {
    private let operations: any BackupAccountOperationsProtocol
    public init(operations: any BackupAccountOperationsProtocol) { self.operations = operations }
    public func execute(email: String) async throws { try await operations.resetPassword(email: email) }
}

@MainActor
public struct VerifyBackupEmailUseCase {
    private let operations: any BackupAccountOperationsProtocol
    public init(operations: any BackupAccountOperationsProtocol) { self.operations = operations }
    public func execute() async throws { try await operations.sendVerification() }
}

@MainActor
public struct SignOutBackupAccountUseCase {
    private let operations: any BackupAccountOperationsProtocol
    public init(operations: any BackupAccountOperationsProtocol) { self.operations = operations }
    public func execute() async throws { try await operations.signOut() }
}

@MainActor
public struct DeleteBackupAccountUseCase {
    private let operations: any BackupAccountOperationsProtocol
    public init(operations: any BackupAccountOperationsProtocol) { self.operations = operations }
    public func execute(password: String) async throws { try await operations.deleteAccount(password: password) }
}

@MainActor
public struct ImportGuestBackupUseCase {
    private let operations: any BackupAccountOperationsProtocol
    public init(operations: any BackupAccountOperationsProtocol) { self.operations = operations }
    public func execute() async throws { try await operations.importGuest() }
}

@MainActor
public struct RetryBackupUseCase {
    private let operations: any BackupAccountOperationsProtocol
    public init(operations: any BackupAccountOperationsProtocol) { self.operations = operations }
    public func execute() async throws { try await operations.retry() }
}

@MainActor
public struct ObserveBackupStateUseCase {
    private let operations: any BackupAccountOperationsProtocol
    public init(operations: any BackupAccountOperationsProtocol) { self.operations = operations }
    public func execute() -> AsyncStream<BackupState> { operations.observeState() }
}

@MainActor
public struct BackupAccountUseCases {
    public let register: RegisterBackupAccountUseCase
    public let signIn: SignInBackupAccountUseCase
    public let signInGoogle: SignInGoogleBackupUseCase
    public let resetPassword: ResetBackupPasswordUseCase
    public let sendVerification: VerifyBackupEmailUseCase
    public let signOut: SignOutBackupAccountUseCase
    public let deleteAccount: DeleteBackupAccountUseCase
    public let importGuest: ImportGuestBackupUseCase
    public let retry: RetryBackupUseCase
    public let observeState: ObserveBackupStateUseCase

    public init(operations: any BackupAccountOperationsProtocol) {
        register = RegisterBackupAccountUseCase(operations: operations)
        signIn = SignInBackupAccountUseCase(operations: operations)
        signInGoogle = SignInGoogleBackupUseCase(operations: operations)
        resetPassword = ResetBackupPasswordUseCase(operations: operations)
        sendVerification = VerifyBackupEmailUseCase(operations: operations)
        signOut = SignOutBackupAccountUseCase(operations: operations)
        deleteAccount = DeleteBackupAccountUseCase(operations: operations)
        importGuest = ImportGuestBackupUseCase(operations: operations)
        retry = RetryBackupUseCase(operations: operations)
        observeState = ObserveBackupStateUseCase(operations: operations)
    }
}
