import Foundation

extension Bundle {
    var pregnancyContentRemoteURL: URL? {
        guard let rawValue = object(forInfoDictionaryKey: "PregnancyContentURL") as? String,
              !rawValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return nil
        }

        return URL(string: rawValue)
    }
}
