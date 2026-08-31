import AppLocalization
import BabyLoadingInfrastructure
import Foundation
import Observation
import PregnancyProgress

public enum SettingsLoadingState: Equatable, Sendable {
    case idle
    case loaded
    case failed
}

public enum SettingsSaveState: Equatable, Sendable {
    case idle
    case saving
    case saved
    case invalidFutureLastPeriodDate
    case failed
}

public enum SettingsViewModelOutput: Equatable, Sendable {
    case lastPeriodDateUpdated(Date)
}

public typealias SettingsViewModelOutputHandler = @MainActor @Sendable (SettingsViewModelOutput) async -> Void

@MainActor
@Observable
public final class SettingsViewModel {
    public private(set) var lastPeriodDate: Date
    public private(set) var dueDate: Date?
    public private(set) var appLanguage: AppLanguage
    public private(set) var appVersion: String
    public private(set) var loadingState: SettingsLoadingState = .idle
    public private(set) var saveState: SettingsSaveState = .idle
    public private(set) var hasStoredFutureLastPeriodDate = false

    @ObservationIgnored private let loadPregnancyProgressUseCase: any LoadPregnancyProgressUseCaseProtocol
    @ObservationIgnored private let updateLastPeriodDateUseCase: any UpdateLastPeriodDateUseCaseProtocol
    @ObservationIgnored private let calculateDueDateUseCase: any CalculateDueDateUseCaseProtocol
    @ObservationIgnored private let resolveAppLanguageUseCase: any ResolveAppLanguageUseCaseProtocol
    @ObservationIgnored private let loadAppVersionUseCase: any LoadAppVersionUseCaseProtocol
    @ObservationIgnored private let outputHandler: SettingsViewModelOutputHandler

    public init(
        loadPregnancyProgressUseCase: any LoadPregnancyProgressUseCaseProtocol,
        updateLastPeriodDateUseCase: any UpdateLastPeriodDateUseCaseProtocol,
        calculateDueDateUseCase: any CalculateDueDateUseCaseProtocol,
        resolveAppLanguageUseCase: any ResolveAppLanguageUseCaseProtocol,
        loadAppVersionUseCase: any LoadAppVersionUseCaseProtocol,
        initialLanguage: AppLanguage,
        outputHandler: @escaping SettingsViewModelOutputHandler
    ) {
        self.loadPregnancyProgressUseCase = loadPregnancyProgressUseCase
        self.updateLastPeriodDateUseCase = updateLastPeriodDateUseCase
        self.calculateDueDateUseCase = calculateDueDateUseCase
        self.resolveAppLanguageUseCase = resolveAppLanguageUseCase
        self.loadAppVersionUseCase = loadAppVersionUseCase
        self.outputHandler = outputHandler
        lastPeriodDate = .now
        appLanguage = initialLanguage
        appVersion = loadAppVersionUseCase.execute()
    }

    public func reload(
        asOf date: Date = .now,
        preferredLanguages: [String]
    ) async {
        let resolvedLanguage = resolveAppLanguageUseCase.execute(preferredLanguages: preferredLanguages)

        do {
            let progress = try await loadPregnancyProgressUseCase.execute(asOf: date)
            switch progress {
            case nil:
                dueDate = nil
                hasStoredFutureLastPeriodDate = false
            case let .active(activeProgress):
                lastPeriodDate = activeProgress.lastPeriodDate
                dueDate = activeProgress.dueDate
                hasStoredFutureLastPeriodDate = false
            case .invalidFutureLastPeriodDate:
                lastPeriodDate = date
                dueDate = nil
                hasStoredFutureLastPeriodDate = true
            }
            appLanguage = resolvedLanguage
            appVersion = loadAppVersionUseCase.execute()
            loadingState = .loaded
        } catch {
            appLanguage = resolvedLanguage
            loadingState = .failed
        }
    }

    public func updateLastPeriodDate() async {
        saveState = .saving
        let selectedDate = lastPeriodDate

        do {
            try await updateLastPeriodDateUseCase.execute(selectedDate, asOf: .now)
            await outputHandler(.lastPeriodDateUpdated(selectedDate))
            saveState = .saved
            hasStoredFutureLastPeriodDate = false
        } catch PregnancyProgressValidationError.futureLastPeriodDate {
            saveState = .invalidFutureLastPeriodDate
        } catch {
            saveState = .failed
        }
    }

    public func selectLastPeriodDate(_ date: Date) {
        lastPeriodDate = date
        dueDate = calculateDueDateUseCase.execute(lastPeriodDate: date)
        hasStoredFutureLastPeriodDate = false
        if saveState != .saving {
            saveState = .idle
        }
    }

    public func clearSaveFailure() {
        guard saveState == .failed else { return }
        saveState = .idle
    }
}
