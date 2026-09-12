import Foundation

public actor BackupSynchronizationDriver {
    private let localStore: BackupLocalStore
    private let remoteStore: any BackupRemoteStoreProtocol
    private let connectivity: any BackupConnectivityProtocol
    private let images: ImageUploadService
    private let synchronize: SynchronizeBackupUseCase
    private var session = UUID()
    private var isConnected = false
    private var retryAttempt = 0
    private var worker: Task<Void, Never>?
    private var localObservation: Task<Void, Never>?
    private var remoteObservation: Task<Void, Never>?
    private var networkObservation: Task<Void, Never>?
    private var retryTask: Task<Void, Never>?
    private var workContinuation: AsyncStream<Void>.Continuation?
    private var observers: [UUID: AsyncStream<BackupFailure?>.Continuation] = [:]

    public init(
        localStore: BackupLocalStore,
        remoteStore: any BackupRemoteStoreProtocol,
        connectivity: any BackupConnectivityProtocol,
        images: ImageUploadService,
        synchronize: SynchronizeBackupUseCase
    ) {
        self.localStore = localStore
        self.remoteStore = remoteStore
        self.connectivity = connectivity
        self.images = images
        self.synchronize = synchronize
    }

    public func failures() -> AsyncStream<BackupFailure?> {
        let identifier = UUID()
        return AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            observers[identifier] = continuation
            continuation.onTermination = { [weak self] _ in
                Task { await self?.removeObserver(identifier) }
            }
        }
    }

    private func removeObserver(_ identifier: UUID) { observers[identifier] = nil }

    public func start(account: BackupAccount) async {
        await stop()
        guard !account.isAnonymous else { return }
        let currentSession = session
        let signals = AsyncStream<Void>.makeStream(bufferingPolicy: .bufferingNewest(1))
        workContinuation = signals.continuation
        worker = Task {
            for await _ in signals.stream {
                guard !Task.isCancelled else { return }
                await runPass(account: account, expectedSession: currentSession)
            }
        }
        localObservation = Task {
            for await _ in await localStore.changes() {
                guard !Task.isCancelled else { return }
                signals.continuation.yield(())
            }
        }
        networkObservation = Task {
            for await connected in connectivity.changes() {
                guard !Task.isCancelled else { return }
                await connectionChanged(connected, expectedSession: currentSession)
            }
        }
        remoteObservation = Task { await observeRemote(account: account, expectedSession: currentSession) }
    }

    public func stop() async {
        session = UUID()
        worker?.cancel()
        localObservation?.cancel()
        remoteObservation?.cancel()
        networkObservation?.cancel()
        retryTask?.cancel()
        workContinuation?.finish()
        worker = nil
        localObservation = nil
        remoteObservation = nil
        networkObservation = nil
        retryTask = nil
        workContinuation = nil
        retryAttempt = 0
        isConnected = false
        await images.cancel()
    }

    private func connectionChanged(_ connected: Bool, expectedSession: UUID) async {
        guard expectedSession == session else { return }
        isConnected = connected
        if connected {
            retryTask?.cancel()
            retryTask = nil
            workContinuation?.yield(())
        } else {
            await images.cancel()
        }
    }

    private func runPass(account: BackupAccount, expectedSession: UUID) async {
        guard session == expectedSession, isConnected, retryTask == nil else { return }
        do {
            try await images.execute(account: account)
            guard session == expectedSession, !Task.isCancelled else { return }
            retryAttempt = 0
            report(nil)
        } catch {
            guard session == expectedSession, !Task.isCancelled else { return }
            let failure = (error as? BackupFailure) ?? .storage
            guard failure != .cancelled, failure != .sessionChanged else { return }
            report(failure)
            if failure.isTransient {
                retryAttempt += 1
                let delay = Self.retryDelay(attempt: retryAttempt, jitter: Double.random(in: 0.75...1.25))
                retryTask = Task {
                    do { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) } catch { return }
                    retryReady(expectedSession: expectedSession)
                }
            }
        }
    }

    private func retryReady(expectedSession: UUID) {
        guard session == expectedSession else { return }
        retryTask = nil
        workContinuation?.yield(())
    }

    private func observeRemote(account: BackupAccount, expectedSession: UUID) async {
        var attempt = 0
        while session == expectedSession, !Task.isCancelled {
            do {
                for try await event in try await remoteStore.observe(userID: account.id) {
                    guard session == expectedSession, !Task.isCancelled else { return }
                    try await synchronize.merge(event, userID: account.id)
                    attempt = 0
                }
                return
            } catch {
                guard session == expectedSession, !Task.isCancelled else { return }
                let failure = (error as? BackupFailure) ?? .invalidData
                report(failure)
                guard failure.isTransient else { return }
                attempt += 1
                let delay = Self.retryDelay(attempt: attempt, jitter: Double.random(in: 0.75...1.25))
                do { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) } catch { return }
            }
        }
    }

    private func report(_ failure: BackupFailure?) {
        for observer in observers.values { observer.yield(failure) }
    }

    public static func retryDelay(attempt: Int, jitter: Double) -> TimeInterval {
        min(300, pow(2, Double(max(0, min(attempt, 9)))) * min(1.25, max(0.75, jitter)))
    }
}
