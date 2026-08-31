public protocol LoadBabyProgressWidgetContextUseCaseProtocol: Sendable {
    func execute() async throws -> BabyProgressWidgetContext
}
