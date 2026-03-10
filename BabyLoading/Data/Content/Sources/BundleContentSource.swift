import Foundation

struct BundleContentSource: PregnancyContentBundleSourceProtocol {
    private let bundle: Bundle
    private let localization: PregnancyContentLocalization

    init(bundle: Bundle, localization: PregnancyContentLocalization) {
        self.bundle = bundle
        self.localization = localization
    }

    func loadDocument() -> PregnancyContentDocument? {
        guard let url = bundle.url(forResource: localization.resourceName, withExtension: "json"),
              let data = try? Data(contentsOf: url)
        else {
            return nil
        }

        return try? PregnancyContentDocument.decodeValidated(
            from: data,
            expectedLocale: localization.localeCode
        )
    }
}
