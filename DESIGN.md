# Design System — Baby Loading

Este documento es el contrato visual compartido entre las aplicaciones Android e iOS de Baby Loading. Mantén las reglas comunes equivalentes en ambos repositorios; las tablas de implementación pueden nombrar APIs nativas distintas.

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

## Principios compartidos

- Diseña por **propósito semántico**, no por una aproximación visual ni por el nombre de un token de una plataforma.
- Un color de marca, uno de selección y uno de estado son conceptos distintos, aunque se perciban parecidos.
- Android e iOS comparten intención, jerarquía, contenido y accesibilidad; cada plataforma conserva sus controles y convenciones nativas.
- El fondo puede extenderse bajo las barras del sistema. El contenido legible, los controles y las imágenes informativas deben respetar sus áreas seguras.
- La app es solo clara. No se introduce modo oscuro ni color dinámico sin actualizar este contrato y ambos clientes.

## Paleta y semántica de color

Los valores hex son la referencia visual para revisión. Implementa los colores con tokens centrales o con la API semántica nativa indicada, nunca con literales repetidos dentro de una pantalla.

| Propósito | Referencia visual | Uso | Android | iOS |
| --- | --- | --- | --- | --- |
| Fondo superior | `#FFBFD1` | Inicio del degradado principal | `BabyGradientTop` | `GradientBackground.gradientTop` |
| Fondo inferior | `#C7B8F5` | Fin del degradado principal | `BabyGradientBottom` | `GradientBackground.gradientBottom` |
| Marca berry | `#9B405C` | Identidad persistente, no selección temporal | `BrandPink` / `colorScheme.primary` | Token de marca central cuando sea necesario |
| Acento de selección rosa | `#FF2D55` | Semana o día actual, selección activa, énfasis puntual | `BabyAccentPink` | `Color.pink` |
| Acento de selección violeta | Púrpura del sistema al 80 % | Extremo final de un gradiente de selección | `BabyAccentPurple.copy(alpha = 0.8f)` | `Color.purple.opacity(0.8)` |
| Superficie de tarjeta actual | `#FFFFFF` | Elemento actual o prioritario | `Color.White` | `Color.white` |
| Superficie de tarjeta secundaria | Blanco al 88 % | Elemento de contexto sobre el degradado | `Color.White.copy(alpha = 0.88f)` | `Color.white.opacity(0.88)` |
| Texto principal | `#211A1C` | Contenido legible de primera jerarquía | `colorScheme.onSurface` | `.primary` |
| Texto secundario | `#504347` | Metadatos y apoyo | `colorScheme.onSurfaceVariant` | `.secondary` |
| Separador y trazo pasivo | Blanco al 30–65 % | Línea temporal o borde no seleccionado sobre degradado | `Color.White.copy(alpha = …)` | `Color.white.opacity(…)` |
| Estado al día | Verde suave | Seguimiento cuya próxima captura aún no vence | `BabyStatusPositiveContainer` | `Color.green.opacity(0.18)` |
| Estado pendiente | Naranja suave | Seguimiento cuya próxima captura ya vence | `BabyStatusAttentionContainer` | `Color.orange.opacity(0.18)` |

### Reglas de color

- `BrandPink` y `Color.pink` no son intercambiables. El primero representa la identidad de Android; el segundo es el acento semántico compartido para una selección actual.
- No uses `colorScheme.primary`, `.tint`, `.accentColor` ni un color de marca como atajo para un propósito que tenga token propio.
- Los gradientes de estado actual usan, de izquierda a derecha, el acento rosa y el acento violeta. No sustituyas el violeta semántico por el lavanda de marca.
- La sombra de una tarjeta actual toma el acento rosa con 15 % de opacidad; las tarjetas no actuales no proyectan sombra de color.
- No se transmite significado solo mediante el color: el estado actual también debe incluir etiqueta, semántica seleccionada o ambos cuando corresponda.

## Espaciado, forma y elevación

La escala base es de 4 puntos. Evita valores locales si existe un token o un componente que exprese la misma relación.

| Token base | Valor | Uso típico |
| --- | --- | --- |
| Extra pequeño | 4 | Separación mínima y badge vertical |
| Pequeño | 8 | Separación entre grupos relacionados |
| Medio | 16 | Gutter, separación entre elementos principales y ancho de línea temporal |
| Grande | 24 | Padding de pantalla y agrupación de secciones |
| Extra grande | 32 | Separación de bloques destacados |

| Elemento compartido | Especificación |
| --- | --- |
| Tarjetas de la línea temporal | Radio continuo de 16; tarjeta actual blanca; tarjeta secundaria blanca al 88 %; sombra rosa al 15 %, radio 8, desplazamiento vertical 4 solo en la actual. |
| Línea temporal | Ancho 16; separación de 16 respecto a la tarjeta; línea blanca al 30 % de 2 puntos; marcadores pasivos blancos al 50–65 %. |
| Marcador de semana actual | Círculo rosa de 14 con borde blanco de 2; semanas no actuales usan círculo blanco al 50 % de 8. |
| Marcador de día actual | Círculo rosa de 7 con borde blanco de 1; los no actuales son de 4. |
| Imagen de tamaño del bebé | Contenedor circular de 40; recorte circular de 34; borde rosa al 20 % de 1.5. |
| Badge «Aquí estás» / «You are here» | Cápsula con gradiente de selección; texto blanco Bold de caption2; padding horizontal 10 y vertical 4. |

## Componentes, estados y accesibilidad

- Reutiliza el tema, las formas, las superficies y los tokens del sistema de diseño antes de definir constantes de feature.
- Una tarjeta estática no debe exponerse como botón ni tener chevrons. Si se habilita interacción, documenta el estado, la acción y la semántica en esta guía.
- Una tarjeta actual debe comunicarlo visualmente y mediante accesibilidad. En Android usa `selected`; en iOS el trait `.isSelected` y el valor localizado.
- Las imágenes decorativas se ocultan de accesibilidad. Las imágenes informativas requieren una descripción localizada.
- Respeta Dynamic Type en iOS y el escalado de texto del sistema en Android; no bloquees el tamaño de fuentes en pantallas de app.
- Mantén contraste legible entre texto y superficie. La selección rosa se acompaña de una etiqueta o semántica, nunca solo color.
- Los objetivos interactivos respetan el mínimo recomendado por cada plataforma. Los encabezados se marcan como tales y siguen una jerarquía consistente.

## Gobernanza y sincronización entre plataformas

1. Define o revisa primero el propósito visual: color, tipografía, espaciado, forma, estado y accesibilidad.
2. Añade el mapeo Android e iOS en la misma edición. Si una plataforma no tiene todavía token, créalo en su sistema de diseño; no reutilices uno parecido.
3. Implementa con tokens o componentes centrales, nunca con literales de pantalla salvo valores documentados de un componente.
4. Valida la vista en ambas plataformas antes de cerrar el cambio.
5. Mantén `DESIGN.md` equivalente en los dos repositorios. Los cambios de iOS se realizan en una rama propia y los de Android respetan los cambios locales existentes.

Cuando exista una discrepancia entre una captura y el código, consulta el código de la otra plataforma para identificar el propósito antes de ajustar valores. Las capturas sirven para validar; no sustituyen este contrato.
