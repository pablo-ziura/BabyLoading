import CloudBackup
import FirebaseCore
import FirebaseFirestore
import FirebaseStorage
import Foundation
import GoogleSignIn
#if canImport(UIKit)
    import UIKit

@MainActor
public enum FirebaseBackupFactory {
    public static func makeServices(
        app: FirebaseApp,
        localStore: BackupLocalStore,
        preparer: any BackupImagePreparingProtocol,
        temporaryDirectory: URL,
        googleSignIn: GIDSignIn,
        presenter: @escaping @MainActor () -> UIViewController?
    ) throws -> BackupServices {
        let appName = app.name
        let clients = FirebaseServiceClients(app: app)
        let authentication = try AuthManager(clients: clients, googleSignIn: googleSignIn, presenter: presenter)
        let remote = try FirestoreService {
            guard let configuredApp = FirebaseApp.app(name: appName) else { throw BackupFailure.unavailable }
            return Firestore.firestore(app: configuredApp)
        }
        let storage = try FirebaseImageStorage {
            guard let configuredApp = FirebaseApp.app(name: appName) else { throw BackupFailure.unavailable }
            return Storage.storage(app: configuredApp)
        }
        let synchronize = SynchronizeBackupUseCase(localStore: localStore, remoteStore: remote)
        let images = ImageUploadService(
            localStore: localStore, storage: storage, preparer: preparer,
            synchronize: synchronize, temporaryDirectory: temporaryDirectory
        )
        let driver = BackupSynchronizationDriver(
            localStore: localStore, remoteStore: remote, connectivity: BackupNetworkMonitor(),
            images: images, synchronize: synchronize
        )
        return BackupServices(authentication: authentication, remoteStore: remote, driver: driver)
    }
}
#endif
