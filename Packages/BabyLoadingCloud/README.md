# BabyLoadingCloud

Firebase adapters for the iOS app. `DependencyContainer` composes `BackupRuntime`
after `FirebaseApplicationDelegate` configures the selected Firebase project.
Features consume focused operations from `CloudBackup`; the widget has no Firebase
dependency and reads only the local `lastPeriodDate` projection.

## Configuration

The manual package-linking checkpoint is complete. The main target links
`BabyLoadingCloud` and `CloudBackup`. Keep both products and Firebase SDKs out of
`BabyProgressWidgetExtension`. Firebase 12.18.0 and Google Sign-In 10.0.0 are pinned.

| Configuration | App Info.plist | Firebase configuration | App Group |
| --- | --- | --- | --- |
| Debug / Release | `Configuration/BabyLoading-Info.plist` | `Configuration/Firebase/GoogleService-Info.plist` | `group.com.pablo.BabyLoading` |
| Lab | `Configuration/BabyLoading-Info-Lab.plist` | `Configuration/Firebase/GoogleService-Info-Lab.plist` | `group.com.pablo.BabyLoading.lab` |

Lab requires a different **Firebase project and Storage bucket**, not merely another
app registration or OAuth client in the same project. Its bundle identifier is
`com.pablo.ruiz.babyloading.lab`. The opposite Firebase plist is excluded from each
build. Startup checks that the selected Firebase configuration matches the app's
bundle identifier. Crashlytics also receives the selected configuration path.

Enable Anonymous, Email/Password and Google in both Firebase projects. Create
Firestore and Storage resources in each project. Firebase plists remain ignored
by Git. `GOOGLE_REVERSED_CLIENT_ID` supplies the matching URL scheme per build
configuration; update it through `xcp` whenever the corresponding OAuth client
changes. Google presentation uses the active scene, and the host handles callbacks.

**Sign in with Apple is deferred by the product decision for this implementation.**
It is not offered in the UI. Enabling it later requires its provider configuration,
entitlements, nonce handling, linking consent, recent authorization and token
revocation before account deletion.

## Local persistence and recovery

- Startup loads local data without waiting for authentication or a network request.
  Silent anonymous authentication retries transient failures; anonymous users never
  upload pregnancy documents or photos.
- `cloud-backup/manifest.json` is the atomic schema-v1 account index and outbox.
  `guest` and individual Firebase UIDs have separate profiles. Image originals live
  in `cloud-backup/files/` and are referenced only by their owning profiles.
- Before writing an original or downloaded image, persist its file intent. Startup
  completes interrupted writes whose files exist. Metadata and mutation identity
  commit together; retries preserve the same operation IDs.
- Migration copies `gallery/` and `belly-tracking/` originals byte for byte, retaining
  source identities, available dates, capture weeks and cadence. An unknown
  historical week remains `nil`. Only after the complete migration is committed
  are legacy copies retired. The tracking manifest remains schema v1.
- Account linking preserves the anonymous UID and adopts guest data. A durable
  linking marker recovers a restart before adoption completes. Signing into a
  different account offers guest import; it does not import automatically.
- Import refreshes the destination account first, adds missing stable photo IDs,
  and fills only missing date/cadence values. Repeating import does not duplicate
  photos. Source guest data is removed from the guest profile after import commits.
- Sign-out retains account data and its queue, hidden from the guest profile.
  Account transitions stop workers/listeners and clear Firestore persistence before
  changing authentication. Session checks discard late transfer results.
- Deletion requires UI confirmation. A recent-login error invokes email/password or
  Google reauthentication. Local deletion follows confirmed Auth deletion and a
  persisted confirmation; pending file cleanup recovers after interruption.
  Ambiguous network failures preserve local data until deletion is confirmed.
  Backend cleanup of Firestore and Storage remains separately managed.

## Synchronization contract

Remote paths are `users/{uid}/pregnancyLogs/{logId}` and
`users/{uid}/settings/pregnancy`. Operation receipts are immutable documents at
`users/{uid}/mutations/{operationId}`. Keep receipts and photo tombstones permanently
unless a future coordinated compaction protocol replaces this contract.

