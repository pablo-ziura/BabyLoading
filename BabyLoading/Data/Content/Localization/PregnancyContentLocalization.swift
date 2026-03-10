import Foundation

struct PregnancyContentLocalization: Equatable, Sendable {
    static let fallbackLocale = "en"
    static let resourcePrefix = "pregnancy-content"

    let localeCode: String

    init(localeCode: String) {
        self.localeCode = localeCode
    }

    init(
        bundle: Bundle,
        preferredLanguages: [String] = Locale.preferredLanguages,
        bundlePreferredLocalizations: [String]? = nil,
        supportedLocales: [String]? = nil
    ) {
        let availableLocales = supportedLocales ?? Self.availableLocales(in: bundle)
        let preferredLocaleIdentifiers = (bundlePreferredLocalizations ?? bundle.preferredLocalizations) + preferredLanguages
        localeCode = Self.resolveLocale(
            supportedLocales: availableLocales,
            preferredLanguages: preferredLocaleIdentifiers
        )
    }

    var resourceName: String {
        "\(Self.resourcePrefix).\(localeCode)"
    }

    var fileName: String {
        "\(resourceName).json"
    }

    func metadataKey(_ suffix: String) -> String {
        "pregnancyContent.\(localeCode).\(suffix)"
    }

    static func availableLocales(in bundle: Bundle) -> [String] {
        let resourceURLs = bundle.urls(forResourcesWithExtension: "json", subdirectory: nil) ?? []
        let prefix = "\(resourcePrefix)."
        let suffix = ".json"

        let locales = resourceURLs.compactMap { url -> String? in
            let fileName = url.lastPathComponent
            guard fileName.hasPrefix(prefix), fileName.hasSuffix(suffix) else {
                return nil
            }

            let startIndex = fileName.index(fileName.startIndex, offsetBy: prefix.count)
            let endIndex = fileName.index(fileName.endIndex, offsetBy: -suffix.count)
            let localeCode = String(fileName[startIndex ..< endIndex])
            return localeCode.isEmpty ? nil : localeCode
        }

        return Array(Set(locales)).sorted()
    }

    private static func resolveLocale(
        supportedLocales: [String],
        preferredLanguages: [String]
    ) -> String {
        let uniqueLocales = Array(Set(supportedLocales)).sorted()

        guard !uniqueLocales.isEmpty else {
            return fallbackLocale
        }

        let defaultLocale = uniqueLocales.contains(fallbackLocale) ? fallbackLocale : uniqueLocales[0]
        return Bundle.preferredLocalizations(from: uniqueLocales, forPreferences: preferredLanguages).first
            ?? defaultLocale
    }
}
