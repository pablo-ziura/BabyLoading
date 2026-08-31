# AGENTS.md

Living document for every agent working on `BabyLoading`.
Read it in full before proposing changes or modifying code.

Before creating or modifying a screen, reusable component, or widget that includes text, read
`DESIGN.md` and apply its typography and accessibility rules. `DESIGN.md` is the shared visual
contract between iOS and Android: if a visual decision changes, also update its Android equivalent
and map the semantic tokens on both platforms.

Any modification to `BabyLoading.xcodeproj`, `project.pbxproj`, build settings, target membership,
build phases, package references, or assets must be made with XcodeProjectCLI (`xcp`). Do not edit
`project.pbxproj` manually.

## Project overview

- Native SwiftUI app with the `BabyLoading`, `BabyLoadingTests`, and
  `BabyProgressWidgetExtension` targets.
- Swift 6, Observation (`@Observable`), WidgetKit, Swift Package Manager, and a shared App Group.
- iOS 26.5 deployment target, iPhone and iPad only.
- The app is intentionally single-window on iPhone and iPad because one `Coordinator` owns the
  complete scene state.
- Reference simulator: `iPhone 17 Pro Max`, iOS 26.5.
- The visual appearance is kept forced to `.preferredColorScheme(.light)`.
- App resources, localized strings, fonts, and JSON files remain in `BabyLoading/Resources`.

## Composition root and state flow

```text
BabyLoadingApp
└── @State Coordinator
    ├── DependencyContainer
    ├── AppRouter
    ├── DashboardViewModel
    ├── JourneyViewModel
    ├── GalleryViewModel
    └── SettingsViewModel
```

- `BabyLoadingApp` owns `@State private var coordinator = Coordinator()`.
- `Coordinator` is the app's sole coordinator. It is `@MainActor`, `@Observable`, and internally
  constructs a non-singleton `DependencyContainer`.
- `Coordinator` is the exclusive owner of `AppRouter` and the four ViewModels.
- `AppRouter` models only the selected tab and the full-screen presentation of the tracking camera.
  Do not introduce routes or stacks that do not correspond to an active flow.
- The router and ViewModels are provided through the SwiftUI `Environment` from the
  `Coordinator` factories.
- Views never receive stores, repositories, or use cases. They also do not construct dependencies.
- Do not apply type erasure to factories: keep opaque types with `some View`.
- `SettingsViewModelOutput.lastPeriodDateUpdated` causes `Coordinator` to reload the four features
  and request a widget reload.
- If the effective locale changes, `Coordinator` recreates the content use cases, updates the four
  features, and reloads the widget.
- `Coordinator` ignores activation callbacks until its initial load completes. Every later
  activation reloads the four date-dependent features from one captured date; unchanged locales
  reuse the existing content use cases and do not trigger a widget reload.

## Packages and modules

| Package | Products |
|---|---|
| `AppPreferences` | `AppPreferences` |
| `BabyLoadingCore` | `BabyLoadingInfrastructure`, `AppLocalization`, `PregnancyProgress`, `PregnancyContent`, `UltrasoundGallery`, `BellyTracking`, `BabyProgressWidgetSupport` |
| `BabyLoadingDesignSystem` | `BabyLoadingDesignTokens`, `BabyLoadingDesignComponents` |
| `BabyLoadingFeatures` | `BabyLoadingNavigation`, `DashboardFeature`, `JourneyFeature`, `GalleryFeature`, `SettingsFeature` |

Graph rules:

- No feature depends on another feature.
- `GalleryFeature` is the only module that imports PhotosUI, Photos, or AVFoundation. It also owns
  the UI, ViewModel, and camera service.
- `BabyLoadingCore` products do not import SwiftUI, WidgetKit, Photos, or AVFoundation.
- `BabyLoadingDesignComponents` depends on `BabyLoadingDesignTokens`.
- The widget compiles only Swift under `BabyProgressWidget/` and consumes modular products.
- Each production source belongs to a single target.
- Do not create `Interface`/`Implementation` target pairs.
- Protocol names end in `Protocol`. Use `Model` or `DTO` suffixes only when they describe a real
  technical role.
