@testable import BabyLoadingInfrastructure
import Foundation
import Testing

struct BabyLoadingInfrastructureTests {
    @Test func sharedAppGroupIdentifierRemainsCompatible() {
        #expect(SharedAppGroup.productionIdentifier == "group.com.pablo.BabyLoading")

        let sharedAppGroup = try? SharedAppGroup(
            identifier: SharedAppGroup.productionIdentifier
        )

        #expect(sharedAppGroup?.identifier == SharedAppGroup.productionIdentifier)
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
