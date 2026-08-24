import Foundation

public actor BellyTrackingRepository: BellyTrackingRepositoryProtocol {
    private let store: any BellyTrackingStoreProtocol

    public init(store: any BellyTrackingStoreProtocol) {
        self.store = store
    }

    public func loadTimeline() async throws -> [BellyTrackingEntry] {
        try await store.loadTimeline()
    }

    public func loadImageData(imageFileName: String) async throws -> Data? {
        try await store.loadImageData(imageFileName: imageFileName)
    }

    public func capturePhoto(
        data: Data,
        capturedAt: Date,
        pregnancyWeekAtCapture: Int?
    ) async throws -> BellyTrackingEntry {
        try await store.capturePhoto(
            data: data,
            capturedAt: capturedAt,
            pregnancyWeekAtCapture: pregnancyWeekAtCapture
        )
    }

    public func deleteEntry(id: UUID) async throws {
        try await store.deleteEntry(id: id)
    }

    public func loadSettings() async throws -> BellyTrackingSettings {
        try await store.loadSettings()
    }

    public func updateSettings(_ settings: BellyTrackingSettings) async throws {
        try await store.updateSettings(settings)
    }
}

public protocol LoadBellyTrackingTimelineUseCaseProtocol: Sendable {
    func execute() async throws -> [BellyTrackingEntry]
}

public struct LoadBellyTrackingTimelineUseCase: LoadBellyTrackingTimelineUseCaseProtocol, Sendable {
    private let repository: any BellyTrackingRepositoryProtocol

    public init(repository: any BellyTrackingRepositoryProtocol) {
        self.repository = repository
    }

    public func execute() async throws -> [BellyTrackingEntry] {
        try await repository.loadTimeline()
    }
}

public protocol LoadBellyTrackingImageUseCaseProtocol: Sendable {
    func execute(imageFileName: String) async throws -> Data?
}

public struct LoadBellyTrackingImageUseCase: LoadBellyTrackingImageUseCaseProtocol, Sendable {
    private let repository: any BellyTrackingRepositoryProtocol

    public init(repository: any BellyTrackingRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(imageFileName: String) async throws -> Data? {
        try await repository.loadImageData(imageFileName: imageFileName)
    }
}

public protocol CaptureBellyTrackingPhotoUseCaseProtocol: Sendable {
    func execute(
        data: Data,
        capturedAt: Date,
        pregnancyWeekAtCapture: Int?
    ) async throws -> BellyTrackingEntry
}

public struct CaptureBellyTrackingPhotoUseCase: CaptureBellyTrackingPhotoUseCaseProtocol, Sendable {
    private let repository: any BellyTrackingRepositoryProtocol

    public init(repository: any BellyTrackingRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(
        data: Data,
        capturedAt: Date,
        pregnancyWeekAtCapture: Int?
    ) async throws -> BellyTrackingEntry {
        try await repository.capturePhoto(
            data: data,
            capturedAt: capturedAt,
            pregnancyWeekAtCapture: pregnancyWeekAtCapture
        )
    }
}

public protocol DeleteBellyTrackingEntryUseCaseProtocol: Sendable {
    func execute(id: UUID) async throws
}

public struct DeleteBellyTrackingEntryUseCase: DeleteBellyTrackingEntryUseCaseProtocol, Sendable {
    private let repository: any BellyTrackingRepositoryProtocol

    public init(repository: any BellyTrackingRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(id: UUID) async throws {
        try await repository.deleteEntry(id: id)
    }
}

public protocol LoadBellyTrackingSettingsUseCaseProtocol: Sendable {
    func execute() async throws -> BellyTrackingSettings
}

public struct LoadBellyTrackingSettingsUseCase: LoadBellyTrackingSettingsUseCaseProtocol, Sendable {
    private let repository: any BellyTrackingRepositoryProtocol

    public init(repository: any BellyTrackingRepositoryProtocol) {
        self.repository = repository
    }

    public func execute() async throws -> BellyTrackingSettings {
        try await repository.loadSettings()
    }
}

public protocol UpdateBellyTrackingSettingsUseCaseProtocol: Sendable {
    func execute(_ settings: BellyTrackingSettings) async throws
}

public struct UpdateBellyTrackingSettingsUseCase: UpdateBellyTrackingSettingsUseCaseProtocol, Sendable {
    private let repository: any BellyTrackingRepositoryProtocol

    public init(repository: any BellyTrackingRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(_ settings: BellyTrackingSettings) async throws {
        try await repository.updateSettings(settings)
    }
}

public protocol ResolveBellyTrackingStatusUseCaseProtocol: Sendable {
    func execute(
        settings: BellyTrackingSettings,
        lastCapture: Date?,
        asOf date: Date
    ) -> BellyTrackingStatus
}

public struct ResolveBellyTrackingStatusUseCase: ResolveBellyTrackingStatusUseCaseProtocol, Sendable {
    private let calendar: Calendar

    public init(calendar: Calendar) {
        self.calendar = calendar
    }

    public func execute(
        settings: BellyTrackingSettings,
        lastCapture: Date?,
        asOf date: Date
    ) -> BellyTrackingStatus {
        settings.trackingStatus(
            lastCapture: lastCapture,
            asOf: date,
            calendar: calendar
        )
    }
}