- Keep one use case per operation. Do not reintroduce cross-cutting repositories that mix unrelated
  domains or capabilities.
- No production initializer accepts optional dependencies, global fallbacks, or a default concrete
  implementation.

## Module responsibilities

- `BabyLoadingInfrastructure`: App Group access and app version.
- `AppLocalization`: resolution of the app's effective language.
- `PregnancyProgress`: calculation, persistence, and operations on `lastPeriodDate`.
- `PregnancyContent`: validation, localization, bundle/cache sources, and week or timeline queries.
- `UltrasoundGallery`: ultrasound photo identity and persistence.
- `BellyTracking`: timeline, manifest, image processing, settings, and cadence rules.
- `BabyProgressWidgetSupport`: immutable snapshot and the operation that loads it.
- `BabyLoadingDesignTokens`: semantic typography, colors, spacing, shapes, and elevation.
- `BabyLoadingDesignComponents`: shared SwiftUI components such as `GradientBackground` and
  `SoftCard`.
- Each feature owns its ViewModel, views, presentation state, and tests.
- The host target is limited to the lifecycle, composition root, routing, and tab shell.

## Shared persistence

- The `Debug` and `Release` configurations use the production App Group:
  `group.com.pablo.BabyLoading`. The `Lab` configuration uses the isolated App Group
  `group.com.pablo.BabyLoading.lab` and installs alongside production with its own bundle identifier.
- `Lab` uses the `AppIconLab` asset set, which preserves the production icon under a uniform
  semi-transparent violet overlay. `Debug` and `Release` continue to use `AppIcon`.
- `APP_GROUP_IDENTIFIER` is injected into the app and widget Info.plists and entitlements. Both
  composition roots resolve it through `SharedAppGroup`; do not hardcode the identifier or allow a
  Lab build to access the production group.
- Backward-compatible preference key: `lastPeriodDate`, managed through `AppPreferences`.
- `AppPreferences` does not know the App Group or product keys; the suite is injected by
  `SharedAppGroup`.
- Ultrasounds: `gallery/` directory, with stable identity based on the file name.
- Tracking: `belly-tracking/manifest.json`, schema v1.
- A guided capture is stored only in `belly-tracking/`; it is not duplicated in `gallery/`.
- New captures preserve HEIC when the camera permits it. Historical JPEG/JPG files remain
  supported.
- EXIF orientation is materialized before the 9:16 center crop.
- There is no production API for the former single photo; do not add runtime migration or purging
  without an explicit decision.
- Any change to keys, paths, schemas, or formats is cross-target and requires reviewing the app,
  widget, and contract tests in the same change.

## Weekly content

- Base sources: `BabyLoading/Resources/pregnancy-content.en.json` and
  `BabyLoading/Resources/pregnancy-content.es.json`.
- Read priority: valid host bundle -> valid read-only historical cache -> empty document for the
  requested locale.
- The historical cache uses `pregnancy-content.<locale>.json` in the App Group. It is not written
  or deleted.
- There is no remote synchronization, refresh, ETag, or endpoint configuration.
- `PregnancyContentDocument` decodes and retains `revision`; it validates the schema, locale,
  unique weeks with complete `6...40` coverage, and non-empty `keyEvents`.
- Unsupported locales fall back to English (`en`).
- Do not relax validation to accept incorrect documents. A schema change requires updating models,
  validation, resources, and tests together.

## Concurrency

- The app, `Coordinator`, `DependencyContainer`, router, ViewModels, observable camera model, and
  timeline provider live on `MainActor`.
- Stores and repositories with mutable state are actors.
- The capture service is an actor that serializes the AVFoundation session.
- Immutable use cases are `Sendable` structs.
- Persistence errors propagate with `throws`; ViewModels translate them into typed UI states and
  retain the last valid content when applicable.
