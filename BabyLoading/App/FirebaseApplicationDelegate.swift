import FirebaseCore
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

        return options
    }
}
