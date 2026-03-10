import Foundation

protocol PregnancyContentCacheStoreProtocol: AnyObject {
    func loadDocument() -> PregnancyContentDocument?
    @discardableResult
    func saveDocument(_ document: PregnancyContentDocument) -> Bool

    var eTag: String? { get set }
    var lastFetchAt: Date? { get set }
    var revision: Int? { get set }
}
