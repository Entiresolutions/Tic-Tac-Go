# Product Requirements Document (PRD) - Tic Tac GO

## 1. Executive Summary
**Tic Tac GO** (powered by Entire Solution) is a modern, offline-first strategy board game built in Flutter. Based on the 5-in-a-row Gomoku/Caro strategic mechanic on an optimized $7 \times 7$ grid, the application is completely self-contained and operates 100% offline without remote servers or cloud database dependencies. All player profiles, ratings, match histories, onboarding states, and audio preferences persist locally on the device using `SharedPreferences`.

The game offers two primary gameplay modes:
1. **Play with Bot**: Single-player mode against an adaptive, multi-tier AI bot with dynamic difficulty scaling.
2. **2 Players (Pass & Play)**: Local two-player mode on a single shared device.

---

## 2. Core Product Scope & Key Features

### 2.1 100% Offline & Local Persistence
- **Zero Remote Dependencies**: No external API, server, or cloud database required; all game logic and storage execute on-device.
- **Local Profile & Stats**: Player rating (Elo-based), wins, losses, draws, total matches, and win rate persist via `LocalStorageService`.
- **Match History Tracking**: Every completed match (against the Bot or in 2-Player mode) is recorded locally with result, move count, timestamps, and duration.
- **First-Time Tutorial Dialog (`CaroTutorialDialog`)**: Automatically triggers for first-time players before their first match, and is always re-accessible from the Home screen ("Rules") and the Settings screen ("How to Play").
- **Clean Modal Presentation**: Borderless, floating modal dialog with smooth soft drop shadows and clear navigation.

### 2.2 Gameplay Modes
1. **Play with Bot**:
   - Single-player offline match against computer AI.
   - Player always plays as **'X' (Cobalt Royal Blue)**; Bot plays as **'O' (Coral Crimson Red)**.
   - Dynamic Elo rating changes applied on victory or defeat.
2. **2 Players (Local / Pass & Play)**:
   - Turn-based play on a shared screen.
   - Player 1 plays as **'X'**; Player 2 plays as **'O'**.
   - Offline ratings and records saved to local match history.

---

## 3. Game Mechanics & Business Logic

### 3.1 Board Dimensions & Win Condition
- **Grid Format**: $7 \times 7$ square grid cells (`rows = 7, cols = 7`).
- **Winning Condition**: **5 consecutive unbroken symbols** in any direction (`winLen = 5`).
- **Evaluation Vectors**:
  1. Horizontal: $(r, c) \to (r, c + k)$
  2. Vertical: $(r, c) \to (r + k, c)$
  3. Main Diagonal: $(r, c) \to (r + k, c + k)$
  4. Anti-Diagonal: $(r, c) \to (r + k, c - k)$
