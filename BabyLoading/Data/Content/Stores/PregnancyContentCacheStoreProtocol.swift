import Foundation

protocol PregnancyContentCacheStoreProtocol: AnyObject {
    func loadDocument() -> PregnancyContentDocument?
}
