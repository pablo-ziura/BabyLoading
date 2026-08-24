import AppPreferences
import Foundation

public actor PregnancyProgressStore: PregnancyProgressStoreProtocol {
    static let lastPeriodDateKey = PreferenceKey<Date>("lastPeriodDate")

    private let preferencesStore: any PreferencesStoreProtocol

    public init(preferencesStore: any PreferencesStoreProtocol) {
        self.preferencesStore = preferencesStore
    }

    public func loadLastPeriodDate() async throws -> Date? {
        try await preferencesStore.read(Self.lastPeriodDateKey)
    }

    public func updateLastPeriodDate(_ date: Date?) async throws {
        if let date {
            try await preferencesStore.write(date, for: Self.lastPeriodDateKey)
        } else {
            await preferencesStore.remove(Self.lastPeriodDateKey)
        }
    }
}
