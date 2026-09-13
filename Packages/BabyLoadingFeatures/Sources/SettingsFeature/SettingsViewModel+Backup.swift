import CloudBackup
import Foundation

extension SettingsViewModel {
    public func registerBackup(email: String, password: String) {
        performBackup { try await self.backupUseCases.register.execute(email: email, password: password) }
    }

    public func signInBackup(email: String, password: String) {
        performBackup { try await self.backupUseCases.signIn.execute(email: email, password: password) }
    }

    public func signInGoogleBackup() {
        performBackup { try await self.backupUseCases.signInGoogle.execute() }
    }

    public func resetBackupPassword(email: String) {
        performBackup {
            try await self.backupUseCases.resetPassword.execute(email: email)
            self.backupMessageKey = "backup.passwordResetSent"
        }
    }

    public func verifyBackupEmail() {
        performBackup {
            try await self.backupUseCases.sendVerification.execute()
            self.backupMessageKey = "backup.verificationSent"
        }
    }

    public func signOutBackup() { performBackup { try await self.backupUseCases.signOut.execute() } }
    public func deleteBackupAccount(password: String) {
        performBackup { try await self.backupUseCases.deleteAccount.execute(password: password) }
    }
    public func importGuestBackup() { performBackup { try await self.backupUseCases.importGuest.execute() } }
    public func retryBackup() { performBackup { try await self.backupUseCases.retry.execute() } }

    private func performBackup(_ operation: @escaping @MainActor () async throws -> Void) {
        guard backupTask == nil, !backupState.isWorking else { return }
        isPerformingBackupAction = true
        backupFailure = nil
        backupMessageKey = nil
        backupTask = Task { [weak self] in
            guard let self else { return }
            defer { self.backupTask = nil; self.isPerformingBackupAction = false }
            do { try await operation() } catch {
                let failure = (error as? BackupFailure) ?? .unavailable
                if failure != .cancelled { self.backupFailure = failure }
            }
        }
    }
}
