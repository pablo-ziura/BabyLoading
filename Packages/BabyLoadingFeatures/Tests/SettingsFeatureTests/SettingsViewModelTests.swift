import AppLocalization
import BabyLoadingInfrastructure
import Foundation
import PregnancyProgress
import SettingsFeature
import Testing

@MainActor
struct SettingsViewModelTests {
    @Test
    func updateDatePersistsAndEmitsTypedOutput() async {
        let updatedDate = Date(timeIntervalSince1970: 1_700_000_000)
        let updateUseCase = SettingsUpdateDateUseCaseRecorder()
        let outputRecorder = SettingsOutputRecorder()
        let viewModel = makeViewModel(
            updateUseCase: updateUseCase,
            outputHandler: { outputRecorder.record($0) }
        )
        viewModel.selectLastPeriodDate(updatedDate)

        await viewModel.updateLastPeriodDate()

        #expect(await updateUseCase.lastDate == updatedDate)
        #expect(outputRecorder.outputs == [.lastPeriodDateUpdated(updatedDate)])
        #expect(viewModel.saveState == .saved)
    }

    @Test
    func reloadResolvesLanguageAndProgress() async {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let activeProgress = ActivePregnancyProgress(
            lastPeriodDate: date,
            dueDate: date.addingTimeInterval(280 * 86_400),
            gestationalAge: GestationalAge(weeks: 10, days: 0),
            phase: .ongoing,
            dueDateRelation: .upcoming(days: 210)
        )
        let progress = PregnancyProgress.active(activeProgress)
        let viewModel = SettingsViewModel(
            loadPregnancyProgressUseCase: SettingsProgressUseCaseStub(progress: progress),
            updateLastPeriodDateUseCase: SettingsUpdateDateUseCaseRecorder(),
            calculateDueDateUseCase: SettingsDueDateUseCaseStub(),
            resolveAppLanguageUseCase: ResolveAppLanguageUseCase(),
            loadAppVersionUseCase: SettingsAppVersionUseCaseStub(version: "1.2.3"),
            initialLanguage: .english,
            outputHandler: { _ in }
        )

        await viewModel.reload(asOf: date, preferredLanguages: ["es-ES"])

        #expect(viewModel.lastPeriodDate == date)
        #expect(viewModel.dueDate == activeProgress.dueDate)
        #expect(viewModel.appLanguage == .spanish)
        #expect(viewModel.appVersion == "1.2.3")
        #expect(viewModel.loadingState == .loaded)
    }

    @Test
    func updateDateFailureDoesNotEmitOutput() async {
        let outputRecorder = SettingsOutputRecorder()
        let viewModel = makeViewModel(
            updateUseCase: SettingsFailingUpdateDateUseCase(),
            outputHandler: { outputRecorder.record($0) }
        )

        await viewModel.updateLastPeriodDate()

        #expect(viewModel.saveState == .failed)
        #expect(outputRecorder.outputs.isEmpty)
    }

    @Test
    func reloadFlagsHistoricalFutureDateForCorrection() async {
        let storedFutureDate = Date(timeIntervalSince1970: 1_800_000_000)
        let viewModel = SettingsViewModel(
            loadPregnancyProgressUseCase: SettingsProgressUseCaseStub(
                progress: .invalidFutureLastPeriodDate(lastPeriodDate: storedFutureDate)
            ),
            updateLastPeriodDateUseCase: SettingsUpdateDateUseCaseRecorder(),
            calculateDueDateUseCase: SettingsDueDateUseCaseStub(),
            resolveAppLanguageUseCase: ResolveAppLanguageUseCase(),
            loadAppVersionUseCase: SettingsAppVersionUseCaseStub(version: "1.2.3"),
            initialLanguage: .english,
            outputHandler: { _ in }
        )

        await viewModel.reload(asOf: .now, preferredLanguages: ["en-US"])

        #expect(viewModel.hasStoredFutureLastPeriodDate)
        #expect(viewModel.dueDate == nil)
    }

    @Test
    func selectingDateUpdatesDueDateWithoutPersistingOrEmittingOutput() async {
        let selectedDate = Date(timeIntervalSince1970: 1_700_000_000)
        let expectedDueDate = Date(timeIntervalSince1970: 1_800_000_000)
        let updateUseCase = SettingsUpdateDateUseCaseRecorder()
        let outputRecorder = SettingsOutputRecorder()
        let viewModel = makeViewModel(
            updateUseCase: updateUseCase,
            calculateDueDateUseCase: SettingsDueDateUseCaseStub(dueDate: expectedDueDate),
            outputHandler: { outputRecorder.record($0) }
        )

        viewModel.selectLastPeriodDate(selectedDate)

        #expect(viewModel.lastPeriodDate == selectedDate)
        #expect(viewModel.dueDate == expectedDueDate)
        #expect(await updateUseCase.lastDate == nil)
        #expect(outputRecorder.outputs.isEmpty)
    }

    private func makeViewModel(
        updateUseCase: any UpdateLastPeriodDateUseCaseProtocol,
        calculateDueDateUseCase: any CalculateDueDateUseCaseProtocol = SettingsDueDateUseCaseStub(),
        outputHandler: @escaping SettingsViewModelOutputHandler
    ) -> SettingsViewModel {
        SettingsViewModel(
            loadPregnancyProgressUseCase: SettingsProgressUseCaseStub(progress: nil),
            updateLastPeriodDateUseCase: updateUseCase,
            calculateDueDateUseCase: calculateDueDateUseCase,
            resolveAppLanguageUseCase: ResolveAppLanguageUseCase(),
            loadAppVersionUseCase: SettingsAppVersionUseCaseStub(version: "1.0"),
            initialLanguage: .english,
            outputHandler: outputHandler
        )
    }
}

private struct SettingsDueDateUseCaseStub: CalculateDueDateUseCaseProtocol {
    var dueDate = Date(timeIntervalSince1970: 2_000_000_000)

    func execute(lastPeriodDate: Date) -> Date {
        dueDate
    }
}

@MainActor
private final class SettingsOutputRecorder {
    private(set) var outputs: [SettingsViewModelOutput] = []

    func record(_ output: SettingsViewModelOutput) {
        outputs.append(output)
    }
}

private struct SettingsProgressUseCaseStub: LoadPregnancyProgressUseCaseProtocol {
    let progress: PregnancyProgress?

    func execute(asOf date: Date) async throws -> PregnancyProgress? {
        progress
    }
}

private actor SettingsUpdateDateUseCaseRecorder: UpdateLastPeriodDateUseCaseProtocol {
    private(set) var lastDate: Date?

    func execute(_ date: Date?, asOf: Date) {
        lastDate = date
    }
}

private struct SettingsFailingUpdateDateUseCase: UpdateLastPeriodDateUseCaseProtocol {
    func execute(_ date: Date?, asOf: Date) async throws {
        throw SettingsUpdateDateError.persistenceFailed
    }
}

private enum SettingsUpdateDateError: Error {
    case persistenceFailed
}

private struct SettingsAppVersionUseCaseStub: LoadAppVersionUseCaseProtocol {
    let version: String

    func execute() -> String {
        version
    }
}
