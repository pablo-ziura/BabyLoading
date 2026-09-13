import Foundation
import PregnancyProgress

@MainActor
public final class BackupRuntime: BackupAccountOperationsProtocol {
    public private(set) var state = BackupState()
    private let localStore: BackupLocalStore
    private let initializeLocal: InitializeBackupUseCase
    private let projectionStore: any PregnancyProgressStoreProtocol
    private let makeServices: @MainActor () throws -> BackupServices
    private let calendar: Calendar
    private var services: BackupServices?
    private var isActive = false
    private var accountGeneration = UUID()
    private var localObservation: Task<Void, Never>?
    private var accountObservation: Task<Void, Never>?
    private var failureObservation: Task<Void, Never>?
    private var anonymousSignIn: Task<Void, Never>?
    private var observers: [UUID: AsyncStream<BackupState>.Continuation] = [:]

    public init(
        localStore: BackupLocalStore,
        initializeLocal: InitializeBackupUseCase,
        projectionStore: any PregnancyProgressStoreProtocol,
        calendar: Calendar,
        makeServices: @escaping @MainActor () throws -> BackupServices
    ) {
        self.localStore = localStore
        self.initializeLocal = initializeLocal
        self.projectionStore = projectionStore
        self.calendar = calendar
        self.makeServices = makeServices
    }

    deinit {
        localObservation?.cancel()
        accountObservation?.cancel()
        failureObservation?.cancel()
        anonymousSignIn?.cancel()
    }

    public func initialize() async throws {
        do { try await initializeIfNeeded() } catch { report(error); throw error }
    }

    private func initializeIfNeeded() async throws {
        guard !state.isReady else { return }
        try await initializeLocal.execute()
        let services = try makeServices()
        self.services = services
        let snapshot = try await localStore.snapshot()
        if let userID = snapshot.confirmedAccountDeletion {
            try await localStore.finishAccountDeletion(userID: userID)
        }
        try await reconcileAccount()
        state.isReady = true
        publish()
        localObservation = Task { [weak self, localStore] in
            for await _ in await localStore.changes() {
                guard !Task.isCancelled, let self else { return }
                do { try await self.refreshState() } catch { self.report(error) }
            }
        }
        accountObservation = Task { [weak self, authentication = services.authentication] in
            for await account in authentication.observeAccounts() {
                guard !Task.isCancelled, let self else { return }
                guard !self.state.isWorking, account != self.state.account else { continue }
                self.state.isWorking = true
                self.publish()
                do {
                    try await self.pauseForAccountChange()
                    try await self.reconcileAccount()
                    await self.resumeSynchronization()
                } catch { self.report(error) }
                self.state.isWorking = false
                self.publish()
            }
        }
        failureObservation = Task { [weak self, driver = services.driver] in
            for await failure in await driver.failures() {
                guard !Task.isCancelled, let self else { return }
                self.state.failure = failure
                self.publish()
            }
        }
    }

