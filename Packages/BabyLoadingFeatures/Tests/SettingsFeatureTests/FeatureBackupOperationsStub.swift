import CloudBackup
import Foundation

@MainActor
final class FeatureBackupOperationsStub: BackupAccountOperationsProtocol {
    func register(email: String, password: String) {}
    func signIn(email: String, password: String) {}
    func signInGoogle() {}
    func resetPassword(email: String) {}
    func sendVerification() {}
    func signOut() {}
    func deleteAccount(password: String) {}
    func importGuest() {}
    func retry() {}
    func observeState() -> AsyncStream<BackupState> { AsyncStream { $0.finish() } }
}
