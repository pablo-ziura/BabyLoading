# BabyLoading

## Español

`BabyLoading` es una app iOS en SwiftUI para seguir el embarazo desde la fecha de la última
menstruación. Calcula la semana actual y la fecha estimada de parto, presenta contenido semanal
localizado, conserva galerías de ecografías y seguimiento fotográfico, y comparte el progreso con
un widget.

### Features

- `Dashboard`: semana, fecha estimada de parto, días restantes y resumen del desarrollo.
- `Journey`: cronología localizada de las semanas `6...40`.
- `Gallery`: ecografías, exportación a Fotos y seguimiento guiado con cámara.
- `Settings`: configuración de la fecha base e información de versión.
- `BabyProgressWidget`: snapshot del progreso sobre el mismo App Group que la app.

### Requisitos y stack

- Xcode con soporte para el SDK de iOS 26.5.
- iOS 26.5 para iPhone y iPad.
- Simulador de referencia: `iPhone 17 Pro Max`, iOS 26.5.
- Swift 6, SwiftUI, Observation, WidgetKit y Swift Package Manager.
- App Group `group.com.pablo.BabyLoading`.
- Inglés y español mediante `Localizable.xcstrings` y contenido JSON validado.
- La app mantiene `.preferredColorScheme(.light)`.

### Variante de laboratorio

El scheme compartido `BabyLoading Lab` instala una segunda app, `Baby Loading Lab`, para pruebas
manuales sin alterar datos reales. Usa el bundle identifier
`com.pablo.ruiz.babyloading.lab`, el App Group aislado `group.com.pablo.BabyLoading.lab` y el icono
violeta `AppIconLab`. No debe utilizarse para distribución ni para datos de producción.

### Arquitectura

La app usa un único coordinator como composition root de presentación:

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

`Coordinator` crea internamente un `DependencyContainer` no singleton y posee exclusivamente el
router y los cuatro ViewModels. Las factories los inyectan mediante SwiftUI `Environment`.
`AppRouter` solo modela la tab seleccionada y la cámara full-screen. Las Views no conocen stores,
repositories ni use cases.

Cuando cambia `lastPeriodDate`, `Coordinator` recarga las cuatro features y el widget. Cuando cambia
el locale efectivo, recrea las operaciones de contenido, refresca toda la presentación y solicita
un nuevo timeline del widget.

### Módulos

| Package | Productos |
|---|---|
| `AppPreferences` | `AppPreferences` |
| `BabyLoadingCore` | `BabyLoadingInfrastructure`, `AppLocalization`, `PregnancyProgress`, `PregnancyContent`, `UltrasoundGallery`, `BellyTracking`, `BabyProgressWidgetSupport` |
| `BabyLoadingDesignSystem` | `BabyLoadingDesignTokens`, `BabyLoadingDesignComponents` |
| `BabyLoadingFeatures` | `BabyLoadingNavigation`, `DashboardFeature`, `JourneyFeature`, `GalleryFeature`, `SettingsFeature` |

Las features no dependen entre sí. Core no importa SwiftUI, WidgetKit, Photos ni AVFoundation.
`GalleryFeature` concentra PhotosUI, Photos, AVFoundation y la cámara. Los componentes de diseño
dependen de los tokens semánticos. El target host conserva únicamente lifecycle, routing,
composición y el shell de tabs.

### Datos y contenido

- `lastPeriodDate` se persiste con `AppPreferences` en el App Group.
- Las ecografías viven en `gallery/` y mantienen identidad estable por nombre de archivo.
- El seguimiento vive en `belly-tracking/manifest.json` con schema v1.
- Las capturas nuevas conservan HEIC cuando está disponible; JPEG/JPG históricos siguen siendo
  compatibles.
- El contenido base está en `BabyLoading/Resources/pregnancy-content.en.json` y
  `pregnancy-content.es.json`.
- La prioridad es: bundle host válido -> cache histórica válida de solo lectura -> documento vacío.
- No hay sincronización remota, networking de producto ni API legacy de foto única.

### Widget y concurrencia

`WidgetDependencyContainer` compone un grafo independiente y carga un
`BabyProgressWidgetSnapshot` inmutable. No crea navegación ni presentación de la app. Los cambios de
fecha o locale solicitan recarga y el timeline actualiza también cada hora.

