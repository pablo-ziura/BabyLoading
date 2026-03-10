# AGENTS.md

Documento vivo para cualquier agente que trabaje en `BabyLoading`.
Leer este archivo antes de proponer cambios o tocar codigo.

## Resumen del proyecto

- App iOS nativa en SwiftUI con target principal `BabyLoading`, target de widget `BabyProgressWidget` y target de tests `BabyLoadingTests`.
- Stack actual: Swift 6.0, Observation (`@Observable`), SwiftUI NavigationStack, WidgetKit, App Group compartido y un paquete local `Packages/AppNetwork`.
- Deployment target actual: iOS 26.2.
- Simulador de referencia para builds y tests locales: `iPhone 17 Pro` con `iOS 26.2`.
- El proyecto esta en una fase activa de evolucion alrededor de contenido de embarazo remoto/cacheado. No asumas que todo lo nuevo esta estabilizado todavia.

## Estructura real del codebase

- `BabyLoading/App`
  Punto de entrada, DI manual, coordinacion de tabs y fabricas de vistas.
- `BabyLoading/Domain`
  Logica de negocio pura y tipos de dominio como `PregnancyCalculator` y `BabySize`.
- `BabyLoading/Data`
  Persistencia local, acceso a App Group, repositorios y modelo del documento JSON de contenido semanal.
- `BabyLoading/Presentation`
  ViewModel principal, vistas SwiftUI, componentes compartidos y navegacion.
- `BabyProgressWidget`
  Timeline provider, entry y vista del widget. Reusa `DependencyContainer.shared`.
- `BabyLoadingTests`
  Mezcla de `Testing` y `XCTest`.
- `Packages/AppNetwork`
  Paquete Swift local con `NetworkClient` actor y tests propios. Existe en el workspace, pero hoy no se ve usado desde los targets principales.

## Arquitectura y flujo de datos

- La app sigue una separacion simple por capas: `Presentation -> Repository -> Data/Domain`.
- La composicion se hace en `DependencyContainer.shared`.
- El estado principal de UI vive en `BabyProgressViewModel`, marcado como `@Observable` y `@MainActor`.
- No introducir `ObservableObject` ni `@Published` salvo que haya una razon fuerte y consistente con codigo existente.
- La navegacion por tabs vive en `AppCoordinator` con un `NavigationPath` por tab.
- Las vistas se crean desde `DependencyContainer+ViewFactory.swift`. Si una nueva pantalla necesita dependencias, enchufarla ahi antes de crear accesos directos desde la vista.

## Persistencia y datos compartidos

- El App Group actual es `group.com.pablo.BabyLoading`.
- `BabyProgressDataSource` guarda:
  `lastPeriodDate` en `UserDefaults(suiteName:)`.
- `BabyProgressDataSource` guarda tambien:
  foto legacy unica en archivo `user_photo.jpg`.
- `BabyProgressDataSource` guarda tambien:
  galeria multi-foto en el directorio `gallery/` del contenedor compartido.
- El widget depende de este almacenamiento compartido. Cualquier cambio de keys, nombres de archivo o ubicacion debe considerarse un cambio cross-target.

## Contenido semanal del embarazo

- Las fuentes base son `BabyLoading/Resources/pregnancy-content.en.json`
  y `BabyLoading/Resources/pregnancy-content.es.json`.
- Los tipos de contenido viven en `BabyLoading/Data/Content/` separados por responsabilidad:
  modelos, sources, stores, repositorios y extensiones.
- La resolución de locale del contenido vive en `BabyLoading/Data/Content/Localization/`
  y hace fallback a `en` cuando el idioma del dispositivo no está soportado.
- Los protocolos de contenido se mantienen junto a la implementación concreta de su capa,
  no en una carpeta global de `Protocols`.
- `PregnancyContentDocument` valida:
  `schemaVersion`, `locale`, `revision`, cobertura completa de semanas 6...40 y ausencia de `keyEvents` vacios.
- `PregnancyContentRepository` resuelve el snapshot inicial con esta prioridad:
  cache del App Group -> bundle -> `.empty`.
- La actualizacion remota es opcional y depende de `INFOPLIST_KEY_PregnancyContentURL`
  o de `INFOPLIST_KEY_PregnancyContentURLTemplate` con placeholder `{locale}`.
- Si `PregnancyContentURL` esta vacia, la sincronizacion remota queda desactivada.
- La cache compartida guarda JSON, `ETag`, `lastFetchAt` y `revision`.
- La cache compartida se separa por locale para no mezclar snapshots de idiomas distintos.
- No bypasses las validaciones del documento para "hacer que funcione". Si cambia el schema, hay que actualizar validacion, tests y recurso base.

