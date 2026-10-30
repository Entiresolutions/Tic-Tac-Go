# Design System & UI Specification - Tic Tac GO

## 1. Visual Theme & Aesthetic Philosophy
**Tic Tac GO** (powered by Entire Solution) adheres to a unified dual-theme visual system:
1. **Neo-Blue Strategic Minimalist (Light Theme)**: Crisp white canvas, rich royal and electric blues, soft depth bevels, clean borders, and high legibility.
2. **Deep Navy Cybernetic Gaming (Dark Theme)**: Immersive midnight navy backgrounds (`#0B1220`), elevated slate surfaces (`#111C2E` / `#17243A`), high-contrast dark board field (`#152238`), and vibrant electric neon-blue highlights (`#3B82F6`).

The visual language emphasizes distraction-free local gameplay, large legible touch targets, smooth interactive feedback, high-contrast player indicators, and immediate theme switching without application restarts.

---

## 2. Color Palette & Theming Tokens

### 2.1 Dual-Theme Core Tokens

| Token Name | Light Theme Value | Dark Theme Value | Purpose |
| :--- | :--- | :--- | :--- |
| `primary` | `#2563EB` | `#3B82F6` | Interactive buttons, active toggles, brand highlights |
| `primaryLight` | `#3B82F6` | `#60A5FA` | Hover states, secondary accents |
| `primaryDark` | `#1D4ED8` | `#1D4ED8` | Button bevel edges, pressed depths |
| `deepBlue` | `#1E40AF` | `#1D4ED8` | App bar headers, gradient transitions |
| `scaffoldBackground` | `#F9FAFB` | `#0B1220` | Fullscreen background canvas |
| `surface` | `#FFFFFF` | `#111C2E` | Card containers, modal dialogs, menu panels |
| `surfaceSecondary` | `#F1F5F9` | `#17243A` | Stat pills, secondary elevated sections |
| `surfaceMuted` | `#E2E8F0` | `#1E2D47` | Subtle backdrops, disabled track backgrounds |
| `border` | `#E5E7EB` | `#334155` | Subtle item dividers, container outlines |
| `borderDark` | `#CBD5E1` | `#475569` | High-definition card contours |
| `boardSurface` | `#FFFFFF` | `#152238` | Main $7 \times 7$ board grid field |
| `boardBorder` | `#E5E7EB` | `#334155` | Outer board border and grid lines |
| `cellBackground` | `#FFFFFF` | `#17243A` | Individual stone cell background |
| `cellHover` | `#F8FAFC` | `#1E2D47` | Cursor hover & touch pre-highlight |
| `textPrimary` | `#0F172A` | `#F8FAFC` | High-contrast main headings and active labels |
| `textSecondary` | `#64748B` | `#94A3B8` | Subtitles, helper text, and secondary stats |
| `textMuted` | `#94A3B8` | `#64748B` | Placeholder labels, timestamp counters |
| `buttonBevel` | `#1E40AF` | `#1D4ED8` | 3D physical tactile push bevel depth |
| `buttonWhiteBevel` | `#E2E8F0` | `#1E293B` | White / surface button tactile push bevel |
| `shadowSubtle` | `#0F0F172A` (6%) | `#33000000` (20%) | Card and button baseline drop shadows |
| `shadowMedium` | `#1A0F172A` (10%) | `#4D000000` (30%) | Elevated board and dialog shadow depth |

### 2.2 Invariant Identity & Status Tokens (Both Themes)

- **Player 'X' (Cobalt Royal Blue)**:
  - Primary Gradient: `#1D4ED8` $\to$ `#60A5FA`
  - Solid Badge: `#2563EB`
  - Text Character: Pure White (`#FFFFFF`)
  - Glow Bloom: `rgba(29, 78, 216, 0.25)`
- **Player 'O' (Coral Crimson Red)**:
  - Primary Gradient: `#B91C1C` $\to$ `#F87171`
  - Solid Badge: `#DC2626`
  - Text Character: Pure White (`#FFFFFF`)
  - Glow Bloom: `rgba(220, 38, 38, 0.25)`
- **Winning Streak Highlight**:
  - Gold / Amber Glow: `#F59E0B`
  - Shimmer Light: `#FDE68A`
  - Glowing Laser Strike Line: Winner's exact symbol color (`#1D4ED8` for X, `#B91C1C` for O) with specular core and ambient bloom.
- **Match Outcome Status**:
  - **Victory**: `#059669` (Emerald Green)
  - **Defeat**: `#DC2626` (Bright Crimson)
  - **Draw**: `#94A3B8` (Neutral Slate)
- **Turn Timer States**:
  - Normal (>10s): `#10B981` (Vibrant Emerald)
  - Warning (5s–10s): `#F59E0B` (Amber Orange)
  - Critical (<5s): `#EF4444` (Flashing Crimson)

---

## 3. Theme Architecture & State Management

