# AGENTS.md

Documento vivo para cualquier agente que trabaje en `BabyLoading`.
Leerlo completo antes de proponer cambios o tocar código.

Antes de crear o modificar una pantalla, un componente reutilizable o un widget que incluya texto,
leer `DESIGN.md` y aplicar sus reglas de tipografía y accesibilidad. `DESIGN.md` es el contrato visual
compartido entre iOS y Android: si cambia una decisión visual, actualizar también su equivalente de
Android y mapear los tokens semánticos en ambas plataformas.

Toda modificación de `BabyLoading.xcodeproj`, `project.pbxproj`, build settings, target membership,
build phases, referencias de paquetes o assets se realiza con XcodeProjectCLI (`xcp`). No editar
`project.pbxproj` manualmente.

## Resumen del proyecto

- App nativa SwiftUI con targets `BabyLoading`, `BabyLoadingTests` y
  `BabyProgressWidgetExtension`.
- Swift 6, Observation (`@Observable`), WidgetKit, Swift Package Manager y App Group compartido.
- Deployment target iOS 26.5, únicamente para iPhone y iPad.
- Simulador de referencia: `iPhone 17 Pro Max`, iOS 26.5.
- El esquema visual se mantiene forzado a `.preferredColorScheme(.light)`.
- Los recursos de app, strings localizados, fuentes y JSON permanecen en `BabyLoading/Resources`.

## Composition root y flujo de estado

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

- `BabyLoadingApp` posee `@State private var coordinator = Coordinator()`.
- `Coordinator` es el único coordinator de la app. Es `@MainActor`, `@Observable` y construye
  internamente un `DependencyContainer` no singleton.
- `Coordinator` es el propietario exclusivo de `AppRouter` y de los cuatro ViewModels.
- `AppRouter` modela únicamente la tab seleccionada y la presentación full-screen de la cámara de
  seguimiento. No introducir rutas o stacks que no correspondan a un flujo activo.
- Router y ViewModels se entregan mediante SwiftUI `Environment` desde las factories del
  `Coordinator`.
- Las Views nunca reciben stores, repositories ni use cases. Tampoco construyen dependencias.
- No aplicar type erasure a las factories: conservar tipos opacos con `some View`.
- `SettingsViewModelOutput.lastPeriodDateUpdated` hace que `Coordinator` recargue las cuatro
  features y solicite una recarga del widget.
- Si cambia el locale efectivo, `Coordinator` recrea los use cases de contenido, actualiza las
  cuatro features y recarga el widget.

## Paquetes y módulos

| Package | Productos |
|---|---|
| `AppPreferences` | `AppPreferences` |
| `BabyLoadingCore` | `BabyLoadingInfrastructure`, `AppLocalization`, `PregnancyProgress`, `PregnancyContent`, `UltrasoundGallery`, `BellyTracking`, `BabyProgressWidgetSupport` |
| `BabyLoadingDesignSystem` | `BabyLoadingDesignTokens`, `BabyLoadingDesignComponents` |
| `BabyLoadingFeatures` | `BabyLoadingNavigation`, `DashboardFeature`, `JourneyFeature`, `GalleryFeature`, `SettingsFeature` |

Reglas del grafo:

- Ninguna feature depende de otra feature.
- `GalleryFeature` es el único módulo que importa PhotosUI, Photos o AVFoundation. También posee la
  UI, el ViewModel y el servicio de cámara.
- Los productos de `BabyLoadingCore` no importan SwiftUI, WidgetKit, Photos ni AVFoundation.
- `BabyLoadingDesignComponents` depende de `BabyLoadingDesignTokens`.
- El widget solo compila Swift bajo `BabyProgressWidget/` y consume productos modulares.
- Cada source productivo pertenece a un único target.
- No crear pares de targets `Interface`/`Implementation`.
- Los protocolos terminan en `Protocol`. Usar sufijos `Model` o `DTO` solo cuando describan un rol
  técnico real.
- Mantener un use case por operación. No reintroducir repositorios transversales que mezclen
  dominios o capacidades no relacionadas.
- Ningún initializer productivo acepta dependencias opcionales, fallbacks globales o una
  implementación concreta por defecto.

## Responsabilidad de los módulos

- `BabyLoadingInfrastructure`: acceso al App Group y versión de la app.
- `AppLocalization`: resolución del idioma efectivo de la app.
- `PregnancyProgress`: cálculo, persistencia y operaciones sobre `lastPeriodDate`.
- `PregnancyContent`: validación, localización, fuentes bundle/cache y consultas por semana o
  timeline.
- `UltrasoundGallery`: identidad y persistencia de fotos de ecografía.
- `BellyTracking`: timeline, manifest, procesamiento de imágenes, settings y reglas de cadencia.
- `BabyProgressWidgetSupport`: snapshot inmutable y operación para cargarlo.
- `BabyLoadingDesignTokens`: tipografía, colores, espaciado, formas y elevación semánticos.
- `BabyLoadingDesignComponents`: componentes SwiftUI compartidos como `GradientBackground` y
  `SoftCard`.
- Cada feature posee su ViewModel, sus vistas, su estado de presentación y sus tests.
- El target host se limita al ciclo de vida, composition root, routing y shell de tabs.

## Persistencia compartida

- App Group: `group.com.pablo.BabyLoading`.
- Key compatible de preferencias: `lastPeriodDate`, gestionada con `AppPreferences`.
- `AppPreferences` no conoce el App Group ni keys de producto; la suite se inyecta desde
  `SharedAppGroup`.
