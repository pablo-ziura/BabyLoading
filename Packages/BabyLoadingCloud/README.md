# BabyLoadingCloud

Firebase adapters for the Baby Loading application. The host composition root owns
these clients; feature views and the widget must not construct or import them.

## Current integration stage

The package currently provides explicitly injected Firebase clients and the
100 MiB persistent Firestore cache configuration. `CloudBackup`, in
`BabyLoadingCore`, provides the local `PregnancyLog` and `SyncStatus` types.
Authentication flows, synchronization, image transfers and UI integration follow
after the manual Xcode linking checkpoint. The new Auth, Firestore and Storage
clients are not instantiated by the application at this stage.

Firebase 12.18.0 and Google Sign-In 10.0.0 match the application's existing resolved
versions. SDK dependencies are declared explicitly in this package.

## Manual Xcode linking checkpoint

1. Open `BabyLoading.xcodeproj`.
2. Add the local package at `Packages/BabyLoadingCloud` using Xcode's package
   dependency interface. Select the `BabyLoadingCloud` product for the
   `BabyLoading` application target.
3. Add the `CloudBackup` product from the already referenced `BabyLoadingCore`
   package to the `BabyLoading` target's **Frameworks, Libraries, and Embedded
   Content**. Do not add another copy of the Core package.
4. Keep both products out of `BabyProgressWidgetExtension`. FirebaseAuth,
   FirebaseFirestore and FirebaseStorage are dependencies of this package and
   do not need separate direct links from the host.
5. Resolve package versions. Report completion before implementation resumes.

After this checkpoint, verify the project references, dependency resolution,
application compilation and absence of Firebase from the widget dependency graph.
Create `FirebaseServiceClients` only after the application delegate configures
Firebase, and before any Firestore operations. Recreate clients deliberately when
resetting a Firestore session; do not repeatedly configure an active instance.

## Firebase and provider configuration

- Keep production configuration at
  `Configuration/Firebase/GoogleService-Info.plist`.
- Register Lab in a separate Firebase project and replace
  `Configuration/Firebase/GoogleService-Info-Lab.plist` with its configuration.
  Distinct iOS app registrations in the same Firebase project do not isolate
  authentication, documents or image storage.
- Enable Anonymous, Email/Password, Google and Apple authentication in both
  projects. Create Firestore and Storage resources in each project.
- Enable Sign in with Apple for the production and Lab app identifiers and their
  signing profiles. Configure the Apple provider, including the OAuth code flow
  required for token revocation. Keep Apple private keys outside the repository.
- Verify Google client IDs and URL callbacks against each configuration's
  `REVERSED_CLIENT_ID`.
- Firebase configuration plists remain ignored by Git. Security rules and
  emulator tests will be delivered with the synchronization implementation;
  deploying them is a separate step.

## Boundaries

- The local persistence layer remains authoritative for offline operation.
- Anonymous authentication does not authorize uploading pregnancy data.
- `PregnancyLog` is a local model. Do not encode it directly into Firestore:
  local paths and transient device transfer states are not remote fields.
- Account deletion removes Auth on the client. A separately managed backend
  removes the associated Firestore and Storage data.
