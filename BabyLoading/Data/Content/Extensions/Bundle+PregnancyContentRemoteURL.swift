import Foundation

extension Bundle {
    func pregnancyContentRemoteURL(localeCode: String) -> URL? {
        if let template = infoDictionaryValue(for: "PregnancyContentURLTemplate") {
            return URL(string: template.replacingOccurrences(of: "{locale}", with: localeCode))
        }

        guard let rawValue = infoDictionaryValue(for: "PregnancyContentURL") else {
            return nil
        }

        return URL(string: rawValue)
    }

    private func infoDictionaryValue(for key: String) -> String? {
        guard let rawValue = object(forInfoDictionaryKey: key) as? String,
              !rawValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return nil
        }

        return rawValue
    }
}