- Ecografías: directorio `gallery/`, con identidad estable basada en el nombre de archivo.
- Seguimiento: `belly-tracking/manifest.json`, schema v1.
- Una captura guiada se guarda solo en `belly-tracking/`; no se duplica en `gallery/`.
- Las capturas nuevas preservan HEIC cuando la cámara lo permite. JPEG/JPG históricos siguen siendo
  compatibles.
- Antes del recorte central 9:16 se materializa la orientación EXIF.
- No existe API productiva para la antigua foto única; no añadir migración o purga runtime sin una
  decisión explícita.
- Cualquier cambio de keys, paths, schemas o formatos es cross-target y exige revisar app, widget y
  tests de contrato en el mismo cambio.

## Contenido semanal

- Fuentes base: `BabyLoading/Resources/pregnancy-content.en.json` y
  `BabyLoading/Resources/pregnancy-content.es.json`.
- Prioridad de lectura: bundle host válido -> cache histórica válida de solo lectura -> documento
  vacío del locale solicitado.
- La cache histórica usa `pregnancy-content.<locale>.json` en el App Group. No se escribe ni se
  elimina.
- No existe sincronización remota, refresh, ETag ni configuración de endpoints.
- `PregnancyContentDocument` decodifica y conserva `revision`; valida schema, locale, semanas únicas
  con cobertura completa `6...40` y `keyEvents` no vacíos.
- Los locales no soportados hacen fallback a inglés (`en`).
- No relajar validaciones para aceptar documentos incorrectos. Un cambio de schema requiere cambiar
  modelos, validación, recursos y tests juntos.

## Concurrencia

- App, `Coordinator`, `DependencyContainer`, router, ViewModels, modelo observable de cámara y
  timeline provider viven en `MainActor`.
- Stores y repositories con estado mutable son actors.
- El servicio de captura es un actor que serializa la sesión de AVFoundation.
- Use cases inmutables son structs `Sendable`.
- Los errores de persistencia se propagan con `throws`; los ViewModels los traducen a estados de UI
  tipados y conservan el último contenido válido cuando aplica.
- No recurrir a anotaciones de concurrencia inseguras ni silenciar fallos de persistencia.
- Evitar `Task` en Views cuando la responsabilidad corresponde a un ViewModel o al `Coordinator`.
- Si una decisión depende de concurrencia, deprecaciones o comportamiento actual de APIs Apple,
  validarla primero con la documentación oficial mediante MCP `cupertino`.

## UI, navegación y accesibilidad

- Tabs canónicas: dashboard, journey, gallery y settings.
- Cada tab mantiene su `NavigationStack`; no hay coordinadores por tab.
- La cámara se presenta desde `AppRouter` como destino full-screen.
- El visor y `AVCapturePhotoOutput` usan `AVCaptureDevice.RotationCoordinator` para alinear preview,
  captura, escala y orientación.
- Reutilizar primero tokens y componentes de `BabyLoadingDesignSystem`.
- Los textos visibles de app y widget viven en `Localizable.xcstrings`, actualmente en inglés y
  español.
- Conservar Dynamic Type, VoiceOver, contraste, targets táctiles y comportamiento con tecnologías
  asistivas. Cualquier decisión visual compartida exige actualizar `DESIGN.md` y Android.

## Widget

- `WidgetDependencyContainer` es un composition root independiente.
- Compone el grafo mínimo de infraestructura compartida, preferencias, localización, progreso,
  contenido y carga del snapshot; nunca crea navegación ni estado de presentación de la app.
- El entry es `BabyProgressWidgetEntry` y contiene un `BabyProgressWidgetSnapshot` inmutable.
- Los cambios de fecha o locale solicitan recarga mediante `WidgetReloader`.
- El timeline programa además una actualización cada hora.
- Si cambia el snapshot o cualquier contrato persistido, revisar juntos
  `WidgetDependencyContainer`, `BabyProgressTimelineProvider`, `BabyProgressWidgetEntry` y
  `BabyProgressWidgetEntryView`.

## Testing y calidad

- La cobertura unitaria vive junto al package propietario y usa Swift Testing.
- El target host conserva integración de composition root, recursos, frameworks y contratos
  compartidos: `CoordinatorIntegrationTests`, `SharedPersistenceContractTests`,
  `PregnancyContentResourceTests`, `BabySizeResourceTests` y `BabyLoadingTypographyTests`.
- Antes de tocar reglas de negocio, parsing, persistencia, cámara o widget, actualizar primero los
  tests de caracterización correspondientes.
- SwiftLint 0.65.1 está versionado en `Scripts/swiftlint/`; no sustituirlo por una instalación global.
- Una cámara física requiere validación manual de permisos, start/stop, cancelación, captura, HEIC,
  rotación de preview/captura y referencia superpuesta.

Comandos de verificación:

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

## Reglas de extensión

- Evitar introducir singletons, service locators ni estado global.
- No mover lógica de negocio o acceso a plataforma a las Views.
- Cuando una feature nueva necesite lógica o datos de negocio, debe exponer operaciones enfocadas
  desde Core, recibirlas en su ViewModel y ser compuesta por `Coordinator` sin depender de otra
  feature.
- Si una feature toca datos compartidos, probar app y widget en conjunto.
- No introducir dependencias externas sin una razón explícita y revisada.
- Mantener código, nombres, comentarios y mensajes de commit en inglés. Usar comentarios mínimos y
  solo cuando explican una decisión que el código no expresa.
- Mantener este documento sincronizado con cualquier cambio de arquitectura, targets, paquetes,
  persistencia, widget, concurrencia o estrategia de tests.
