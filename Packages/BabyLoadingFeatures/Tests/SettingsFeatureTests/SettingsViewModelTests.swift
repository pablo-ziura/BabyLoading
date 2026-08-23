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
        viewModel.lastPeriodDate = updatedDate

        await viewModel.updateLastPeriodDate()

        #expect(await updateUseCase.lastDate == updatedDate)
        #expect(outputRecorder.outputs == [.lastPeriodDateUpdated(updatedDate)])
        #expect(viewModel.saveState == .saved)
    }

    @Test
    func reloadResolvesLanguageAndProgress() async {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let progress = PregnancyProgress(
            lastPeriodDate: date,
            dueDate: date.addingTimeInterval(280 * 86_400),
            currentWeek: 10,
            daysUntilDueDate: 210
        )
        let viewModel = SettingsViewModel(
            loadPregnancyProgressUseCase: SettingsProgressUseCaseStub(progress: progress),
            updateLastPeriodDateUseCase: SettingsUpdateDateUseCaseRecorder(),
            resolveAppLanguageUseCase: ResolveAppLanguageUseCase(),
            loadAppVersionUseCase: SettingsAppVersionUseCaseStub(version: "1.2.3"),
            initialLanguage: .english,
            outputHandler: { _ in }
        )

        await viewModel.reload(asOf: date, preferredLanguages: ["es-ES"])

        #expect(viewModel.lastPeriodDate == date)
        #expect(viewModel.dueDate == progress.dueDate)
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

    private func makeViewModel(
        updateUseCase: any UpdateLastPeriodDateUseCaseProtocol,
        outputHandler: @escaping SettingsViewModelOutputHandler
    ) -> SettingsViewModel {
        SettingsViewModel(
            loadPregnancyProgressUseCase: SettingsProgressUseCaseStub(progress: nil),
            updateLastPeriodDateUseCase: updateUseCase,
            resolveAppLanguageUseCase: ResolveAppLanguageUseCase(),
            loadAppVersionUseCase: SettingsAppVersionUseCaseStub(version: "1.0"),
            initialLanguage: .english,
            outputHandler: outputHandler
        )
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

    func execute(_ date: Date?) {
        lastDate = date
    }
}

private struct SettingsFailingUpdateDateUseCase: UpdateLastPeriodDateUseCaseProtocol {
    func execute(_ date: Date?) async throws {
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
