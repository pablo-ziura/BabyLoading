import AppLocalization
import Foundation

final class PregnancyContentRepositoryFactory: PregnancyContentRepositoryFactoryProtocol {
    private let bundle: Bundle
    private let containerURL: URL
    private let fileManager: FileManager

    init(
        bundle: Bundle,
        containerURL: URL,
        fileManager: FileManager
    ) {
        self.bundle = bundle
        self.containerURL = containerURL
        self.fileManager = fileManager
    }

    func makeRepository(for language: AppLanguage) -> PregnancyContentRepositoryProtocol {
        let localization = PregnancyContentLocalization(localeCode: language.rawValue)

        return PregnancyContentRepository(
            expectedLocale: localization.localeCode,
            bundleSource: BundleContentSource(bundle: bundle, localization: localization),
            cacheStore: SharedContentCacheStore(
                localization: localization,
                fileManager: fileManager,
                containerURL: containerURL
            )
        )
    }
}
