@testable import BabyLoading
import BabyLoadingInfrastructure
import Testing

struct SharedPersistenceContractTests {
    @Test func appGroupIdentifierRemainsCompatibleAcrossTargets() {
        #expect(SharedAppGroup.identifier == "group.com.pablo.BabyLoading")
    }

}