### 3.1 Centralized `ThemeProvider`
- **Class**: `ThemeProvider extends ChangeNotifier`
- **Responsibilities**:
  1. Loads `isDarkMode` preference on app boot from `LocalStorageService` (key: `is_dark_mode`, default: `false`).
  2. Updates `AppColors.isDarkMode = value` synchronously on toggle.
  3. Calls `notifyListeners()`, causing `MaterialApp` in `main.dart` to rebuild with `themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light`.
  4. Persists change asynchronously to `SharedPreferences`.

### 3.2 Dynamic `AppColors` Access
To support seamless switching without complex context lookups throughout widgets, dynamic tokens in `AppColors` are implemented as static getters:
```dart
static bool isDarkMode = false;
static Color get primary => isDarkMode ? const Color(0xFF3B82F6) : const Color(0xFF2563EB);
static Color get scaffoldBackground => isDarkMode ? const Color(0xFF0B1220) : const Color(0xFFF9FAFB);
static Color get surface => isDarkMode ? const Color(0xFF111C2E) : const Color(0xFFFFFFFF);
static Color get boardSurface => isDarkMode ? const Color(0xFF152238) : const Color(0xFFFFFFFF);
```
When `ThemeProvider` notifies listeners, the entire UI tree rebuilds with the active theme tokens instantly.

### 3.3 Material 3 Integration (`AppTheme`)
- `AppTheme.lightTheme` & `AppTheme.darkTheme`:
  - Full `ColorScheme` mapping (`primary`, `surface`, `onSurface`, `outline`).
  - Standardized `AppBarTheme`, `CardTheme`, `DialogTheme`, and `DividerTheme` matching the design tokens.
  - Native system navigation bar and status bar icons auto-adjust for contrast.

---

## 4. UI Components & Screen Specifications

### 4.1 Settings Appearance Section (`SettingsScreen`)
- **Location**: Top of Settings screen.
- **Components**:
  - Animated Sun/Moon icon badge (Gold sun in Light mode, Electric Blue moon in Dark mode).
  - Title: **"Dark Mode"**
  - Subtitle: Dynamic theme description ("Deep navy & neon blue accents" / "Clean canvas & strategic blue").
  - Pill Badge: High-contrast **"Light"** or **"Dark"** chip.
  - Interactive Switch: Instant toggle with haptic feedback.

### 4.2 Board Contrast & Grid Legibility (`CaroBoard` & `CaroCell`)
- **Light Theme**:
  - Crisp White board surface (`#FFFFFF`) on light grey scaffold (`#F9FAFB`).
  - Light grey grid lines (`#E5E7EB`).
  - Symbols render with vibrant dual-stop linear gradients.
- **Dark Theme**:
  - Deep Navy board surface (`#152238`) on midnight canvas (`#0B1220`).
  - Slate grid lines (`#334155`).
  - Elevated cells (`#17243A`) with subtle dark shadows (`rgba(0,0,0,0.2)`).
  - Cell hover state glows in vibrant blue (`#3B82F6`).
- **5-in-a-Row Laser Visibility**:
  - The winning laser strike and glowing cell highlights use multi-layered rendering (`BoxShadow` + core stroke) that creates dramatic neon contrast on both white and deep navy surfaces.

### 4.3 Splash Screen & Home Screen Logo
- Both the Splash screen animated centerpiece and Home screen hero logo adapt dynamically:
  - Board field transitions between Light White and Dark Navy (`#152238`).
  - Background glows use responsive alpha blending (`AppColors.bgGlowBlue` & `AppColors.bgGlowCyan`).
  - Diagonal 5-X winning streak and 20-O cards flip cleanly in both modes.

---

## 5. Animation, Audio & Interactive Feedback
1. **Stone Placement Flip & Sound**:
   - 3D card flip animation (`Matrix4` $Y$-axis rotation with perspective `0.001` over $380\text{ms}$).
   - Synchronized `tic.mp3` sound effect and selection vibration click.
2. **Winning Laser Strike & Haptic Surge**:
   - Multi-pass custom painter (ambient bloom, middle vibrant stroke, specular core highlight) drawn over the winning streak of 5.
   - Synchronized `laser.mp3` audio effect and heavy dual-pulse haptic feedback surge.
3. **Theme Switch Transition**:
   - Instant 0ms latency widget rebuild via `ThemeProvider`.
   - Subtle 300ms scale transition on the Sun/Moon icon inside Settings.
4. **Button Press Dynamics**:
   - Physical press translation (`topTranslate: 4dp`, `bottomMargin: 0dp`) in `BouncingGameButton`.
   - Synchronized `button.mp3` click sound and light tactile impact.
5. **Continuous Background Game Soundtrack**:
   - Smooth ambient looping `tic-tac-go-game Soundtrack.mp3`.
   - Automatic lifecycle pausing when app is minimized or backgrounded, and automatic resumption when returned to foreground.
