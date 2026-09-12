import CloudBackup
import Foundation
import Network

public struct BackupNetworkMonitor: BackupConnectivityProtocol {
    public init() {}

    public func changes() -> AsyncStream<Bool> {
        AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            let monitor = NWPathMonitor()
            monitor.pathUpdateHandler = { continuation.yield($0.status == .satisfied) }
            continuation.onTermination = { _ in monitor.cancel() }
            monitor.start(queue: DispatchQueue(label: "com.babyloading.backup.connectivity"))
        }
    }
}
