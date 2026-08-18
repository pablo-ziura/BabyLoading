@testable import BabyLoading

struct MockAppVersionProvider: AppVersionProviding {
    let version: String

    func marketingVersion() -> String {
        version
    }
}
