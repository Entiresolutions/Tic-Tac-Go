import 'winning_line_data.dart';

/// Predefined strategic levels for Tic Tac GO.
enum GameLevel {
  beginner,
  easy,
  medium,
  hard,
  veryHard,
  master;

  String get displayName {
    switch (this) {
      case GameLevel.beginner:
        return 'Beginner';
      case GameLevel.easy:
        return 'Easy';
      case GameLevel.medium:
        return 'Medium';
      case GameLevel.hard:
        return 'Hard';
      case GameLevel.veryHard:
        return 'Very Hard';
      case GameLevel.master:
        return 'Master';
    }
  }

  String get description {
    switch (this) {
      case GameLevel.beginner:
        return '3×3 Grid • 3 in a row';
      case GameLevel.easy:
        return '4×4 Grid • 3 in a row';
      case GameLevel.medium:
        return '5×5 Grid • 4 in a row';
      case GameLevel.hard:
        return '6×6 Grid • 5 in a row';
      case GameLevel.veryHard:
        return '7×7 Grid • 7 in a row';
      case GameLevel.master:
        return '8×8 Grid • 8 in a row';
    }
  }

  int get rows => config.rows;
  int get cols => config.cols;
  int get winLen => config.winLen;
  int get botMistakes => config.botMistakes;

  GameConfig get config {
    switch (this) {
      case GameLevel.beginner:
        return GameConfig.create(
          level: GameLevel.beginner,
          rows: 3,
          cols: 3,
          winLen: 3,
          botMistakes: 3,
          botProfile: const BotProfile(
            searchDepth: 0,
            attackWeight: 1.0,
            defenseWeight: 0.8,
            pruningRadius: 1,
          ),
        );
      case GameLevel.easy:
        return GameConfig.create(
          level: GameLevel.easy,
          rows: 4,
          cols: 4,
          winLen: 3,
          botMistakes: 2,
          botProfile: const BotProfile(
            searchDepth: 0,
            attackWeight: 1.1,
            defenseWeight: 0.9,
            pruningRadius: 1,
          ),
        );
      case GameLevel.medium:
        return GameConfig.create(
          level: GameLevel.medium,
          rows: 5,
          cols: 5,
          winLen: 4,
          botMistakes: 2,
          botProfile: const BotProfile(
            searchDepth: 0,
            attackWeight: 1.2,
            defenseWeight: 1.1,
            pruningRadius: 1,
          ),
        );
      case GameLevel.hard:
        return GameConfig.create(
          level: GameLevel.hard,
          rows: 6,
          cols: 6,
          winLen: 5,
          botMistakes: 2,
          botProfile: const BotProfile(
            searchDepth: 2,
            attackWeight: 1.3,
            defenseWeight: 1.2,
            pruningRadius: 2,
          ),
        );
      case GameLevel.veryHard:
        return GameConfig.create(
          level: GameLevel.veryHard,
          rows: 7,
          cols: 7,
          winLen: 7,
          botMistakes: 1,
          botProfile: const BotProfile(
            searchDepth: 2,
            attackWeight: 1.4,
            defenseWeight: 1.3,
            pruningRadius: 2,
          ),
        );
      case GameLevel.master:
        return GameConfig.create(
          level: GameLevel.master,
          rows: 8,
          cols: 8,
          winLen: 8,
          botMistakes: 0,
          botProfile: const BotProfile(
            searchDepth: 3,
            attackWeight: 1.5,
            defenseWeight: 1.4,
            pruningRadius: 2,
          ),
        );
    }
  }
}

/// Profile tuning for the AI Bot at a specific level.
class BotProfile {
  final int searchDepth;
  final double attackWeight;
  final double defenseWeight;
  final int pruningRadius;

  const BotProfile({
    required this.searchDepth,
    required this.attackWeight,
    required this.defenseWeight,
    required this.pruningRadius,
  });
}

/// Precomputed line of `winLen` consecutive positions.
class BoardWindow {
  final List<Position> positions;
  const BoardWindow(this.positions);
}

/// Fully parameterized game configuration controlling board geometry,
/// victory condition, bot difficulty profile, and precomputed windows for
/// O(windows) early dead-position draw detection.
class GameConfig {
  final GameLevel level;
  final int rows;
  final int cols;
  final int winLen;
  final int botMistakes;
  final BotProfile botProfile;
  final List<BoardWindow> windows;

