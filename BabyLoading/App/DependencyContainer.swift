import Foundation

class DependencyContainer {
    static let shared = DependencyContainer()

    let dataSource: BabyProgressDataSourceProtocol
    let repository: BabyProgressRepositoryProtocol
    let widgetReloader: WidgetReloaderProtocol

    private init() {
        dataSource = BabyProgressDataSource()
        repository = BabyProgressRepository(dataSource: dataSource)
        widgetReloader = DefaultWidgetReloader()
    }
}
