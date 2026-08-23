import Foundation

public struct PregnancyContentLocalization: Equatable, Sendable {
    public static let fallbackLocale = "en"
    public static let resourcePrefix = "pregnancy-content"

    public let localeCode: String

    public init(localeCode: String) {
        self.localeCode = localeCode
    }

    public var resourceName: String {
        "\(Self.resourcePrefix).\(localeCode)"
    }

    public var fileName: String {
        "\(resourceName).json"
    }

    public static func resolve(
        supportedLocales: [String],
        preferredLanguages: [String]
    ) -> PregnancyContentLocalization {
        let availableLocales = Array(Set(supportedLocales)).sorted()
        guard !availableLocales.isEmpty else {
            return PregnancyContentLocalization(localeCode: fallbackLocale)
        }

        let fallback = availableLocales.contains(fallbackLocale)
            ? fallbackLocale
            : availableLocales[0]
        let localeCode = Bundle.preferredLocalizations(
            from: availableLocales,
            forPreferences: preferredLanguages
        ).first ?? fallback

        return PregnancyContentLocalization(localeCode: localeCode)
    }

    public static func availableLocales(in bundle: Bundle) -> [String] {
        let resourceURLs = bundle.urls(forResourcesWithExtension: "json", subdirectory: nil) ?? []
        let prefix = "\(resourcePrefix)."
        let suffix = ".json"

        return Array(Set(resourceURLs.compactMap { url -> String? in
            let fileName = url.lastPathComponent
            guard fileName.hasPrefix(prefix), fileName.hasSuffix(suffix) else {
                return nil
            }

            let startIndex = fileName.index(fileName.startIndex, offsetBy: prefix.count)
            let endIndex = fileName.index(fileName.endIndex, offsetBy: -suffix.count)
            let localeCode = String(fileName[startIndex ..< endIndex])
            return localeCode.isEmpty ? nil : localeCode
        })).sorted()
    }
}
