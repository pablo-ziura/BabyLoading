import Foundation

struct BundleContentSource: PregnancyContentBundleSourceProtocol {
    private let bundle: Bundle
    private let resourceName: String

    init(bundle: Bundle, resourceName: String = "pregnancy-content.es") {
        self.bundle = bundle
        self.resourceName = resourceName
    }

    func loadDocument() -> PregnancyContentDocument? {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json"),
              let data = try? Data(contentsOf: url)
        else {
            return nil
        }

        return try? PregnancyContentDocument.decodeValidated(from: data)
    }
}