App, coordinator, router, ViewModels, timeline provider y modelo observable de cámara están aislados
en `MainActor`. Los stores, repositories con estado y el servicio de captura son actors. Los use
cases inmutables son `Sendable` y los errores de I/O se convierten en estados de UI tipados.

### Estructura del repositorio

```text
BabyLoading/
  App/
  Presentation/Navigation/
  Resources/
BabyProgressWidget/
BabyLoadingTests/
Packages/
  AppPreferences/
  BabyLoadingCore/
  BabyLoadingDesignSystem/
  BabyLoadingFeatures/
Scripts/swiftlint/
AGENTS.md
DESIGN.md
```

### Verificación local

Abre el proyecto:

```bash
open BabyLoading.xcodeproj
```

Ejecuta SwiftLint y todos los tests de packages:

```bash
./Scripts/swiftlint/swiftlint-0.65.1 lint --config .swiftlint.yml --strict --force-exclude --no-cache

swift test --package-path Packages/AppPreferences
swift test --package-path Packages/BabyLoadingCore
swift test --package-path Packages/BabyLoadingDesignSystem
swift test --package-path Packages/BabyLoadingFeatures
```

Ejecuta el test plan del host:

```bash
xcodebuild test -project BabyLoading.xcodeproj -scheme BabyLoadingTests -testPlan BabyLoadingTests -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=26.5'
```

Compila app, widget e iPad:

```bash
xcodebuild -project BabyLoading.xcodeproj -scheme BabyLoading -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=26.5' build
xcodebuild -project BabyLoading.xcodeproj -scheme 'BabyLoading Lab' -configuration Lab -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=26.5' build
xcodebuild -project BabyLoading.xcodeproj -scheme BabyLoading -configuration Release -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=26.5' build
xcodebuild -project BabyLoading.xcodeproj -scheme BabyProgressWidgetExtension -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=26.5' build
xcodebuild -project BabyLoading.xcodeproj -scheme BabyLoading -destination 'platform=iOS Simulator,name=iPad Pro 11-inch (M5),OS=26.5' build
```

La cámara debe verificarse además en un iPhone físico: permisos, start/stop, cancelación, captura,
HEIC, rotación de preview/captura y referencia superpuesta.

### Desarrollo

- `AGENTS.md` es la guía viva de arquitectura, dependencias y reglas de extensión.
- `DESIGN.md` es el contrato visual compartido con Android.
- La cobertura unitaria vive junto al package propietario; el target host conserva únicamente tests
  de composition root, recursos, frameworks y contratos compartidos.
- Los cambios del proyecto Xcode, membership, build settings, packages o assets se realizan con
  XcodeProjectCLI (`xcp`).

## English

`BabyLoading` is a SwiftUI iOS app for tracking pregnancy from the last menstrual period date. It
calculates the current week and estimated due date, presents localized weekly content, keeps
ultrasound and guided photo timelines, and shares progress with a widget.

### Features

- `Dashboard`: current week, estimated due date, remaining days, and development summary.
- `Journey`: localized timeline for weeks `6...40`.
- `Gallery`: ultrasound photos, Photos export, and guided camera tracking.
- `Settings`: base-date configuration and app version information.
- `BabyProgressWidget`: a progress snapshot backed by the same App Group as the app.

### Requirements and stack

- Xcode with the iOS 26.5 SDK.
- iOS 26.5 on iPhone and iPad.
- Reference simulator: `iPhone 17 Pro Max`, iOS 26.5.
- Swift 6, SwiftUI, Observation, WidgetKit, and Swift Package Manager.
- App Group `group.com.pablo.BabyLoading`.
- English and Spanish through `Localizable.xcstrings` and validated JSON content.
- The app keeps `.preferredColorScheme(.light)`.

### Lab variant

The shared `BabyLoading Lab` scheme installs a second app, `Baby Loading Lab`, for manual testing
without altering real data. It uses the `com.pablo.ruiz.babyloading.lab` bundle identifier, the
isolated `group.com.pablo.BabyLoading.lab` App Group, and the violet `AppIconLab` icon. It must not
be used for distribution or production data.

### Architecture

The app uses one coordinator as its presentation composition root:

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

`Coordinator` creates a non-singleton `DependencyContainer` internally and exclusively owns the
router and four ViewModels. Its factories inject them through SwiftUI `Environment`. `AppRouter`
models only selected-tab state and full-screen camera presentation. Views never receive stores,
repositories, or use cases.