    public func setActive(_ active: Bool) async {
        isActive = active
        guard let services else { return }
        if active {
            await resumeSynchronization()
            if services.authentication.currentAccount == nil, anonymousSignIn == nil {
                anonymousSignIn = Task { [weak self, authentication = services.authentication] in
                    defer { self?.anonymousSignIn = nil }
                    var attempt = 0
                    while self?.isActive == true, authentication.currentAccount == nil, !Task.isCancelled {
                        do {
                            try await authentication.signInAnonymously()
                            if self?.state.failure == .network { self?.state.failure = nil; self?.publish() }
                            return
                        } catch {
                            guard !Task.isCancelled else { return }
                            self?.report(error)
                            guard (error as? BackupFailure)?.isTransient == true else { return }
                            attempt += 1
                            let delay = BackupSynchronizationDriver.retryDelay(attempt: attempt, jitter: 1)
                            do { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) } catch { return }
                        }
                    }
                }
            }
        } else {
            anonymousSignIn?.cancel()
            await services.driver.stop()
        }
    }

    public func observeState() -> AsyncStream<BackupState> {
        let identifier = UUID()
        return AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            observers[identifier] = continuation
            continuation.yield(state)
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor [weak self] in self?.observers[identifier] = nil }
            }
        }
    }

    public func register(email: String, password: String) async throws {
        try await accountOperation { authentication in
            if authentication.currentAccount == nil { try await authentication.signInAnonymously() }
            guard let anonymousID = authentication.currentAccount?.id else { throw BackupFailure.credentials }
            try await self.localStore.beginGuestLink(userID: anonymousID)
            try await authentication.linkEmail(email: email, password: password)
        }
    }

    public func signIn(email: String, password: String) async throws {
        try await accountOperation { try await $0.signInEmail(email: email, password: password) }
    }

    public func signInGoogle() async throws {
        try await accountOperation { authentication in
            if authentication.currentAccount == nil { try await authentication.signInAnonymously() }
            if let anonymous = authentication.currentAccount, anonymous.isAnonymous {
                try await self.localStore.beginGuestLink(userID: anonymous.id)
            }
            try await authentication.signInGoogle(linkAnonymous: authentication.currentAccount?.isAnonymous == true)
        }
    }

    public func resetPassword(email: String) async throws {
        try await credentialOperation { try await $0.resetPassword(email: email) }
    }

    public func sendVerification() async throws {
        try await credentialOperation { try await $0.sendVerification() }
    }

    public func signOut() async throws {
        try await accountOperation { try $0.signOut() }
        await setActive(isActive)
    }

    public func deleteAccount(password: String) async throws {
        try await accountOperation { authentication in
            guard let account = authentication.currentAccount, !account.isAnonymous else {
                throw BackupFailure.credentials
            }
            try await self.localStore.beginAccountDeletion(userID: account.id)
            do {
                do { try await authentication.deleteAccount() } catch BackupFailure.recentLoginRequired {
                    try await authentication.reauthenticate(password: password)
                    try await authentication.deleteAccount()
                }
            } catch {
                try await self.localStore.cancelAccountDeletion()
                throw error
            }
            try await self.localStore.confirmAccountDeletion(userID: account.id)
            try await self.localStore.finishAccountDeletion(userID: account.id)
        }
        await setActive(isActive)
    }

    public func importGuest() async throws {
        guard !state.isWorking, let services, let account = state.account, !account.isAnonymous else {
            throw BackupFailure.sessionChanged
        }
        state.isWorking = true
        publish()
        defer { state.isWorking = false; publish() }
        await services.driver.stop()
        do {
            let synchronize = SynchronizeBackupUseCase(localStore: localStore, remoteStore: services.remoteStore)
            try await synchronize.refresh(account: account)
            try await localStore.importGuest(userID: account.id)
            try await refreshState()
            await resumeSynchronization()
        } catch {
            await resumeSynchronization()
            report(error)
            throw error
        }
    }

    public func retry() async throws {
        guard !state.isWorking else { throw BackupFailure.sessionChanged }
        if !state.isReady { try await initialize() }
        guard let services else { throw BackupFailure.unavailable }
        state.isWorking = true
        publish()
        defer { state.isWorking = false; publish() }
        do {
            await services.driver.stop()
            try await services.remoteStore.reset()
            try await localStore.retryFailures()
            state.failure = nil
            try await refreshState()
            await setActive(isActive)
        } catch { report(error); throw error }
    }

    private func accountOperation(_ operation: (any BackupAuthenticationProtocol) async throws -> Void) async throws {
        guard !state.isWorking, let services else { throw BackupFailure.unavailable }
        state.isWorking = true
        state.failure = nil
        publish()
        defer { state.isWorking = false; publish() }
        if let anonymousSignIn { anonymousSignIn.cancel(); await anonymousSignIn.value }
        let previous = services.authentication.currentAccount
        do {
            try await pauseForAccountChange()
            try await operation(services.authentication)
            let current = services.authentication.currentAccount
            let linkedGuest = previous?.isAnonymous == true && previous?.id == current?.id
                && current?.isAnonymous == false
            try await reconcileAccount(adoptGuest: linkedGuest)
            await resumeSynchronization()
        } catch {
            do { try await reconcileAccount() } catch { report(error); throw error }
            await resumeSynchronization()
            report(error)
            throw error
        }
    }

    private func credentialOperation(
        _ operation: (any BackupAuthenticationProtocol) async throws -> Void
    ) async throws {
        guard !state.isWorking, let services else { throw BackupFailure.unavailable }
        state.isWorking = true
        publish()
        defer { state.isWorking = false; publish() }
        if let anonymousSignIn { anonymousSignIn.cancel(); await anonymousSignIn.value }
        do { try await operation(services.authentication) } catch { report(error); throw error }
    }

    private func pauseForAccountChange() async throws {
        guard let services else { throw BackupFailure.unavailable }
        accountGeneration = UUID()
        await services.driver.stop()
        try await services.remoteStore.reset()
    }

    private func reconcileAccount(adoptGuest: Bool = false) async throws {
        guard let services else { throw BackupFailure.unavailable }
        let account = services.authentication.currentAccount
        let pendingLinkID = try await localStore.snapshot().pendingGuestLinkID
        let recoverLink = pendingLinkID != nil && pendingLinkID == account?.id && account?.isAnonymous == false
        try await localStore.activate(
            userID: account?.isAnonymous == false ? account?.id : nil, adoptGuest: adoptGuest || recoverLink
        )
        state.account = account
        try await refreshState()
    }

    public func refreshLocalState() async throws { try await refreshState() }

    private func refreshState() async throws {
        let generation = accountGeneration
        let account = services?.authentication.currentAccount
        let expectedProfile = account?.isAnonymous == false ? account?.id : "guest"
        let snapshot = try await localStore.snapshot()
        guard generation == accountGeneration, snapshot.profileID == expectedProfile else { return }
        let date = try snapshot.settings.lastPeriodDay.map { try PregnancyCalendarDay.decode($0, calendar: calendar) }
        let projected = try await projectionStore.loadLastPeriodDate()
        guard generation == accountGeneration else { return }
        if projected != date { try await projectionStore.updateLastPeriodDate(date) }
        guard generation == accountGeneration, account == services?.authentication.currentAccount else { return }
        state.account = account
        state.profileID = snapshot.profileID
        state.hasGuestData = snapshot.hasGuestData
        state.records = snapshot.records.sorted { $0.remote.id < $1.remote.id }
        state.lastPeriodDay = snapshot.settings.lastPeriodDay
        publish()
    }

    private func resumeSynchronization() async {
        guard isActive, let services, let account = services.authentication.currentAccount, !account.isAnonymous else {
            return
        }
        await services.driver.start(account: account)
    }

    private func report(_ error: Error) {
        let failure = (error as? BackupFailure) ?? .storage
        if failure != .cancelled { state.failure = failure }
        publish()
    }

    private func publish() {
        for observer in observers.values { observer.yield(state) }
    }
}
