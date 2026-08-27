import Foundation

public actor PregnancyContentRepository: PregnancyContentRepositoryProtocol {
    private let expectedLocale: String
    private let bundleSource: any PregnancyContentSourceProtocol
    private let legacyCacheSource: any PregnancyContentSourceProtocol

    private var resolvedSnapshot: PregnancyContentDocument?

    public init(
        expectedLocale: String,
        bundleSource: any PregnancyContentSourceProtocol,
        legacyCacheSource: any PregnancyContentSourceProtocol
    ) {
        self.expectedLocale = expectedLocale
        self.bundleSource = bundleSource
        self.legacyCacheSource = legacyCacheSource
    }

    public func currentSnapshot() async -> PregnancyContentDocument {
        await resolveSnapshot()
    }

    public func weekContent(for week: Int) async -> WeekContent? {
        guard PregnancyContentDocument.coveredWeeks.contains(week) else {
            return nil
        }

        return await resolveSnapshot().weeks.first { $0.week == week }
    }

    public func allWeekContent() async -> [WeekContent] {
        await resolveSnapshot().weeks
    }

    private func resolveSnapshot() async -> PregnancyContentDocument {
        if let resolvedSnapshot {
            return resolvedSnapshot
        }

        if let bundledDocument = await loadDocument(from: bundleSource) {
            resolvedSnapshot = bundledDocument
            return bundledDocument
        }

        if let legacyDocument = await loadDocument(from: legacyCacheSource) {
            resolvedSnapshot = legacyDocument
            return legacyDocument
        }

        let emptyDocument = PregnancyContentDocument.empty(locale: expectedLocale)
        resolvedSnapshot = emptyDocument
        return emptyDocument
    }

    private func loadDocument(
        from source: any PregnancyContentSourceProtocol
    ) async -> PregnancyContentDocument? {
        do {
            return try await source.loadDocument()
        } catch {
            return nil
        }
    }
}

public protocol LoadPregnancyWeekContentUseCaseProtocol: Sendable {
    func execute(week: Int) async -> WeekContent?
}

public struct LoadPregnancyWeekContentUseCase: LoadPregnancyWeekContentUseCaseProtocol, Sendable {
    private let repository: any PregnancyContentRepositoryProtocol

    public init(repository: any PregnancyContentRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(week: Int) async -> WeekContent? {
        await repository.weekContent(for: week)
    }
}

public protocol LoadPregnancyTimelineUseCaseProtocol: Sendable {
    func execute() async -> [WeekContent]
}

public struct LoadPregnancyTimelineUseCase: LoadPregnancyTimelineUseCaseProtocol, Sendable {
    private let repository: any PregnancyContentRepositoryProtocol

    public init(repository: any PregnancyContentRepositoryProtocol) {
        self.repository = repository
    }

    public func execute() async -> [WeekContent] {
        await repository.allWeekContent()
    }
}
