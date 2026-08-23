import Foundation

final class PregnancyContentRepositoryFactory: PregnancyContentRepositoryFactoryProtocol {
    private let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    func makeRepository(for language: AppLanguage) -> PregnancyContentRepositoryProtocol {
        let localization = PregnancyContentLocalization(localeCode: language.rawValue)

        return PregnancyContentRepository(
            expectedLocale: localization.localeCode,
            bundleSource: BundleContentSource(bundle: bundle, localization: localization),
            cacheStore: SharedContentCacheStore(localization: localization)
        )
    }
}