`RemotePregnancyLog` contains schema version, origin, original identity, available
date, optional week/notes/image URL and a deletion marker. It never contains device
paths or `uploading` state. `lastPeriodDay` is a Gregorian civil date (`yyyy-MM-dd`),
interpreted locally, rather than a timezone-dependent instant.

Local operations finish after the disk commit. The foreground worker sends queued
mutations transactionally, recording each receipt with its document change. Only
changed fields are patched; server commit order decides the latest value per field.
A tombstone prevents later edits or creates from reviving the record. A server
refresh after acknowledgement reconciles fields received during a local mutation.

Firestore uses `PersistentCacheSettings` with `100 * 1024 * 1024` bytes. This is a
cache cleanup threshold, not a strict storage quota. Persistence is initialized
before any Firestore access and reset through disable/terminate/clear/recreate
stages when accounts change.

## Images

The single foreground worker observes connectivity and local changes. It publishes
metadata before uploading to `users/{uid}/photos/{logId}.jpg`, then persists the
Storage URL before confirming it in Firestore. `synced` requires the document
acknowledgement. A failed document confirmation does not repeat the image upload.

JPEG export uses original pixel dimensions, materialized orientation, quality 0.9,
white behind transparency and no EXIF. Original files remain untouched. Existing
25 MiB / 48 megapixel / 12,000-pixel-dimension validation limits apply. Conversion
failures remain visible and retryable.

Remote JPEGs are downloaded automatically while active, checked for size/content
type, decoded and validated, then installed locally before the gallery exposes
them. Downloads are never automatically exported to Photos. Existing guided
capture export behavior is unchanged.

Transient failures retry with exponential delay and jitter, capped at five minutes.
Permanent failures remain visible with a retry action. Transfers stop when the app
leaves the foreground; this implementation does not promise execution while closed.

## Security rules and verification

Rules and emulator tests live in `Firebase/`. They deny anonymous access, enforce
UID ownership and schema constraints, protect tombstones and operation receipts,
and require a live photo document before a JPEG upload. **Rules are delivered but
are not deployed automatically.** See `Firebase/README.md` for commands.

Automated coverage includes offline initialization, stable-UID linking, existing
account import, repeated import, interrupted file writes, image confirmation retry,
late transfer completion, account isolation, recent-login deletion, JPEG conversion
and historical migration. Host tests use isolated local fixtures and offline cloud
adapters rather than creating real accounts.

Automated verification completed on 2026-09-13: Core (117 tests), Features
(48 tests), host integration tests, six emulator rules tests, strict SwiftLint, and
simulator builds for Debug, Release, Lab, the widget and iPad. The gallery account
switch regression was reproduced before the fix and passes afterward. Built app
resources were checked for the selected Firebase plist and matching Google callback;
the widget's package graph excludes cloud products.

Interactive simulator inspection was unavailable because Computer Use permission
was not granted. Build and mock results do not replace provider, accessibility or
physical-device checks.

Before release, complete the following checks in Lab with its deployed rules:

1. Register/sign in with Email/Password and Google, cancel credential prompts, and
   verify the callback returns to Lab. Verify password reset and email verification.
2. Use two devices to verify upload/download, offline edits, deletion while the
   second device is offline, reconnection, import and account switching mid-transfer.
3. Delete an account after its authentication expires; verify local cleanup and the
   separately managed backend's remote deletion.
4. Check VoiceOver and large Dynamic Type on Settings/Gallery. Validate physical
   camera permissions, rotation, capture, HEIC preservation and Photos export in Lab.

References: [Firebase offline persistence](https://firebase.google.com/docs/firestore/manage-data/enable-offline),
[transactions](https://firebase.google.com/docs/firestore/manage-data/transactions),
[account linking](https://firebase.google.com/docs/auth/ios/account-linking),
[account management](https://firebase.google.com/docs/auth/ios/manage-users).
