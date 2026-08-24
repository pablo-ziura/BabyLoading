import Foundation

public struct BundlePregnancyContentSource: PregnancyContentSourceProtocol, Sendable {
    private let bundle: Bundle
    private let localization: PregnancyContentLocalization

    public init(
        bundle: Bundle,
        localization: PregnancyContentLocalization
    ) {
        self.bundle = bundle
        self.localization = localization
    }

    public func loadDocument() async throws -> PregnancyContentDocument? {
        guard let resourceURL = bundle.url(
            forResource: localization.resourceName,
            withExtension: "json"
        ) else {
            return nil
        }

        return try PregnancyContentDocument.decodeValidated(
            from: Data(contentsOf: resourceURL),
            expectedLocale: localization.localeCode
        )
    }
}
