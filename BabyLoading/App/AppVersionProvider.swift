import Foundation

protocol AppVersionProviding {
    func marketingVersion() -> String
}

struct BundleAppVersionProvider: AppVersionProviding {
    private let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    func marketingVersion() -> String {
        bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }
}
