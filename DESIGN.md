# Guía de diseño — Baby Loading iOS

Este documento es la fuente de verdad para todo texto de producto, componentes y widgets.

## Tipografía

Toda interfaz propia usa **Nunito Sans**, incluida la app y `BabyProgressWidgetExtension`. El origen es el repositorio oficial Google Fonts/Nunito Sans; la versión queda fijada al commit [`058bd7a2f33d6ad5ef1df985b3db403622016a8c`](https://github.com/googlefonts/NunitoSans/tree/058bd7a2f33d6ad5ef1df985b3db403622016a8c), bajo SIL Open Font License 1.1. Sus hashes SHA-256 son:

- Romana: `f934d7142fb4784bf828da485b7dcbd90c0c80d514e9d49a5da0ed3a1ae2491d`
- Cursiva: `d9d5db18f3c11221a4fbb553cbc709391c1179964c7eaa4466ef43c78aa4492f`

Los ficheros y su licencia viven en `BabyLoading/Resources/Fonts/`. Cualquier fuente nueva debe añadirse a los targets `BabyLoading` y `BabyProgressWidgetExtension`, registrarse en ambos bundles y verificarse en el test de tipografía.

| Uso | Peso | API SwiftUI |
| --- | --- | --- |
| Texto largo y ayuda | 400 Regular | `BabyLoadingTypography.text(.body)` |
| Texto secundario y metadatos | 400 Regular | `.subheadline`, `.footnote`, `.caption` |
| Botones y controles | 600 SemiBold | `text(.headline, weight: .semibold)` |
| Títulos de sección y pantalla | 700 Bold | `text(.title3/.title2/.largeTitle, weight: .bold)` |
| Cifras o hitos protagonistas | 800 ExtraBold | `text(..., weight: .extraBold)` o `widget(..., weight: .extraBold)` |

## Cómo construir una pantalla

- Usa siempre `BabyLoadingTypography.text(_:weight:italic:)` para texto de app. No llames a `Font.custom`, `.system(..., design: .rounded)` ni `.fontWeight` directamente.
- El helper conserva Dynamic Type usando el `Font.TextStyle` indicado. Elige el rol semántico y deja que SwiftUI escale el tamaño.
- En widgets usa `BabyLoadingTypography.widget(size:weight:italic:)` solo cuando el espacio fijo del widget requiera una medida concreta.
- Para énfasis editorial usa `italic: true`, que selecciona una variante itálica real. No uses `.italic()` ni oblicua sintética.
- Permite que el texto informativo ocupe varias líneas; usa `lineLimit` solo en etiquetas compactas y con un `minimumScaleFactor` razonable cuando sea necesario.
- Mantén contraste suficiente, tamaño táctil adecuado y los modificadores de accesibilidad existentes. No compenses una falta de contraste aumentando el peso. Emoji, SF Symbols y controles gestionados por el sistema conservan su fuente nativa.
- No uses ExtraBold fuera de una cifra o hito principal, ni más de dos pesos en el mismo componente. Medium (500) se reserva para metadatos compactos; no sustituye a SemiBold en controles ni a Bold en títulos.

## Equivalencias y ejemplos

| Propósito | Android Material 3 | iOS SwiftUI | Peso |
| --- | --- | --- | --- |
| Título de pantalla | `headlineLarge` | `.largeTitle` | 700 Bold |
| Título de componente | `titleLarge` | `.title3` | 700 Bold |
| Cuerpo informativo | `bodyLarge` | `.body` | 400 Regular |
| Control o acción | `labelLarge` | `.headline` | 600 SemiBold |
| Metadato | `bodySmall` | `.caption` | 400 Regular |
| Cifra protagonista | `displaySmall` | `widget(size:weight:)` | 800 ExtraBold |

Pantalla:

```swift
Text("dashboard.title")
    .font(BabyLoadingTypography.text(.title2, weight: .bold))
```

Componente reutilizable:

```swift
Text("component.action")
    .font(BabyLoadingTypography.text(.headline, weight: .semibold))
```

Widget:

```swift
Text("28")
    .font(BabyLoadingTypography.widget(size: 28, weight: .extraBold))
```

Énfasis editorial:

```swift
Text("editorial.note")
    .font(BabyLoadingTypography.text(.body, italic: true))
```

## Correspondencia con Android

iOS y Android comparten Nunito Sans y la jerarquía Regular → SemiBold → Bold → ExtraBold. No fuerces puntos idénticos entre plataformas: iOS conserva Dynamic Type y Android los roles de Material 3. Al implementar una vista equivalente, asigna el mismo propósito de texto y usa el rol nativo correspondiente.
