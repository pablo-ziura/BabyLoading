import Foundation

class DependencyContainer {
    static let shared = DependencyContainer()
    
    let dataSource: BabyProgressDataSourceProtocol
    let repository: BabyProgressRepositoryProtocol
    
    private init() {
        self.dataSource = BabyProgressDataSource()
        self.repository = BabyProgressRepository(dataSource: self.dataSource)
    }
}