- **Winning Line Highlight & Strike Line**:
  - `WinningLineData` stores the exact 5 cell coordinates.
  - An animated glowing strike line (custom-painted in the winning symbol's color: Blue for X, Red for O) draws across the 5 winning cells.
  - The board remains fully visible post-match with in-place action buttons ("Play Again" / "Home"), eliminating disruptive pop-up overlays.

### 3.2 Move Execution Logic (`CaroController`)
1. **Validation**:
   - Coordinates must fall within the grid ($0 \le r < 7$, $0 \le c < 7$).
   - Target cell must be blank (`board[r][c] == ""`).
   - In **Play with Bot**: User taps are only accepted during Player's turn (`currentTurn == mySymbol`).
   - Moves are rejected if the game is concluded (`isFinished == true`) or paused (`isPaused == true`).
2. **Move Processing**:
   - Symbol placed (`board[r][c] = symbol`).
   - Move counter incremented (`moveCount++`).
   - Move placement sound (`tic.mp3`) and selection haptic click triggered.
   - Turn countdown timer reset to 30 seconds.
3. **Outcome Resolution**:
   - **Win**: Sets `isFinished = true`, computes rating changes, records match result locally, draws animated strike line, plays `laser.mp3`, and triggers strong dual-pulse haptic feedback.
   - **Draw**: When all 49 cells are filled without a 5-streak, sets `isFinished = true`, records draw locally, and triggers draw haptic feedback.
   - **Ongoing**: Switches turn (`X` $\leftrightarrow$ `O`), resets 30s timer, and schedules bot response (350ms delay) if in bot mode.

### 3.3 Dynamic Adaptive AI Logic (Bot Scaling)
The Bot uses a 3-tier heuristic evaluation algorithm:
1. **Tier 1 - Winning Move (Highest Priority)**:
   - Scans all vacant cells; if placing `'O'` creates 5-in-a-row, executes immediately for victory (+600 weight).
2. **Tier 2 - Critical Defense Block**:
   - Scans all vacant cells; if player `'X'` has an open 4-in-a-row, immediately blocks that spot (+550 weight).
3. **Tier 3 - 5-Cell Window Evaluation & Center Control**:
   - Analyzes all possible 5-cell segments in 4 directions.
   - Offensive: 3-in-a-row (+180), 2-in-a-row (+40), 1-stone (+10).
   - Defensive: Blocks player 3-in-a-row (+180), 2-in-a-row (+50).
   - Positional weight favors controlling center cells of the $7 \times 7$ grid.

---

## 4. Audio, Soundtrack & Haptic Feedback System

### 4.1 Audio Engine Architecture (`AudioService`)
- Centralized singleton managing independent audio channels to eliminate audio overlap or clipping:
  - `_bgmPlayer`: Dedicated player for background music looping (`ReleaseMode.loop`).
  - `_buttonPlayer`: Dedicated low-latency player for button clicks.
  - `_movePlayer`: Dedicated low-latency player for board stone moves.
  - `_laserPlayer`: Dedicated player for winning laser strikes.
- **Timestamp Debouncing**: Prevents audio glitches during rapid taps (50ms button debounce, 60ms move debounce, 300ms laser strike debounce).
- **App Lifecycle Observer (`WidgetsBindingObserver`)**: Automatically pauses background music when the app is backgrounded or minimized, and resumes playback when returning to the foreground.

### 4.2 Audio Assets (`assets/sound/`)
| Asset File | Trigger Event | Behavior |
| :--- | :--- | :--- |
| `button.mp3` | Interactive button clicks, tabs, and navigation | Crisp, tactile click feedback |
| `tic.mp3` | Valid piece placement on the $7 \times 7$ board | Instant stone placement sound |
| `laser.mp3` | Winning 5-streak line strike animation | Synchronized laser strike sound |
| `tic-tac-go-game Soundtrack.mp3` | Continuous game soundtrack | Smooth ambient background loop |

### 4.3 Haptic Feedback Engine (`HapticService`)
- Centralized singleton respecting user's haptic toggle setting:
  - `lightImpact()`: 3D buttons, chips, tabs, and navigation icons.
  - `selectionClick()`: Board cell move placement.
  - `mediumImpact()`: Match loss, surrender, pause, and alert actions.
  - `heavyImpact()`: Match victory celebration.
  - `winningStreak()`: Synchronized multi-pulse haptic vibration surge timed with the laser strike animation.
  - `drawFeedback()`: Balanced haptic impact on drawn games.

---

## 5. UI & Screen Specifications

### 5.1 Splash Screen (`CaroSplashScreen`)
- **Duration**: 5.0 seconds with concurrent local storage preloading.
- **Background**: Clean Canvas (`#F9FAFB`) to Electric Blue (`#EFF6FF`) gradient with soft ambient radial glows (no distracting grid lines).
- **Centerpiece**: Animated 5×5 micro-board:
  - 5 diagonal cells with Cobalt Blue `'X'`s and glowing amber backgrounds (`#F59E0B`).
  - Remaining 20 cells filled with Coral Crimson Red `'O'`s.
  - Diagonal card flip wave animation across the board.
  - Glowing animated strike line drawn across the 5 diagonal `'X'`s.
- **Typography & Branding**: "TIC TAC GO" with letter-spacing and shader gradient, accompanied by a pill badge: `"POWERED BY ENTIRE SOLUTION"`.
- **Progress Bar**: Sleek 5-second linear progress bar in `#2563EB`.

### 5.2 Home Screen (`CaroHomeScreen`)
- **Top Bar**:
  - Left: Brand badge ("Tic Tac GO").
  - Right: Responsive 3D tactile buttons for "Rules" (Tutorial) and "Settings". Compact icon-only display on small viewports (< 420px).
- **Centerpiece Logo**: Matches the Splash Screen's 5×5 micro-board with rounded corners, 5 diagonal X's, 20 O's, glowing amber cells, and diagonal strike line.
- **Tagline**: "Connect 5 – Outsmart – Win!"
- **Action Buttons**:
  - "PLAY WITH BOT": Primary blue 3D tactile button with robot icon.
  - "2 PLAYERS": Crisp white 3D tactile button with players icon.
- **Match History Shortcut**: Quick-access card displaying past wins, losses, and replays.

### 5.3 Playing Screen (`CaroPlayingScreen`)
- **Top Control Bar**: Leave match button, mode pill badge with `"5-IN-ROW"` indicator, and Pause/Restart controls.
- **Player Status**: Active turn indicator, username, rating, symbol badge, and dynamic 30-second circular countdown timer.
- **Interactive Board**: Centered $7 \times 7$ board with 3D card-flip piece placement animations.
- **Post-Game Controls**: Winner banner (`X CONNECTED 5! WINNER!`, `O CONNECTED 5! WINNER!`, or `MATCH DRAWN!`), with in-place "Play Again" and "Home" tactile buttons.

### 5.4 Settings Screen (`SettingsScreen`)
- **Audio & Feedback Section**:
  - Sound Effects: Toggle (ON/OFF) + Volume Slider (0% - 100%).
  - Background Music: Toggle (ON/OFF) + Volume Slider (0% - 100%).
  - Haptic Feedback: Toggle (ON/OFF).
- **Game Info Section**:
  - How to Play (Tutorial launch), Board Format ($7 \times 7$ Grid), Win Condition (5 in a row), Game Storage (Local & Offline), Version (1.0.0).

### 5.5 Match History Screen (`MatchHistoryScreen`)
- Filterable match history tabs: **All**, **Wins**, **Losses**, **Draws**.
- Match cards with opponent name, game mode, result badge, and timestamp.
- Detailed modal popup showing board size, move count, match duration, and date.

---

## 6. Local Storage Schema (`LocalStorageService`)

Data is persisted locally in `SharedPreferences` as structured JSON:

| Key | Type | Description |
| :--- | :--- | :--- |
| `local_user_profile` | JSON String (`MyProfile`) | Username, avatar, rating, total matches, wins, losses, draws, win rate |
| `local_match_history` | JSON Array (`List<MatchHistoryItem>`) | Match ID, opponent name, game mode, result (`win`/`loss`/`draw`), total moves, duration, timestamp |
| `has_seen_tutorial` | Boolean | Flags whether the user has seen the first-time onboarding tutorial |
| `settings_sound_effects` | Boolean | Sound effects enabled state (default: `true`) |
| `settings_sound_effects_volume` | Double | Sound effects volume from `0.0` to `1.0` (default: `0.85`) |
| `settings_music` | Boolean | Background music enabled state (default: `true`) |
| `settings_music_volume` | Double | Background music volume from `0.0` to `1.0` (default: `0.70`) |
| `settings_haptic_feedback` | Boolean | Haptic vibration enabled state (default: `true`) |

- **Local Elo Rating Rules**:
  - Win vs Bot: $+15$ Elo | Loss vs Bot: $-10$ Elo
  - Win in 2-Player: $+20$ Elo | Loss in 2-Player: $-15$ Elo
  - Draw: $\pm 0$ Elo
  - Rating bounded within $[400, 3000]$.

---

## 7. Platform & Build Requirements
- **Framework**: Flutter (Dart 3.x, Null Safety, Material 3 enabled).
- **Android Target**: Android SDK Platform 34 (`compileSdk = 34`, `targetSdk = 34`, `minSdk = 21`).
- **Permissions**: `android.permission.VIBRATE` for tactile haptic feedback.
- **Audio Package**: `audioplayers: ^5.2.1` with `audioplayers_android` compiled against SDK 34.
- **Screen Responsiveness**: Tested and validated across viewports from compact mobile ($320 \times 568$) to large tablet landscape ($1280 \times 800$) with zero `RenderFlex` overflows.
