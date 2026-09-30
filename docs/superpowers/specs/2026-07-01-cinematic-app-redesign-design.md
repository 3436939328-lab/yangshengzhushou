# Cinematic App Redesign Design

## Goal

Upgrade the HarmonyOS wellness assistant UI across all visible APP pages so it feels coherent, polished, cinematic, and aligned with the health and wellness theme.

The redesign must preserve the current app architecture, role routing, data flow, and page capabilities. It should improve visual quality and motion without changing backend contracts or navigation semantics.

## Design Read

This is a multi-role health and wellness APP for normal users, doctors, and administrators. The chosen direction is "night herbal cinematic": dark ink-green surfaces, warm amber highlights, herbal green identity accents, layered translucent cards, and calm motion.

User-facing pages should feel immersive and reassuring. Doctor and administrator pages should keep higher information clarity while sharing the same visual language.

## Current State

- APP entry point: `entry/src/main/ets/pages/Index.ets`.
- Global surface components:
  - `entry/src/main/ets/components/AppHeader.ets`
  - `entry/src/main/ets/components/TabBar.ets`
  - `entry/src/main/ets/components/cards/CommonCards.ets`
- Theme tokens live in `entry/src/main/ets/theme/WellnessTheme.ets`.
- Main tabs are split by role through `RoleExperienceService.ets`.
- Existing pages are mostly light green backgrounds, white cards, small green chips, and repeated section blocks.

The current UI is readable but visually flat. The main redesign opportunity is to create a stronger shared theme layer and reuse it across pages rather than styling each page independently.

## Visual System

### Palette

Replace the light-only palette with a cinematic wellness palette:

- Page background: deep ink green.
- Elevated surfaces: dark herbal glass and warm translucent panels.
- Primary accent: herbal green, used for success, selected states, and healthy signals.
- Warm accent: amber copper, used for risk, reminders, and cinematic highlights.
- Text: warm near-white for dark surfaces, muted sage for secondary copy.
- Lines: low-contrast translucent borders.

The existing constants in `WellnessTheme.ets` should be expanded instead of scattering raw colors through each page.

### Shape And Depth

- Use one radius system across the APP:
  - Main cards: 18.
  - Pills and chips: 999-style rounded via high radius values.
  - Inputs and message bubbles: 16.
- Add subtle border and shadow tokens for glass-like card separation.
- Avoid nested card clutter. Use spacing, section headers, and translucent dividers to group related content.

### Typography

- Keep the platform default font stack.
- Increase hierarchy contrast:
  - APP title and hero metrics become larger and bolder.
  - Section titles gain a small accent rail or glow marker.
  - Dense doctor/admin rows stay compact but use clearer labels and status tags.
- Do not rewrite core business copy as part of this redesign, except where layout requires shorter labels.

## Motion System

Use ArkUI native animation patterns that are cheap and predictable:

- Page and tab content: fade in with a slight upward move.
- Cards: subtle staggered entrance where feasible.
- Buttons and chips: press feedback with scale or opacity.
- Tab bar: selected item becomes a glowing capsule, with text color and indicator transition.
- Chat panel: sending state uses a soft pulsing button or status line.
- Metric bars: grow from a low height to the target height on appearance where supported.

Reduced-motion support should be respected where the platform API makes it practical. Motion must support hierarchy and feedback, not distract from health information.

## Page Scope

### Authentication And Guide

Upgrade `AuthView` and `GuideView` so first launch already matches the cinematic APP:

- Deep background with radial light blooms.
- Login/register panels use translucent elevated surfaces.
- Primary action buttons use herbal green with warm highlight.
- Guide slides use full-screen cinematic composition rather than plain cards.

### Main Shell

Upgrade `Index.ets`, `AppHeader.ets`, and `TabBar.ets`:

- Main background changes to the new deep theme.
- Header becomes a layered status header with title, subtitle, risk pill, and soft bottom glow.
- Content scroll keeps existing tab routing.
- Bottom tab bar becomes a floating cinematic navigation surface.

### User Pages

Upgrade these tabs with stronger emotional design:

- Home: make weather and daily state the hero moment, then plans and quick actions become layered cards.
- Assistant: make chat bubbles, input, source status, questionnaire, and knowledge cards match the dark wellness language.
- Data: make risk summary and metrics feel like a health dashboard with animated bars and clearer status treatments.
- Profile: make records, privacy, indicators, and action groups feel cohesive with the same cards and chips.
- Consultation: make thread list and chat panels use the same message bubble and status styling.

### Doctor Pages

Doctor pages should share the night theme but favor clarity:

- Workbench summary cards use compact metric blocks.
- Consultation list and message panels prioritize scan speed.
- Doctor profile fields use stronger input contrast and professional status tags.

### Admin Pages

Admin pages should become a dark professional console:

- Overview metrics use compact elevated cards.
- People, assistant logs, and consultations use dark list rows with clear filters, status chips, and selected-detail panels.
- Preserve existing admin capabilities and role labels.

## Component Strategy

Add or expand shared builders and constants rather than duplicating style blocks:

- `WellnessTheme.ets`: add cinematic tokens.
- `CommonCards.ets`: add shared section title, chip, surface, and status treatment helpers where ArkUI builder functions fit naturally.
- Existing page files should use those tokens and helpers.

Avoid introducing new dependencies. The current ArkTS/HarmonyOS project has no UI package dependencies and should remain dependency-light.

## Data Flow

No data model or API behavior changes are required.

- Auth session handling remains in `AuthService.ets`.
- Role-based routing remains in `RoleExperienceService.ets`.
- Weather, suggestions, health data, consultation, profile, doctor, and admin services continue as-is.
- Redesign changes should be UI-only unless a small view-state variable is needed for animation.

## Error, Empty, And Loading States

Existing `LoadStateNotice` and `EmptyStateBlock` should be visually upgraded:

- Loading/checking auth uses the deep background and cinematic title treatment.
- Empty states use a quiet illustrated-style text block made from native shapes, not external assets.
- Error notices use warm amber surfaces with readable contrast.

## Accessibility And Readability

- Keep health content legible on dark backgrounds.
- Do not use low-contrast amber text for long paragraphs.
- Important warnings use warm accent plus readable body text.
- Buttons must have readable text in enabled and disabled states.
- Dense admin/doctor screens should avoid overly decorative effects.

## Verification Plan

After implementation:

1. Run available ArkTS/Hvigor tests.
2. Run available build command.
3. Search changed files for obvious syntax mistakes and excessive raw color duplication.
4. Inspect key files for consistent token usage.
5. If device or emulator preview is not available in this environment, state that limitation clearly.

## Out Of Scope

- Backend API changes.
- Route or role model changes.
- New third-party UI dependencies.
- Rewriting app business copy.
- Adding network-loaded images or web assets.

## Implementation Slice

The first implementation should focus on global visual leverage:

1. Expand `WellnessTheme.ets`.
2. Upgrade `AppHeader.ets`, `TabBar.ets`, `CommonCards.ets`, `LoadStateNotice.ets`, and `EmptyStateBlock.ets`.
3. Apply the new surfaces and motion to `Index.ets`, `HomeTab.ets`, `AssistantTab.ets`, and `DataTab.ets`.
4. Extend the same style rules to profile, consultation, doctor, and admin tabs.
5. Verify with build/test commands where available.