  const GameConfig._({
    required this.level,
    required this.rows,
    required this.cols,
    required this.winLen,
    required this.botMistakes,
    required this.botProfile,
    required this.windows,
  });

  /// Factory constructor that precomputes all winLen-length windows once.
  factory GameConfig.create({
    GameLevel level = GameLevel.master,
    required int rows,
    required int cols,
    required int winLen,
    int botMistakes = 0,
    BotProfile botProfile = const BotProfile(
      searchDepth: 3,
      attackWeight: 1.5,
      defenseWeight: 1.4,
      pruningRadius: 2,
    ),
  }) {
    final List<BoardWindow> computedWindows = [];

    // 1. Horizontal windows: (r, c) to (r, c + winLen - 1)
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c <= cols - winLen; c++) {
        final List<Position> line = [];
        for (int k = 0; k < winLen; k++) {
          line.add(Position(r, c + k));
        }
        computedWindows.add(BoardWindow(line));
      }
    }

    // 2. Vertical windows: (r, c) to (r + winLen - 1, c)
    for (int c = 0; c < cols; c++) {
      for (int r = 0; r <= rows - winLen; r++) {
        final List<Position> line = [];
        for (int k = 0; k < winLen; k++) {
          line.add(Position(r + k, c));
        }
        computedWindows.add(BoardWindow(line));
      }
    }

    // 3. Main Diagonal windows (\): (r+k, c+k)
    for (int r = 0; r <= rows - winLen; r++) {
      for (int c = 0; c <= cols - winLen; c++) {
        final List<Position> line = [];
        for (int k = 0; k < winLen; k++) {
          line.add(Position(r + k, c + k));
        }
        computedWindows.add(BoardWindow(line));
      }
    }

    // 4. Anti-Diagonal windows (/): (r+k, c-k)
    for (int r = 0; r <= rows - winLen; r++) {
      for (int c = winLen - 1; c < cols; c++) {
        final List<Position> line = [];
        for (int k = 0; k < winLen; k++) {
          line.add(Position(r + k, c - k));
        }
        computedWindows.add(BoardWindow(line));
      }
    }

    return GameConfig._(
      level: level,
      rows: rows,
      cols: cols,
      winLen: winLen,
      botMistakes: botMistakes,
      botProfile: botProfile,
      windows: computedWindows,
    );
  }

  /// Evaluates whether the current board is in an unavoidable dead-position (Early Draw).
  ///
  /// A window is "alive" for player P if:
  /// 1. It contains 0 opponent stones.
  /// 2. P still has enough turns remaining to fill all empty cells in that window.
  ///
  /// If NO window is alive for 'X' AND NO window is alive for 'O', then neither
  /// player can ever complete a winning line, so the match is an early draw.
  bool isDeadPosition(List<List<String>> board, String nextTurn) {
    int totalEmpty = 0;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (board[r][c].isEmpty) {
          totalEmpty++;
        }
      }
    }

    if (totalEmpty == 0) return true;

    // Remaining turns available for each player
    final int turnsLeftForX = (nextTurn == "X")
        ? (totalEmpty + 1) ~/ 2
        : totalEmpty ~/ 2;
    final int turnsLeftForO = (nextTurn == "O")
        ? (totalEmpty + 1) ~/ 2
        : totalEmpty ~/ 2;

    bool xHasAliveWindow = false;
    bool oHasAliveWindow = false;

    for (final window in windows) {
      if (!xHasAliveWindow) {
        bool hasO = false;
        int emptyCount = 0;
        for (final pos in window.positions) {
          final val = board[pos.x][pos.y];
          if (val == "O") {
            hasO = true;
            break;
          } else if (val.isEmpty) {
            emptyCount++;
          }
        }
        if (!hasO && emptyCount <= turnsLeftForX) {
          xHasAliveWindow = true;
        }
      }

      if (!oHasAliveWindow) {
        bool hasX = false;
        int emptyCount = 0;
        for (final pos in window.positions) {
          final val = board[pos.x][pos.y];
          if (val == "X") {
            hasX = true;
            break;
          } else if (val.isEmpty) {
            emptyCount++;
          }
        }
        if (!hasX && emptyCount <= turnsLeftForO) {
          oHasAliveWindow = true;
        }
      }

      // Early exit if both players still have a viable winning line
      if (xHasAliveWindow && oHasAliveWindow) {
        return false;
      }
    }

    // Dead position if NEITHER player can ever win
    return !xHasAliveWindow && !oHasAliveWindow;
  }
}

