@testable import BabyLoading
import Foundation

class MockDataSource: BabyProgressDataSourceProtocol {
    var storedDate: Date?
    var saveCalled = false
    var fetchCalled = false

    func save(date: Date?) {
        saveCalled = true
        storedDate = date
    }

    func fetchDate() -> Date? {
        fetchCalled = true
        return storedDate
    }
}
