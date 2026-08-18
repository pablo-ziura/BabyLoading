import Foundation

final class PregnancyContentRepositoryFactory: PregnancyContentRepositoryFactoryProtocol {
    private let bundle: Bundle
    private let session: URLSession

    init(bundle: Bundle = .main, session: URLSession = .shared) {
        self.bundle = bundle
        self.session = session
    }

    func makeRepository(for language: AppLanguage) -> PregnancyContentRepositoryProtocol {
        let localization = PregnancyContentLocalization(localeCode: language.rawValue)

        return PregnancyContentRepository(
            expectedLocale: localization.localeCode,
            bundleSource: BundleContentSource(bundle: bundle, localization: localization),
            cacheStore: SharedContentCacheStore(localization: localization),
            remoteSource: RemoteContentSource(
                session: session,
                url: bundle.pregnancyContentRemoteURL(localeCode: localization.localeCode),
                expectedLocale: localization.localeCode
            )
        )
    }
}