- Do not use unsafe concurrency annotations or silence persistence failures.
- Avoid `Task` in Views when the responsibility belongs to a ViewModel or `Coordinator`.
- If a decision depends on concurrency, deprecations, or current Apple API behavior, validate it
  first with the official documentation through the `cupertino` MCP.

## UI, navigation, and accessibility

- Canonical tabs: dashboard, journey, gallery, and settings.
- Each tab keeps its own `NavigationStack`; there are no per-tab coordinators.
- The camera is presented from `AppRouter` as a full-screen destination.
- The viewer and `AVCapturePhotoOutput` use `AVCaptureDevice.RotationCoordinator` to align
  preview, capture, scale, and orientation.
- Reuse tokens and components from `BabyLoadingDesignSystem` first.
- Visible app and widget text lives in `Localizable.xcstrings`, currently in English and Spanish.
- Preserve Dynamic Type, VoiceOver, contrast, touch targets, and assistive technology behavior. Any
  shared visual decision requires updating `DESIGN.md` and Android.

## Widget

- `WidgetDependencyContainer` is an independent composition root.
- It composes the minimum graph of shared infrastructure, preferences, localization, progress,
  content, and snapshot loading; it never creates app navigation or presentation state.
- The entry is `BabyProgressWidgetEntry` and contains an immutable `BabyProgressWidgetSnapshot`.
- Date or locale changes request a reload through `WidgetReloader`.
- The timeline precomputes the current snapshot and snapshots for the next seven local midnights.
- If the snapshot or any persisted contract changes, review `WidgetDependencyContainer`,
  `BabyProgressTimelineProvider`, `BabyProgressWidgetEntry`, and
  `BabyProgressWidgetEntryView` together.

## Testing and quality

- Unit test coverage lives next to the owning package and uses Swift Testing.
- The host target retains integration coverage for the composition root, resources, frameworks, and
  shared contracts: `CoordinatorIntegrationTests`, `SharedPersistenceContractTests`,
  `PregnancyContentResourceTests`, `BabySizeResourceTests`, and
  `BabyLoadingTypographyTests`.
- Before changing business rules, parsing, persistence, camera, or widget behavior, first update
  the corresponding characterization tests.
- SwiftLint 0.65.1 is versioned in `Scripts/swiftlint/`; do not replace it with a global
  installation.
- A physical camera requires manual validation of permissions, start/stop, cancellation, capture,
  HEIC, preview/capture rotation, and overlay reference.

Verification commands:

```bash
./Scripts/swiftlint/swiftlint-0.65.1 lint --config .swiftlint.yml --strict --force-exclude --no-cache

swift test --package-path Packages/AppPreferences
swift test --package-path Packages/BabyLoadingCore
swift test --package-path Packages/BabyLoadingDesignSystem
swift test --package-path Packages/BabyLoadingFeatures

xcodebuild test -project BabyLoading.xcodeproj -scheme BabyLoadingTests -testPlan BabyLoadingTests -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=26.5'
xcodebuild -project BabyLoading.xcodeproj -scheme BabyLoading -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=26.5' build
xcodebuild -project BabyLoading.xcodeproj -scheme BabyLoading -configuration Release -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=26.5' build
xcodebuild -project BabyLoading.xcodeproj -scheme BabyProgressWidgetExtension -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=26.5' build
xcodebuild -project BabyLoading.xcodeproj -scheme BabyLoading -destination 'platform=iOS Simulator,name=iPad Pro 11-inch (M5),OS=26.5' build
```

## Extension rules

- Avoid introducing singletons, service locators, or global state.
- Do not move business logic or platform access into Views.
- When a new feature needs business logic or data, it must expose focused operations from Core,
  receive them in its ViewModel, and be composed by `Coordinator` without depending on another
  feature.
- If a feature touches shared data, test the app and widget together.
- Do not introduce external dependencies without an explicit, reviewed reason.
- Keep code, names, comments, and commit messages in English. Use minimal comments, only when they
  explain a decision the code does not express.
- Keep this document in sync with any change to architecture, targets, packages, persistence,
  widget, concurrency, or testing strategy.
