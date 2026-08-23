import Foundation

@MainActor
final class WidgetDependencyContainer {
    let language: AppLanguage
    let timelineProvider: BabyProgressTimelineProvider

    init() {
        let languageRepository = AppLanguageRepository()
        let language = languageRepository.resolvedLanguage()
        let repository = BabyProgressRepository(
            dataSource: BabyProgressDataSource(),
            contentRepositoryFactory: PregnancyContentRepositoryFactory(),
            initialLanguage: language
        )

        self.language = language
        timelineProvider = BabyProgressTimelineProvider(
            repository: repository,
            language: language
        )
    }
}
