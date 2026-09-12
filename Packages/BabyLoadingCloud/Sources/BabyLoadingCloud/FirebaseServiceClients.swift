import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import FirebaseStorage
import Foundation

@MainActor
public final class FirebaseServiceClients {
    let authentication: Auth
    let firestore: Firestore
    let storage: Storage

    public init(app: FirebaseApp) {
        authentication = Auth.auth(app: app)
        firestore = Firestore.firestore(app: app)
        storage = Storage.storage(app: app)

        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings(
            sizeBytes: NSNumber(value: 100 * 1_024 * 1_024)
        )
        firestore.settings = settings
    }
}
