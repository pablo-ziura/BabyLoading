import FirebaseAuth
import FirebaseCore

@MainActor
public final class FirebaseServiceClients {
    let authentication: Auth

    public init(app: FirebaseApp) {
        authentication = Auth.auth(app: app)
    }
}
