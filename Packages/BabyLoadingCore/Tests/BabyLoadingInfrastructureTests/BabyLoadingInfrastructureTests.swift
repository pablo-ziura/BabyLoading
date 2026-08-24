@testable import BabyLoadingInfrastructure
import Foundation
import Testing

struct BabyLoadingInfrastructureTests {
    @Test func sharedAppGroupIdentifierRemainsCompatible() {
        #expect(SharedAppGroup.identifier == "group.com.pablo.BabyLoading")
    }

    @Test func appVersionUseCaseReturnsProviderValue() {
        let useCase = LoadAppVersionUseCase(provider: AppVersionProviderStub(version: "3.2.1"))

        #expect(useCase.execute() == "3.2.1")
    }
}

private struct AppVersionProviderStub: AppVersionProviderProtocol {
    let version: String

    func marketingVersion() -> String {
        version
    }
}
