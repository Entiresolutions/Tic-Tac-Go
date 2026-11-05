# Product Requirements Document (PRD) - Tic Tac GO

## 1. Executive Summary
**Tic Tac GO** (Application ID: `com.entiresolutions.tictacgo`, powered by Entire Solution) is a modern, offline-first strategy board game built in Flutter. Parameterized around a flexible strategic engine (`GameConfig`) spanning grids from $3 \times 3$ to $8 \times 8$ and win streaks from 3 to 8, the application is completely self-contained and operates 100% offline without remote servers or cloud database dependencies. All player profiles, ratings, match histories, unlocked ranks, and audio preferences persist locally on the device using `SharedPreferences`.

The game offers two primary gameplay modes:
1. **Play with Bot**: Single-player mode with locked rank progression across 6 levels, from Beginner up to flawless Master AI.
2. **2 Players (Pass & Play)**: Local two-player mode on a single shared device across all 6 freely selectable levels (pre-selecting Master).

---

## 2. Core Product Scope & Key Features

### 2.1 100% Offline & Local Persistence
- **Zero Remote Dependencies**: No external API, server, or cloud database required; all game logic and storage execute on-device.
- **Local Profile & Stats**: Player rating (Elo-based), wins, losses, draws, total matches, and win rate persist via `LocalStorageService`.
- **Bot Level Progression**: Unlocked level index persists locally (`bot_unlocked_level`). Beginner is unlocked by default; defeating each level unlocks the subsequent rank up to Master.
- **Match History Tracking**: Every completed match (against the Bot or in 2-Player mode) is recorded locally with result, level name, board rows/cols, total moves, timestamps, and duration.
- **First-Time Tutorial Dialog (`CaroTutorialDialog`)**: Dynamic tutorial highlighting variable win streaks, strategic defense, hints, undos, and turn clocks.

### 2.2 Gameplay Modes & Level Selection
1. **Play with Bot**:
   - Single-player offline match against computer AI.
   - Player always plays as **'X' (Cobalt Royal Blue)**; Bot plays as **'O' (Coral Crimson Red)**.
   - Interactive level dialog shows all 6 ranks with locks. Locked ranks display "Beat <previous level> to unlock".
   - Victory unlocks the next rank and displays a "Next Level" prompt. Beating Master displays the special "MASTER CONQUERED!" banner.
2. **2 Players (Local / Pass & Play)**:
   - Turn-based play on a shared screen.
   - Player 1 plays as **'X'**; Player 2 plays as **'O'**.
   - Level select dialog opens without progression locks; all 6 grid configurations are available (defaulting to Master $8 \times 8$).

---

## 3. Parameterized Game Engine & 6-Level Hierarchy

### 3.1 Shared Strategic Levels (`GameLevel`)
| Level | Display Name | Grid Dimensions | Win Streak (`winLen`) | Bot Mistake Budget | AI Search Profile |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | **Beginner** | $3 \times 3$ | 3 in a row | 3 mistakes | Simple heuristics, quick win for newcomers |
| 2 | **Easy** | $4 \times 4$ | 3 in a row | 2 mistakes | Basic tactical heuristic |
| 3 | **Medium** | $5 \times 5$ | 4 in a row | 2 mistakes | Full heuristic evaluation & fork recognition |
| 4 | **Hard** | $6 \times 6$ | 5 in a row | 2 mistakes | Alpha-beta lookahead (Depth 2), candidate pruning |
| 5 | **Very Hard** | $7 \times 7$ | 7 in a row | 1 mistake | Alpha-beta lookahead (Depth 2), high attack weights |
| 6 | **Master** | $8 \times 8$ | 8 in a row | 0 mistakes (Flawless) | Alpha-beta (Depth 3–4), move ordering, threat creation |

### 3.2 Dynamic Board Dimensions & Geometry (`GameConfig`)
- `rows`, `cols`, and `winLen` are fully parameterized in `GameConfig`.
- All evaluation windows (horizontal, vertical, main diagonal, anti-diagonal) are precomputed once on configuration construction.
- `WinningLineData` records exact winning coordinates, driving dynamic strike-line rendering across any grid size.

### 3.3 Mistake Budgeting Engine
- At match start, the bot pre-picks $N$ turn numbers based on `config.botMistakes`.
- On selected mistake turns, the bot deliberately plays weaker candidate moves or misses non-fatal blocks, allowing human players room for comeback tactics.
- Once the mistake budget is exhausted, the bot reverts to its peak evaluation profile.

### 3.4 Early Dead-Position Draw Detection
- Evaluated immediately after each move (post-win check).
- A window of length `winLen` is considered **alive** for player $P$ if:
  1. It contains zero opponent stones.
  2. Player $P$ has sufficient turns remaining to fill all vacant cells in the window ($turnsLeft = \lceil emptyCells/2 \rceil$ for player to move, $\lfloor emptyCells/2 \rfloor$ for the other).
- **Early Draw Trigger**: If NO window is alive for 'X' and NO window is alive for 'O', the match concludes immediately as a DRAW with the message `"MATCH DRAWN! No winning line left"`.
- Search complexity is capped at $O(\text{windows})$ per move.

---

## 4. Tactical In-Game Tools

### 4.1 Strategic Hint
- Evaluates the current board state using the strongest Master evaluation engine.
- Highlights the optimal next move with an interactive pulsing gold glow and a subtle lightbulb indicator on the cell.
- Cleared automatically on move placement or undo.

### 4.2 Move History & Undo System
- Maintains a clean move stack (`CaroMoveRecord`).
- **Bot Mode**: Reverts both the bot's move and the user's previous move back to user turn; cancels active bot timers and resets the 30-second turn timer.
- **2-Player Mode**: Reverts exactly one move and returns turn to the previous player.
- Tactile 3D button styling with audio click and light haptic confirmation.

### 4.3 Start Match Banner
- Elegant modal banner appearing in the center of the Playing screen at match start.
- Displays "START" and "Connect X to win" along with the current rank and grid dimensions.
- Light-gold gradient, fine gold border, and subtle shadow; auto-dismisses after 2.0 seconds.
- Blocks touch inputs and pauses turn countdown until dismissed.

---

## 5. Audio, Soundtrack & Haptic Feedback System

### 5.1 Continuous Soundtrack Looping
- Background music begins seamlessly in `CaroSplashScreen.initState()` via `AudioService.instance.startBgm()`.
- Continues playing uninterrupted across screens and navigation without restarting.
- Respects user settings and pauses/resumes automatically via `WidgetsBindingObserver`.

### 5.2 Real-Device Hardware Haptics
- `android.permission.VIBRATE` declared in `AndroidManifest.xml` (no network permissions).
- Utilizes the `vibration` hardware plugin with custom vibration patterns and graceful fallback to `HapticFeedback`.
- `winningStreak()`: Multi-pulse vibration pattern (`[0, 70, 50, 110, 50, 180] ms`) synchronized with the laser strike effect.

---

## 6. Visual Identity & Brand Assets

### 6.1 Application Logo & Icons
- `assets/tic-tac-go-logo.png` registered in `pubspec.yaml`.
- App launcher icons generated for Android (including adaptive background `#0B1220`) and iOS using `flutter_launcher_icons`.
- Home screen showcases the clean high-resolution logo badge, while the Splash screen maintains its interactive $5 \times 5$ animated card-flip board.

### 6.2 Responsive Design Standards
- Verified responsive across all viewports from $320 \times 568$ (small mobile) through $412 \times 915$ up to $1280 \times 800$ (tablet landscape).
- Zero RenderFlex overflow issues across portrait and landscape layouts.
