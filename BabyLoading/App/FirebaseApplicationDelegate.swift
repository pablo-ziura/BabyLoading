import FirebaseCore
import GoogleSignIn
import UIKit

@MainActor
final class FirebaseApplicationDelegate: NSObject, UIApplicationDelegate {
    func application(
        _: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        FirebaseApp.configure(options: firebaseOptions)
        return true
    }

    func application(
        _ application: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
    }

    private var firebaseOptions: FirebaseOptions {
        guard let resourceName = Bundle.main.object(
            forInfoDictionaryKey: "FirebaseConfigurationResourceName"
        ) as? String else {
            preconditionFailure("Missing Firebase configuration resource name.")
        }

        guard let configurationPath = Bundle.main.path(
            forResource: resourceName,
            ofType: "plist"
        ) else {
            preconditionFailure("Missing Firebase configuration resource.")
        }

        guard let options = FirebaseOptions(contentsOfFile: configurationPath) else {
            preconditionFailure("Invalid Firebase configuration resource.")
        }

        guard options.bundleID == Bundle.main.bundleIdentifier else {
            preconditionFailure("Firebase configuration does not match this application environment.")
        }
        return options
    }
}
