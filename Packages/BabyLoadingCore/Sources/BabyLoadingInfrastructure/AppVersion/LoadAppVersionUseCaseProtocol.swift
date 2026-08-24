import Foundation

public protocol LoadAppVersionUseCaseProtocol: Sendable {
    func execute() -> String
}