## Concurrencia

- El proyecto ya usa Swift 6 y aislamiento explicito con `@MainActor`.
- `BabyProgressViewModel`, `DependencyContainer` y `BabyProgressTimelineProvider` estan atados al main actor.
- Si tocas aislamiento, `Sendable` o APIs async de Apple, valida antes con la documentacion oficial usando MCP `cupertino`.
- Evita lanzar `Task` sin necesidad desde vistas si la responsabilidad puede vivir en ViewModel o repositorio.

## UI y navegacion

- El shell de navegacion actual es `MainTabView`.
- Tabs actuales:
  dashboard, journey, gallery, settings.
- Mantener la seleccion y los stacks por tab en `AppCoordinator`.
- Reutilizar los componentes comunes de `Presentation/Common` antes de crear nuevos wrappers visuales.
- La app esta forzada a `.preferredColorScheme(.light)`. No introducir dark mode parcial sin una decision explicita del proyecto.
- Los textos visibles de app y widget viven en `Localizable.xcstrings` (`en` y `es` por ahora).

## Widget

- El widget lee el mismo repositorio que la app a traves de `DependencyContainer.shared`.
- `WidgetReloader` se dispara cuando cambia la fecha o cuando el contenido remoto cambia de snapshot.
- Si modificas el contrato de datos que consume el widget, revisar siempre:
  `BabyProgressTimelineProvider`,
  `SimpleEntry`,
  `BabyProgressWidgetEntryView`.

## Networking

- Hay un paquete local `AppNetwork` con `NetworkClientProtocol` y `NetworkClient` actor.
- El fetch remoto de contenido semanal hoy usa `URLSession` directamente desde `RemoteContentSource`.
- Si el proyecto migra mas llamadas HTTP, preferir una decision consistente:
  o seguir con `URLSession` simple para este caso,
  o converger hacia `AppNetwork` en vez de crear una tercera abstraccion.

## Testing

- Hay tests tanto con `import Testing` como con `XCTest`.
- Antes de tocar reglas de negocio, repositorios, parsing JSON o widget data, anadir o actualizar tests.
- Zonas con cobertura relevante:
  `PregnancyCalculatorTests`,
  `BabyLoadingRepositoryTests`,
  `BabyLoadingViewModelTests`,
  `PregnancyContentDocumentTests`,
  `PregnancyContentRepositoryTests`,
  `PregnancyContentResourceTests`,
  `BabySizeResourceTests`.
- El paquete `AppNetwork` tiene tests aislados en `Packages/AppNetwork/Tests/AppNetworkTests`.

## Reglas de extension para agentes

- Antes de cambiar arquitectura, primero seguir el flujo actual y extenderlo con minima friccion.
- No crear singletons nuevos. La composicion central actual ya vive en `DependencyContainer.shared`.
- No mover logica de negocio a las vistas.
- No duplicar acceso a App Group fuera de `SharedAppGroup` o `BabyProgressDataSource` salvo que haya una necesidad clara de nueva abstraccion.
- No introducir dependencias externas sin una razon fuerte. El proyecto actual vive casi entero sobre frameworks nativos y un paquete local.
- Si agregas una nueva feature:
  definir dominio si aplica,
  exponerla via repositorio,
  inyectarla desde `DependencyContainer`,
  probarla en app y widget si toca datos compartidos.
- Si una decision depende de comportamiento actual de APIs Apple, deprecaciones o restricciones de WidgetKit/SwiftUI, validar con MCP `cupertino` antes de responder o implementar.

## Comandos utiles

- Abrir proyecto:
  `open /Users/pablo.ruiz.local/Documents/XCode/BabyLoading/BabyLoading.xcodeproj`
- Build app en el simulador de referencia:
  `xcodebuild -project /Users/pablo.ruiz.local/Documents/XCode/BabyLoading/BabyLoading.xcodeproj -scheme BabyLoading -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2' build`
- Ejecutar tests principales:
  `xcodebuild test -project /Users/pablo.ruiz.local/Documents/XCode/BabyLoading/BabyLoading.xcodeproj -scheme BabyLoadingTests -testPlan BabyLoadingTests -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2'`
- Ejecutar tests del paquete local:
  `swift test --package-path /Users/pablo.ruiz.local/Documents/XCode/BabyLoading/Packages/AppNetwork`

## Notas de mantenimiento

- Este archivo debe actualizarse cuando cambie la arquitectura, el App Group, el origen del contenido remoto, los targets o las reglas de test.
- Si encuentras una discrepancia entre este documento y el codigo, prioriza el codigo y corrige este archivo en la misma tarea si tiene sentido.