Changing `lastPeriodDate` makes `Coordinator` reload all four features and the widget. When the
effective locale changes, it recreates content operations, refreshes presentation state, and asks
the widget for a new timeline.

### Modules

| Package | Products |
|---|---|
| `AppPreferences` | `AppPreferences` |
| `BabyLoadingCore` | `BabyLoadingInfrastructure`, `AppLocalization`, `PregnancyProgress`, `PregnancyContent`, `UltrasoundGallery`, `BellyTracking`, `BabyProgressWidgetSupport` |
| `BabyLoadingDesignSystem` | `BabyLoadingDesignTokens`, `BabyLoadingDesignComponents` |
| `BabyLoadingFeatures` | `BabyLoadingNavigation`, `DashboardFeature`, `JourneyFeature`, `GalleryFeature`, `SettingsFeature` |

Features do not depend on one another. Core does not import SwiftUI, WidgetKit, Photos, or
AVFoundation. `GalleryFeature` owns PhotosUI, Photos, AVFoundation, and camera code. Shared design
components depend on semantic tokens. The host target contains only lifecycle, routing,
composition, and the tab shell.

### Data and content

- `lastPeriodDate` is persisted through `AppPreferences` in the App Group.
- Ultrasound photos live in `gallery/` with stable file-name identity.
- Tracking data lives in `belly-tracking/manifest.json` using schema v1.
- New captures preserve HEIC when available; historical JPEG/JPG files remain compatible.
- Base content lives in `BabyLoading/Resources/pregnancy-content.en.json` and
  `pregnancy-content.es.json`.
- Loading priority is: valid host bundle -> valid read-only historical cache -> empty document.
- There is no remote synchronization, product networking, or legacy single-photo API.

### Widget and concurrency

`WidgetDependencyContainer` builds an independent graph around an immutable
`BabyProgressWidgetSnapshot`. It never creates app navigation or presentation state. Date and locale
changes request a reload, and the timeline also refreshes hourly.

The app, coordinator, router, ViewModels, timeline provider, and observable camera model are isolated
to `MainActor`. Stateful stores, repositories, and the capture service are actors. Immutable use
cases are `Sendable`, and I/O failures map to typed UI states.

### Repository structure

```text
BabyLoading/
  App/
  Presentation/Navigation/
  Resources/
BabyProgressWidget/
BabyLoadingTests/
Packages/
  AppPreferences/
  BabyLoadingCore/
  BabyLoadingDesignSystem/
  BabyLoadingFeatures/
Scripts/swiftlint/
AGENTS.md
DESIGN.md
```

### Local verification

Open the project:

```bash
open BabyLoading.xcodeproj
```

Run SwiftLint and every package test suite:

```bash
./Scripts/swiftlint/swiftlint-0.65.1 lint --config .swiftlint.yml --strict --force-exclude --no-cache

swift test --package-path Packages/AppPreferences
swift test --package-path Packages/BabyLoadingCore
swift test --package-path Packages/BabyLoadingDesignSystem
swift test --package-path Packages/BabyLoadingFeatures
```

Run the hosted test plan:

```bash
xcodebuild test -project BabyLoading.xcodeproj -scheme BabyLoadingTests -testPlan BabyLoadingTests -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=26.5'
```

Build the app, widget, and iPad destination:

```bash
xcodebuild -project BabyLoading.xcodeproj -scheme BabyLoading -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=26.5' build
xcodebuild -project BabyLoading.xcodeproj -scheme 'BabyLoading Lab' -configuration Lab -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=26.5' build
xcodebuild -project BabyLoading.xcodeproj -scheme BabyLoading -configuration Release -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=26.5' build
xcodebuild -project BabyLoading.xcodeproj -scheme BabyProgressWidgetExtension -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=26.5' build
xcodebuild -project BabyLoading.xcodeproj -scheme BabyLoading -destination 'platform=iOS Simulator,name=iPad Pro 11-inch (M5),OS=26.5' build
```

The camera also requires physical-iPhone verification for permissions, start/stop, cancellation,
capture, HEIC, preview/capture rotation, and the alignment reference overlay.

### Development

- `AGENTS.md` is the living architecture, dependency, and extension guide.
- `DESIGN.md` is the visual contract shared with Android.
- Unit tests live with their owning package; the host target keeps only composition-root, resource,
  framework, and shared-contract integration tests.
- Xcode project, membership, build-setting, package, and asset changes use XcodeProjectCLI (`xcp`).
