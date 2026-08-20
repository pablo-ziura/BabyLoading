# BabyLoading

## Español

`BabyLoading` es una app iOS en SwiftUI para seguir el progreso del embarazo a partir de la fecha de la última menstruación. Calcula la semana actual y la fecha estimada de parto con la regla de Naegele, muestra hitos semanales localizados, mantiene una galería de fotos y expone el progreso en un widget compartido.

### Qué incluye

- `Dashboard`: semana actual, fecha estimada de parto, días restantes y resumen del desarrollo.
- `Journey`: timeline semanal con contenido para las semanas `6...40`.
- `Gallery`: galería multifoto persistida en el App Group compartido.
- `Settings`: configuración de la fecha base desde `DatePicker`.
- `BabyProgressWidget`: widget que reutiliza el mismo repositorio y almacenamiento compartido.

### Stack técnico

- Swift 6.0
- SwiftUI + Observation con `@Observable`
- `NavigationStack` con un `NavigationPath` por tab
- `WidgetKit`
- App Group compartido `group.com.pablo.BabyLoading`
- Contenido localizado en `en` y `es`
- Módulo local de networking en `Packages/AppNetwork/`; los targets principales siguen usando `URLSession` desde `RemoteContentSource`

### Arquitectura

- Flujo principal: `Presentation -> Repository -> Data/Domain`
- Composición central en `DependencyContainer.shared`
- Estado principal de UI en `BabyProgressViewModel`, marcado como `@MainActor` y `@Observable`
- Navegación por tabs en `AppCoordinator`
- Fábricas de vistas en `BabyLoading/App/DependencyContainer+ViewFactory.swift`
- La app refresca el contenido remoto al arrancar y al volver a primer plano
- El widget reutiliza `DependencyContainer.shared` para leer el mismo repositorio que la app

### Contenido semanal

- Recursos base en `BabyLoading/Resources/pregnancy-content.en.json` y `BabyLoading/Resources/pregnancy-content.es.json`
- Resolución de locale en `BabyLoading/Data/Content/Localization/` con fallback a `en`
- Snapshot inicial con prioridad `cache App Group -> bundle -> .empty`
- Caché compartida por locale con JSON, `ETag`, `lastFetchAt` y `revision`
- Sincronización remota opcional vía `PregnancyContentURL` o `PregnancyContentURLTemplate`
- La plantilla `PregnancyContentURLTemplate` admite el placeholder `{locale}`
- En el estado actual del proyecto, `INFOPLIST_KEY_PregnancyContentURL` está vacía y la sincronización remota queda desactivada por defecto
- `PregnancyContentRepository` intenta refrescar cada 12 horas cuando existe URL remota
- `PregnancyContentDocument` valida `schemaVersion`, `locale`, `revision`, semanas duplicadas, cobertura completa `6...40` y `keyEvents` no vacíos

### Datos compartidos y widget

- `lastPeriodDate` se guarda en `UserDefaults(suiteName:)`
- La foto legacy única se guarda como `user_photo.jpg`
- La galería multifoto se guarda en el directorio `gallery/` del contenedor compartido
- Cambios de fecha o cambios de snapshot remoto disparan `WidgetReloader`
- Cualquier cambio en keys, nombres de archivo o ubicaciones debe revisarse en app y widget a la vez

### Estructura del repo

```text
BabyLoading/
  App/
  Data/
  Domain/
  Presentation/
  Resources/
BabyProgressWidget/
BabyLoadingTests/
Packages/AppNetwork/
AGENTS.md
```

### Requisitos

- Xcode con soporte para iOS 26.2
- Simulador de referencia: `iPhone 17 Pro` con `iOS 26.2`
- La app fuerza `.preferredColorScheme(.light)`

### Arranque local

1. Abre el proyecto:

```bash
open BabyLoading.xcodeproj
```

2. Compila la app:

```bash
xcodebuild -project BabyLoading.xcodeproj -scheme BabyLoading -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2' build
```

3. Ejecuta los tests principales:

```bash
xcodebuild test -project BabyLoading.xcodeproj -scheme BabyLoadingTests -testPlan BabyLoadingTests -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2'
```

4. Si necesitas compilar el widget por separado:

```bash
xcodebuild -project BabyLoading.xcodeproj -scheme BabyProgressWidgetExtension -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2' build
```

### Configuración del contenido remoto

Puedes habilitar la sincronización remota definiendo una de estas keys en el `Info.plist`:

```text
PregnancyContentURL = https://example.com/pregnancy-content.es.json
```

o bien:

```text
PregnancyContentURLTemplate = https://example.com/pregnancy-content.{locale}.json
```

Notas:

- Si ambas keys están vacías, la app usa el bundle y la caché compartida
- El documento remoto debe respetar el schema validado por `PregnancyContentDocument`
- La `revision` remota debe ser mayor que la almacenada en caché para sustituir el snapshot actual
- Si el servidor devuelve `ETag`, la app enviará `If-None-Match` en refrescos posteriores

### Testing

- Hay tests con `XCTest` y `Testing`
- Cobertura relevante en `PregnancyCalculatorTests`, `BabyLoadingRepositoryTests`, `BabyLoadingViewModelTests`, `PregnancyContentDocumentTests`, `PregnancyContentRepositoryTests`, `PregnancyContentResourceTests` y `BabySizeResourceTests`
- `Packages/AppNetwork/` también contiene tests aislados bajo `Packages/AppNetwork/Tests/AppNetworkTests/`

### Notas de desarrollo

