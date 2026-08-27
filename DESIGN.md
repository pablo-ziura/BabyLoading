# Design System — Baby Loading

This document is the shared visual contract between the Android and iOS Baby Loading applications.
Keep common rules equivalent in both repositories; implementation tables may name different native APIs.

## Typography

Every custom interface uses **Nunito Sans**, including the app and \`BabyProgressWidgetExtension\`.
The source is the official Google Fonts/Nunito Sans repository; the version is pinned to commit
[\`058bd7a2f33d6ad5ef1df985b3db403622016a8c\`](https://github.com/googlefonts/NunitoSans/tree/058bd7a2f33d6ad5ef1df985b3db403622016a8c),
under the SIL Open Font License 1.1. Its SHA-256 hashes are:

- Roman: \`f934d7142fb4784bf828da485b7dcbd90c0c80d514e9d49a5da0ed3a1ae2491d\`
- Italic: \`d9d5db18f3c11221a4fbb553cbc709391c1179964c7eaa4466ef43c78aa4492f\`

The files and their license live in \`BabyLoading/Resources/Fonts/\`. Any new font must be added to
the \`BabyLoading\` and \`BabyProgressWidgetExtension\` targets, registered in both bundles, and
verified by the typography test.

| Usage | Weight | SwiftUI API |
| --- | --- | --- |
| Long-form and help text | 400 Regular | \`BabyLoadingTypography.text(.body)\` |
| Secondary text and metadata | 400 Regular | \`.subheadline\`, \`.footnote\`, \`.caption\` |
| Buttons and controls | 600 SemiBold | \`text(.headline, weight: .semibold)\` |
| Section and screen titles | 700 Bold | \`text(.title3/.title2/.largeTitle, weight: .bold)\` |
| Prominent figures or milestones | 800 ExtraBold | \`text(..., weight: .extraBold)\` or \`widget(..., weight: .extraBold)\` |

## Building a screen

- Always use \`BabyLoadingTypography.text(_:weight:italic:)\` for app text. Do not call
  \`Font.custom\`, \`.system(..., design: .rounded)\`, or \`.fontWeight\` directly.
- The helper preserves Dynamic Type using the stated \`Font.TextStyle\`. Choose the semantic role
  and let SwiftUI scale the size.
- In widgets, use \`BabyLoadingTypography.widget(size:weight:italic:)\` only when the fixed widget
  space requires a specific size.
- For editorial emphasis, use \`italic: true\`, which selects a true italic variant. Do not use
  \`.italic()\` or synthetic oblique.
- Allow informative text to span multiple lines; use \`lineLimit\` only for compact labels and with a
  reasonable \`minimumScaleFactor\` when needed.
- Maintain sufficient contrast, appropriate touch size, and existing accessibility modifiers. Do not
  compensate for insufficient contrast by increasing the weight. Emoji, SF Symbols, and
  system-managed controls retain their native font.
- Do not use ExtraBold outside a primary figure or milestone, nor more than two weights within the
  same component. Medium (500) is reserved for compact metadata; it does not replace SemiBold in
  controls or Bold in titles.

## Equivalences and examples

| Purpose | Android Material 3 | iOS SwiftUI | Weight |
| --- | --- | --- | --- |
| Prominent Home title | \`headlineLarge\` | \`.largeTitle\` | 700 Bold |
| Top-level screen title | \`titleLarge\` | \`.title2\` | 700 Bold |
| Component title | \`titleLarge\` | \`.title3\` | 700 Bold |
| Informative body | \`bodyLarge\` | \`.body\` | 400 Regular |
| Control or action | \`labelLarge\` | \`.headline\` | 600 SemiBold |
| Metadata | \`bodySmall\` | \`.caption\` | 400 Regular |
| Prominent figure | \`displaySmall\` | \`widget(size:weight:)\` | 800 ExtraBold |

Screen:

\`\`\`swift
Text("dashboard.title")
    .font(BabyLoadingTypography.text(.title2, weight: .bold))
\`\`\`

Reusable component:

\`\`\`swift
Text("component.action")
    .font(BabyLoadingTypography.text(.headline, weight: .semibold))
\`\`\`

Widget:

\`\`\`swift
Text("28")
    .font(BabyLoadingTypography.widget(size: 28, weight: .extraBold))
\`\`\`

Editorial emphasis:

\`\`\`swift
Text("editorial.note")
    .font(BabyLoadingTypography.text(.body, italic: true))
\`\`\`

## Android alignment

iOS and Android share Nunito Sans and the Regular → SemiBold → Bold → ExtraBold hierarchy. Do not
force identical point values across platforms: iOS retains Dynamic Type and Android retains Material 3
roles. When implementing an equivalent view, assign the same text purpose and use the corresponding
native role.

## Shared principles

- Design by **semantic purpose**, not visual approximation or the name of a platform token.
- A brand color, a selection color, and a status color are different concepts, even when they appear
  similar.
- Android and iOS share intent, hierarchy, content, and accessibility; each platform retains its
  native controls and conventions.
- The background may extend beneath system bars. Readable content, controls, and informative images
  must respect their safe areas.
- The app is light-only. Do not introduce dark mode or dynamic color without updating this contract
  and both clients.

## Color palette and semantics

Hex values are the visual reference for review. Implement colors with central tokens or the indicated
native semantic API, never with literals repeated within a screen.

| Purpose | Visual reference | Usage | Android | iOS |
| --- | --- | --- | --- | --- |
| Top background | \`#FFBFD1\` | Start of the main gradient | \`BabyGradientTop\` | \`GradientBackground.gradientTop\` |
| Bottom background | \`#C7B8F5\` | End of the main gradient | \`BabyGradientBottom\` | \`GradientBackground.gradientBottom\` |
| Berry brand | \`#9B405C\` | Persistent identity, not temporary selection | \`BrandPink\` / \`colorScheme.primary\` | Central brand token when needed |
| Pink selection accent | \`#FF2D55\` | Current week or day, active selection, focused emphasis | \`BabyAccentPink\` | \`Color.pink\` |
| Purple selection accent | System purple at 80% | Ending edge of a selection gradient | \`BabyAccentPurple.copy(alpha = 0.8f)\` | \`Color.purple.opacity(0.8)\` |
| Current card surface | \`#FFFFFF\` | Current or priority element | \`Color.White\` | \`Color.white\` |
| Secondary card surface | White at 88% | Context element over the gradient | \`Color.White.copy(alpha = 0.88f)\` | \`Color.white.opacity(0.88)\` |
| Primary text | \`#211A1C\` | First-hierarchy readable content | \`colorScheme.onSurface\` | \`.primary\` |
| Secondary text | \`#504347\` | Metadata and supporting text | \`colorScheme.onSurfaceVariant\` | \`.secondary\` |
| Separator and passive stroke | White at 30–65% | Timeline line or unselected border over the gradient | \`Color.White.copy(alpha = …)\` | \`Color.white.opacity(…)\` |
| Up-to-date status | Soft green | Tracking whose next capture is not yet due | \`BabyStatusPositiveContainer\` | \`Color.green.opacity(0.18)\` |
| Pending status | Soft orange | Tracking whose next capture is due | \`BabyStatusAttentionContainer\` | \`Color.orange.opacity(0.18)\` |

### Color rules

- \`BrandPink\` and \`Color.pink\` are not interchangeable. The former represents Android identity;
  the latter is the shared semantic accent for a current selection.
- Do not use \`colorScheme.primary\`, \`.tint\`, \`.accentColor\`, or a brand color as a shortcut for
  a purpose with its own token.
- Current-state gradients use, from left to right, the pink accent and purple accent. Do not replace
  the semantic purple with the brand lavender.
- The shadow of a current card uses the pink accent at 15% opacity; non-current cards do not cast a
  colored shadow.
- Do not convey meaning through color alone: the current state must also include a label, selected
  semantics, or both as appropriate.

## Spacing, shape, and elevation

The base scale is 4 points. Avoid local values when a token or component expresses the same
relationship.

| Base token | Value | Typical usage |
| --- | --- | --- |
| Extra small | 4 | Minimum spacing and vertical badge padding |
| Small | 8 | Spacing between related groups |
| Medium | 16 | Gutter, spacing between primary elements, and timeline width |
| Large | 24 | Screen padding and section grouping |
| Extra large | 32 | Spacing between highlighted blocks |

| Shared element | Specification |
| --- | --- |
| Timeline cards | Continuous 16 radius; current card white; secondary card white at 88%; pink shadow at 15%, 8 radius, 4 vertical offset on the current card only. |
| Timeline | 16 width; 16 spacing from the card; 2-point white line at 30%; passive markers white at 50–65%. |
| Current week marker | 14 pink circle with 2 white border; non-current weeks use an 8 circle at 50% white. |
| Current day marker | 7 pink circle with 1 white border; non-current markers are 4. |
| Baby-size image | 40 circular container; 34 circular crop; 1.5 pink border at 20%. |
| “You are here” badge | Capsule with selection gradient; white Bold caption2 text; 10 horizontal and 4 vertical padding. |
| Dashboard metric cards | Cards in the same metric row align icon, figure, and label into matching vertical bands. The label reserves 48 points before the shared `SoftCard` inset and may grow with text scaling. |
| Late-term and postterm notice | Reuse the secondary `SoftCard` surface with a Bold title, Regular explanatory text, and the relation to the estimated due date. It is informational, not interactive, and must not reuse fetal-size imagery or a progress ring. |

## Components, states, and accessibility

- Reuse the design system's theme, shapes, surfaces, and tokens before defining feature constants.
- A static card must not be exposed as a button or have chevrons. If interaction is enabled,
  document its state, action, and semantics in this guide.
- A current card must communicate its state visually and through accessibility. On Android, use
  \`selected\`; on iOS, the \`.isSelected\` trait and the localized value.
- Decorative images are hidden from accessibility. Informative images require a localized
  description.
- Do not use emoji as decorative text. Use original, untinted raster illustrations with transparent
  backgrounds; keep them pastel, softly rounded, and secondary to the adjacent localized text.
- Respect Dynamic Type on iOS and system text scaling on Android; do not lock font sizes on app
  screens.
- Keep text and surface contrast readable. The pink selection is accompanied by a label or
  semantics, never color alone.
- Interactive targets respect each platform's recommended minimum. Headers are marked as such and
  follow a consistent hierarchy.
- When the pregnancy is late term (41+0 to 41+6) or postterm (42+0 and beyond), show the same
  informational state on iOS and Android: phase label and the relation to the estimated due date.
  The widget also uses the estimated due date terminology in its compact layout and directs the
  user to review the date in the app.

## Governance and cross-platform synchronization

1. First define or review the visual purpose: color, typography, spacing, shape, state, and
   accessibility.
2. Add Android and iOS mapping in the same edit. If a platform does not yet have a token, create it
   in its design system; do not reuse a similar one.
3. Implement with central tokens or components, never screen literals except documented component
   values.
4. Validate the view on both platforms before closing the change.
5. Keep \`DESIGN.md\` equivalent in both repositories. iOS changes are made on a dedicated branch,
   and Android changes preserve existing local changes.

When a screenshot and code disagree, consult the other platform's code to identify the purpose before
adjusting values. Screenshots are for validation; they do not replace this contract.
