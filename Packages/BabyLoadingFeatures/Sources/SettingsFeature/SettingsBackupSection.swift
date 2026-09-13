import BabyLoadingDesignComponents
import BabyLoadingDesignTokens
import SwiftUI

struct SettingsBackupSection: View {
    @Environment(SettingsViewModel.self) private var viewModel
    @State private var email = ""
    @State private var password = ""
    @State private var deletionPassword = ""
    @State private var confirmsDeletion = false
    @State private var confirmsSignOut = false

    var body: some View {
        VStack(alignment: .leading, spacing: BabyLoadingSpacing.medium) {
            Label("backup.title", systemImage: "icloud")
                .font(BabyLoadingTypography.text(.title3, weight: .bold))
                .accessibilityAddTraits(.isHeader)
                .accessibilityHeading(.h2)

            if viewModel.backupState.isGuest {
                guestControls
            } else {
                accountControls
            }

            if viewModel.backupState.isWorking || viewModel.isPerformingBackupAction {
                ProgressView("backup.working")
                    .font(BabyLoadingTypography.text(.body))
            }
            if let key = viewModel.backupMessageKey {
                Text(LocalizedStringKey(key))
                    .font(BabyLoadingTypography.text(.body))
                    .foregroundStyle(.secondary)
            }
            if let failure = viewModel.backupFailure ?? viewModel.backupState.failure {
                Text(LocalizedStringKey("backup.error.\(failure.rawValue)"))
                    .font(BabyLoadingTypography.text(.body))
                    .fixedSize(horizontal: false, vertical: true)
                Button("backup.retry", action: viewModel.retryBackup)
                    .font(BabyLoadingTypography.text(.headline, weight: .semibold))
                    .frame(minHeight: 44)
            }
        }
        .disabled(viewModel.backupState.isWorking || viewModel.isPerformingBackupAction)
        .softCard()
        .padding(.horizontal)
        .alert("backup.delete.title", isPresented: $confirmsDeletion) {
            if viewModel.backupState.account?.providers.contains("password") == true {
                SecureField("backup.password", text: $deletionPassword)
            }
            Button("backup.delete.confirm", role: .destructive) {
                viewModel.deleteBackupAccount(password: deletionPassword)
                deletionPassword = ""
            }
            Button("common.cancel", role: .cancel) { deletionPassword = "" }
        } message: {
            Text("backup.delete.message")
        }
        .confirmationDialog("backup.signOut.message", isPresented: $confirmsSignOut, titleVisibility: .visible) {
            Button("backup.signOut", role: .destructive, action: viewModel.signOutBackup)
            Button("common.cancel", role: .cancel) {}
        }
    }

    private var guestControls: some View {
        VStack(alignment: .leading, spacing: BabyLoadingSpacing.small) {
            Text("backup.guest.message")
                .font(BabyLoadingTypography.text(.body))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            emailField
            SecureField("backup.password", text: $password)
                .textFieldStyle(.roundedBorder)
                .font(BabyLoadingTypography.text(.body))
                .frame(minHeight: 44)
            Button("backup.register") {
                viewModel.registerBackup(
                    email: email.trimmingCharacters(in: .whitespacesAndNewlines), password: password
                )
                password = ""
            }
            .disabled(email.isEmpty || password.isEmpty)
            Button("backup.signIn") {
                viewModel.signInBackup(email: email.trimmingCharacters(in: .whitespacesAndNewlines), password: password)
                password = ""
            }
            .disabled(email.isEmpty || password.isEmpty)
            Button("backup.resetPassword") { viewModel.resetBackupPassword(email: email) }
                .disabled(email.isEmpty)
            Divider().padding(.vertical, BabyLoadingSpacing.small)
            Button("backup.google", action: viewModel.signInGoogleBackup)
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.bordered)
        .font(BabyLoadingTypography.text(.headline, weight: .semibold))
    }

    private var emailField: some View {
        TextField("backup.email", text: $email)
            .textFieldStyle(.roundedBorder)
            .font(BabyLoadingTypography.text(.body))
            .frame(minHeight: 44)
            #if os(iOS)
            .keyboardType(.emailAddress)
            .textContentType(.username)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            #endif
    }

    private var accountControls: some View {
        VStack(alignment: .leading, spacing: BabyLoadingSpacing.small) {
            if let email = viewModel.backupState.account?.email {
                Text(email)
                    .font(BabyLoadingTypography.text(.body))
                    .textSelection(.enabled)
            }
            ForEach(viewModel.backupState.account?.providers ?? [], id: \.self) { provider in
                Text(LocalizedStringKey(provider == "google.com" ? "backup.provider.google" : "backup.provider.email"))
                    .font(BabyLoadingTypography.text(.caption))
                    .foregroundStyle(.secondary)
            }
            Text("backup.account.message")
                .font(BabyLoadingTypography.text(.body))
                .foregroundStyle(.secondary)
            if viewModel.backupState.hasGuestData {
                Text("backup.import.message")
                    .font(BabyLoadingTypography.text(.body))
                Button("backup.import", action: viewModel.importGuestBackup)
            }
            if viewModel.backupState.account?.isEmailVerified == false,
               viewModel.backupState.account?.providers.contains("password") == true {
                Button("backup.verifyEmail", action: viewModel.verifyBackupEmail)
            }
            Button("backup.signOut") { confirmsSignOut = true }
            Button("backup.delete.title", role: .destructive) { confirmsDeletion = true }
        }
        .buttonStyle(.bordered)
        .font(BabyLoadingTypography.text(.headline, weight: .semibold))
    }
}
