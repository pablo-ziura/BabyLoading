import Foundation
import PregnancyProgress

enum MockPregnancyProgressError: Error {
    case loadFailed
    case updateFailed
}

@MainActor
final class MockLoadPregnancyProgressUseCase: LoadPregnancyProgressUseCaseProtocol {
    var result: PregnancyProgress?
    var error: (any Error)?
    private(set) var executeCalled = false
    private(set) var executeCallCount = 0
    private(set) var requestedDate: Date?

    func execute(asOf date: Date) async throws -> PregnancyProgress? {
        executeCalled = true
        executeCallCount += 1
        requestedDate = date

        if let error {
            throw error
        }

        return result
    }
}

@MainActor
final class MockUpdateLastPeriodDateUseCase: UpdateLastPeriodDateUseCaseProtocol {
    var error: (any Error)?
    private(set) var executeCalled = false
    private(set) var executeCallCount = 0
    private(set) var updatedDate: Date?

    func execute(_ date: Date?) async throws {
        executeCalled = true
        executeCallCount += 1
        updatedDate = date

        if let error {
            throw error
        }
    }
}