- `AGENTS.md` es la guía viva de arquitectura, dependencias y reglas de extensión del proyecto
- No mover lógica de negocio a las vistas
- No introducir nuevos singletons; la composición actual vive en `DependencyContainer.shared`
- Si una feature toca datos compartidos, revisar siempre app y widget en conjunto
- Si una decisión depende de APIs Apple, concurrencia Swift 6 o restricciones de WidgetKit, validar primero con documentación oficial

## English

`BabyLoading` is a SwiftUI iOS app for tracking pregnancy progress starting from the last menstrual period date. It calculates the current week and estimated due date using Naegele's rule, shows localized weekly milestones, keeps a photo gallery, and exposes progress through a shared widget.

### What it includes

- `Dashboard`: current week, estimated due date, remaining days, and development summary.
- `Journey`: weekly timeline with content for weeks `6...40`.
- `Gallery`: multi-photo gallery persisted in the shared App Group container.
- `Settings`: base date configuration through `DatePicker`.
- `BabyProgressWidget`: widget that reuses the same repository and shared storage.

### Tech stack

- Swift 6.0
- SwiftUI + Observation with `@Observable`
- `NavigationStack` with one `NavigationPath` per tab
- `WidgetKit`
- Shared App Group `group.com.pablo.BabyLoading`
- Localized content in `en` and `es`
- Local networking module under `Packages/AppNetwork/`; the main targets still use `URLSession` from `RemoteContentSource`

### Architecture

- Main flow: `Presentation -> Repository -> Data/Domain`
- Central composition in `DependencyContainer.shared`
- Main UI state in `BabyProgressViewModel`, marked as `@MainActor` and `@Observable`
- Tab navigation managed by `AppCoordinator`
- View factories live in `BabyLoading/App/DependencyContainer+ViewFactory.swift`
- The app refreshes remote content on launch and when returning to the foreground
- The widget reuses `DependencyContainer.shared` to read the same repository as the app

### Weekly content

- Base resources live in `BabyLoading/Resources/pregnancy-content.en.json` and `BabyLoading/Resources/pregnancy-content.es.json`
- Locale resolution lives in `BabyLoading/Data/Content/Localization/` with fallback to `en`
- Initial snapshot priority is `App Group cache -> bundle -> .empty`
- Shared cache is split by locale and stores JSON, `ETag`, `lastFetchAt`, and `revision`
- Remote sync is optional through `PregnancyContentURL` or `PregnancyContentURLTemplate`
- `PregnancyContentURLTemplate` supports the `{locale}` placeholder
- In the current project state, `INFOPLIST_KEY_PregnancyContentURL` is empty, so remote sync is disabled by default
- `PregnancyContentRepository` tries to refresh every 12 hours when a remote URL exists
- `PregnancyContentDocument` validates `schemaVersion`, `locale`, `revision`, duplicate weeks, full `6...40` coverage, and non-empty `keyEvents`

### Shared data and widget

- `lastPeriodDate` is stored in `UserDefaults(suiteName:)`
- The legacy single photo is stored as `user_photo.jpg`
- The multi-photo gallery is stored in the shared container `gallery/` directory
- Date changes or remote snapshot changes trigger `WidgetReloader`
- Any change to keys, file names, or locations should be reviewed in app and widget together

### Repository structure

```text
BabyLoading/
  App/
  Data/
  Domain/
  Presentation/
  Resources/
BabyProgressWidget/
BabyLoadingTests/
Packages/AppNetwork/
AGENTS.md
```

### Requirements

- Xcode with iOS 26.2 support
- Reference simulator: `iPhone 17 Pro` running `iOS 26.2`
- The app forces `.preferredColorScheme(.light)`

### Local setup

1. Open the project:

```bash
open BabyLoading.xcodeproj
```

2. Build the app:

```bash
xcodebuild -project BabyLoading.xcodeproj -scheme BabyLoading -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2' build
```

3. Run the main tests:

```bash
xcodebuild test -project BabyLoading.xcodeproj -scheme BabyLoadingTests -testPlan BabyLoadingTests -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2'
```

4. If you need to build the widget separately:

```bash
xcodebuild -project BabyLoading.xcodeproj -scheme BabyProgressWidgetExtension -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2' build
```

### Remote content configuration

You can enable remote sync by defining one of these keys in `Info.plist`:

```text
PregnancyContentURL = https://example.com/pregnancy-content.es.json
```

or:

```text
PregnancyContentURLTemplate = https://example.com/pregnancy-content.{locale}.json
```

Notes:

- If both keys are empty, the app uses the bundle and the shared cache
- The remote document must respect the schema validated by `PregnancyContentDocument`
- The remote `revision` must be greater than the cached revision to replace the current snapshot
- If the server returns an `ETag`, the app sends `If-None-Match` on later refreshes

### Testing

- The project contains both `XCTest` and `Testing` tests
- Relevant coverage includes `PregnancyCalculatorTests`, `BabyLoadingRepositoryTests`, `BabyLoadingViewModelTests`, `PregnancyContentDocumentTests`, `PregnancyContentRepositoryTests`, `PregnancyContentResourceTests`, and `BabySizeResourceTests`
- `Packages/AppNetwork/` also contains isolated tests under `Packages/AppNetwork/Tests/AppNetworkTests/`

### Development notes

- `AGENTS.md` is the living guide for architecture, dependencies, and extension rules in this project
- Do not move business logic into views
- Do not introduce new singletons; central composition already lives in `DependencyContainer.shared`
- If a feature touches shared data, always review app and widget together
- If a decision depends on Apple APIs, Swift 6 concurrency, or WidgetKit constraints, validate it first with official documentation
