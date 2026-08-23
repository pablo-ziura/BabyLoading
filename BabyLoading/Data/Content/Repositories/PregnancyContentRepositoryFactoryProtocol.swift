import AppLocalization
import Foundation

protocol PregnancyContentRepositoryFactoryProtocol {
    func makeRepository(for language: AppLanguage) -> PregnancyContentRepositoryProtocol
}
