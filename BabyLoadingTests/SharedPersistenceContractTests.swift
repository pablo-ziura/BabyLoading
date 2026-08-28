@testable import BabyLoading
import BabyLoadingInfrastructure
import Testing

struct SharedPersistenceContractTests {
    @Test func appGroupIdentifierRemainsCompatibleAcrossTargets() {
        #expect(SharedAppGroup.productionIdentifier == "group.com.pablo.BabyLoading")
    }

}
