import 'dart:math' as math;
import 'game_config.dart';
import 'winning_line_data.dart';

/// High-performance, multi-tier Bot AI engine for Tic Tac GO.
/// Supports simple heuristics, full tactical evaluation, and alpha-beta
/// lookahead with move ordering, candidate-cell pruning, and mistake budgets.
class BotEngine {
  /// Find the best move for the AI Bot according to its level profile.
  static Position findBestMove({
    required List<List<String>> board,
    required GameConfig config,
    required String botSymbol,
    required String humanSymbol,
    required bool isMistakeTurn,
  }) {
    final candidates = getCandidateMoves(board, config);
    if (candidates.isEmpty) {
      return Position(config.rows ~/ 2, config.cols ~/ 2);
    }

    // 1. Immediate Win Check (Bot completes win streak)
    for (final pos in candidates) {
      board[pos.x][pos.y] = botSymbol;
      final win = checkWinAt(board, config, pos.x, pos.y, botSymbol);
      board[pos.x][pos.y] = "";
      if (win) {
        if (!isMistakeTurn) {
          return pos;
        }
      }
    }

    // 2. Immediate Block Check (Human about to win next turn)
    Position? criticalBlockPos;
    for (final pos in candidates) {
      board[pos.x][pos.y] = humanSymbol;
      final humanWin = checkWinAt(board, config, pos.x, pos.y, humanSymbol);
      board[pos.x][pos.y] = "";
      if (humanWin) {
        criticalBlockPos = pos;
        break;
      }
    }

    // If it's a mistake turn, deliberately ignore the critical block if possible!
    if (criticalBlockPos != null && !isMistakeTurn) {
      return criticalBlockPos;
    }

    // 3. Mistake execution: pick a non-optimal move
    if (isMistakeTurn && candidates.length > 1) {
      // Filter out the critical block and top move
      final weakCandidates = candidates.where((p) => p != criticalBlockPos).toList();
      if (weakCandidates.isNotEmpty) {
        weakCandidates.sort((a, b) =>
            evaluatePosition(board, config, a.x, a.y, botSymbol, humanSymbol)
                .compareTo(evaluatePosition(board, config, b.x, b.y, botSymbol, humanSymbol)));
        // Return a lower-scoring or median candidate
        final idx = math.Random().nextInt(weakCandidates.length);
        return weakCandidates[idx];
      }
    }

    // 4. Alpha-Beta lookahead for Hard, Very Hard, and Master
    final depth = config.botProfile.searchDepth;
    if (depth >= 2) {
      Position? bestAlphaBetaMove;
      double maxScore = -1e9;
      double alpha = -1e9;
      const double beta = 1e9;

      // Move ordering: evaluate highest static scored moves first
      candidates.sort((a, b) =>
          evaluatePosition(board, config, b.x, b.y, botSymbol, humanSymbol)
              .compareTo(evaluatePosition(board, config, a.x, a.y, botSymbol, humanSymbol)));

      for (final pos in candidates) {
        board[pos.x][pos.y] = botSymbol;
        final score = _minimax(
          board: board,
          config: config,
          depth: depth - 1,
          isMaximizing: false,
          alpha: alpha,
          beta: beta,
          botSymbol: botSymbol,
          humanSymbol: humanSymbol,
        );
        board[pos.x][pos.y] = "";

        if (score > maxScore) {
          maxScore = score;
          bestAlphaBetaMove = pos;
        }
        alpha = math.max(alpha, maxScore);
      }

      if (bestAlphaBetaMove != null) {
        return bestAlphaBetaMove;
      }
    }

    // 5. Tactical Heuristic (for Beginner, Easy, Medium, or Alpha-Beta fallback)
    Position bestPos = candidates.first;
    double bestScore = -1e9;

    for (final pos in candidates) {
      final score = evaluatePosition(board, config, pos.x, pos.y, botSymbol, humanSymbol);
      if (score > bestScore) {
        bestScore = score;
        bestPos = pos;
      }
    }

    return bestPos;
  }

  /// Minimax search with Alpha-Beta pruning and candidate move ordering
  static double _minimax({
    required List<List<String>> board,
    required GameConfig config,
    required int depth,
    required bool isMaximizing,
    required double alpha,
    required double beta,
    required String botSymbol,
    required String humanSymbol,
  }) {
    // Terminal early draw check
    if (config.isDeadPosition(board, isMaximizing ? botSymbol : humanSymbol)) {
      return 0.0;
    }

    if (depth <= 0) {
      return evaluateBoard(board, config, botSymbol, humanSymbol);
    }

    final candidates = getCandidateMoves(board, config);
    if (candidates.isEmpty) return 0.0;

    double currentAlpha = alpha;
    double currentBeta = beta;

    if (isMaximizing) {
      double maxEval = -1e9;
      // Move ordering
      candidates.sort((a, b) =>
          evaluatePosition(board, config, b.x, b.y, botSymbol, humanSymbol)
              .compareTo(evaluatePosition(board, config, a.x, a.y, botSymbol, humanSymbol)));

      for (final pos in candidates) {
        board[pos.x][pos.y] = botSymbol;
        if (checkWinAt(board, config, pos.x, pos.y, botSymbol)) {
          board[pos.x][pos.y] = "";
          return 100000.0 + depth * 1000.0; // Prefer faster wins
        }

        final eval = _minimax(
          board: board,
          config: config,
          depth: depth - 1,
          isMaximizing: false,
          alpha: currentAlpha,
          beta: currentBeta,
          botSymbol: botSymbol,
          humanSymbol: humanSymbol,
        );
        board[pos.x][pos.y] = "";

        maxEval = math.max(maxEval, eval);
        currentAlpha = math.max(currentAlpha, eval);
        if (currentBeta <= currentAlpha) break; // Beta cutoff
      }
      return maxEval;
    } else {
      double minEval = 1e9;
      // Move ordering
      candidates.sort((a, b) =>
          evaluatePosition(board, config, b.x, b.y, humanSymbol, botSymbol)
              .compareTo(evaluatePosition(board, config, a.x, a.y, humanSymbol, botSymbol)));

      for (final pos in candidates) {
        board[pos.x][pos.y] = humanSymbol;
        if (checkWinAt(board, config, pos.x, pos.y, humanSymbol)) {
          board[pos.x][pos.y] = "";
          return -100000.0 - depth * 1000.0; // Block human wins
        }

        final eval = _minimax(
          board: board,
          config: config,
          depth: depth - 1,
          isMaximizing: true,
          alpha: currentAlpha,
          beta: currentBeta,
          botSymbol: botSymbol,
          humanSymbol: humanSymbol,
        );
        board[pos.x][pos.y] = "";

        minEval = math.min(minEval, eval);
        currentBeta = math.min(currentBeta, eval);
        if (currentBeta <= currentAlpha) break; // Alpha cutoff
      }
      return minEval;
    }
  }

  /// Find the best hint move for human player using Master-grade evaluation.
  static Position findHintMove({
    required List<List<String>> board,
    required GameConfig config,
    required String playerSymbol,
  }) {
    final opponentSymbol = playerSymbol == "X" ? "O" : "X";
    final candidates = getCandidateMoves(board, config);
    if (candidates.isEmpty) {
      return Position(config.rows ~/ 2, config.cols ~/ 2);
    }

    // 1. Can human player win immediately?
    for (final pos in candidates) {
      board[pos.x][pos.y] = playerSymbol;
      final win = checkWinAt(board, config, pos.x, pos.y, playerSymbol);
      board[pos.x][pos.y] = "";
      if (win) return pos;
    }

    // 2. Must human block opponent immediate win?
    for (final pos in candidates) {
      board[pos.x][pos.y] = opponentSymbol;
      final oppWin = checkWinAt(board, config, pos.x, pos.y, opponentSymbol);
      board[pos.x][pos.y] = "";
      if (oppWin) return pos;
    }

    // 3. Tactical search
    Position bestPos = candidates.first;
    double bestScore = -1e9;

    for (final pos in candidates) {
      final score = evaluatePosition(
        board,
        config,
        pos.x,
        pos.y,
        playerSymbol,
        opponentSymbol,
      );
      if (score > bestScore) {
        bestScore = score;
        bestPos = pos;
      }
    }

    return bestPos;
  }

  /// Check if placing a symbol at (r, c) creates a line of `winLen` consecutive stones.
  static bool checkWinAt(
    List<List<String>> board,
    GameConfig config,
    int r,
    int c,
    String symbol,
  ) {
    const directions = [
      [0, 1], // horizontal
      [1, 0], // vertical
      [1, 1], // main diag
      [1, -1], // anti-diag
    ];

    for (final dir in directions) {
      int count = 1;
      // forward
      for (int step = 1; step < config.winLen; step++) {
        final nr = r + dir[0] * step;
        final nc = c + dir[1] * step;
        if (nr < 0 || nr >= config.rows || nc < 0 || nc >= config.cols) break;
        if (board[nr][nc] == symbol) {
          count++;
        } else {
          break;
        }
      }
      // backward
      for (int step = 1; step < config.winLen; step++) {
        final nr = r - dir[0] * step;
        final nc = c - dir[1] * step;
        if (nr < 0 || nr >= config.rows || nc < 0 || nc >= config.cols) break;
        if (board[nr][nc] == symbol) {
          count++;
        } else {
          break;
        }
      }

      if (count >= config.winLen) {
        return true;
      }
    }
    return false;
  }

  /// Filter candidate moves to empty cells that are adjacent (within radius) to existing stones.
  /// If the board is empty, returns the center cell.
  static List<Position> getCandidateMoves(List<List<String>> board, GameConfig config) {
    final int rows = config.rows;
    final int cols = config.cols;
    final int radius = config.botProfile.pruningRadius;

    bool hasStones = false;
    final Set<Position> candidateSet = {};

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (board[r][c].isNotEmpty) {
          hasStones = true;
          for (int dr = -radius; dr <= radius; dr++) {
            for (int dc = -radius; dc <= radius; dc++) {
              final nr = r + dr;
              final nc = c + dc;
              if (nr >= 0 && nr < rows && nc >= 0 && nc < cols) {
                if (board[nr][nc].isEmpty) {
                  candidateSet.add(Position(nr, nc));
                }
              }
            }
          }
        }
      }
    }

    if (!hasStones) {
      return [Position(rows ~/ 2, cols ~/ 2)];
    }

    if (candidateSet.isEmpty) {
      // Fallback: return all empty cells
      final list = <Position>[];
      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          if (board[r][c].isEmpty) list.add(Position(r, c));
        }
      }
      return list;
    }

    return candidateSet.toList();
  }

  /// Tactical heuristic evaluation of placing `mySymbol` at (r, c).
  static double evaluatePosition(
    List<List<String>> board,
    GameConfig config,
    int r,
    int c,
    String mySymbol,
    String oppSymbol,
  ) {
    double score = 0.0;
    final centerR = config.rows / 2.0;
    final centerC = config.cols / 2.0;

    // Center preference
    final dist = (r - centerR).abs() + (c - centerC).abs();
    score += (config.rows - dist) * 2.0;

    const directions = [
      [0, 1],
      [1, 0],
      [1, 1],
      [1, -1],
    ];

    final winLen = config.winLen;
    final threatLen = winLen - 1; // 4 in Caro/Gomoku, 2 in 3x3

    for (final dir in directions) {
      final dr = dir[0];
      final dc = dir[1];

      for (int step = -(winLen - 1); step <= 0; step++) {
        int myCount = 0;
        int oppCount = 0;
        bool valid = true;

        for (int k = 0; k < winLen; k++) {
          final nr = r + (step + k) * dr;
          final nc = c + (step + k) * dc;

          if (nr < 0 || nr >= config.rows || nc < 0 || nc >= config.cols) {
            valid = false;
            break;
          }

          if (nr == r && nc == c) {
            myCount++; // candidate cell count
            continue;
          }

          final cell = board[nr][nc];
          if (cell == mySymbol) myCount++;
          if (cell == oppSymbol) oppCount++;
        }

        if (valid) {
          // Attack value (if opponent has 0 stones in window)
          if (oppCount == 0) {
            if (myCount == winLen) {
              score += 100000.0 * config.botProfile.attackWeight; // Immediate Win!
            } else if (myCount == threatLen) {
              score += 2500.0 * config.botProfile.attackWeight; // Direct threat
            } else if (myCount == threatLen - 1 && threatLen - 1 > 0) {
              score += 350.0 * config.botProfile.attackWeight;
            } else {
              score += 20.0 * config.botProfile.attackWeight;
            }
          }

          // Defense value (blocks opponent streak)
          if (myCount == 1) { // Only candidate cell is ours
            if (oppCount == threatLen) {
              score += 8000.0 * config.botProfile.defenseWeight; // Critical threat block!
            } else if (oppCount == threatLen - 1 && threatLen - 1 > 0) {
              score += 800.0 * config.botProfile.defenseWeight;
            } else if (oppCount == threatLen - 2 && threatLen - 2 > 0) {
              score += 150.0 * config.botProfile.defenseWeight;
            } else {
              score += 15.0 * config.botProfile.defenseWeight;
            }
          }
        }
      }
    }

    return score;
  }

  /// Static board evaluation for Alpha-Beta leaves.
  static double evaluateBoard(
    List<List<String>> board,
    GameConfig config,
    String mySymbol,
    String oppSymbol,
  ) {
    double totalScore = 0.0;
    for (final window in config.windows) {
      int myCount = 0;
      int oppCount = 0;
      for (final p in window.positions) {
        final val = board[p.x][p.y];
        if (val == mySymbol) myCount++;
        if (val == oppSymbol) oppCount++;
      }

      if (oppCount == 0 && myCount > 0) {
        if (myCount == config.winLen) {
          return 100000.0;
        }
        if (myCount == config.winLen - 1) {
          totalScore += 1000.0;
        } else if (myCount == config.winLen - 2) {
          totalScore += 100.0;
        } else {
          totalScore += 10.0;
        }
      } else if (myCount == 0 && oppCount > 0) {
        if (oppCount == config.winLen) {
          return -100000.0;
        }
        if (oppCount == config.winLen - 1) {
          totalScore -= 1200.0;
        } else if (oppCount == config.winLen - 2) {
          totalScore -= 120.0;
        } else {
          totalScore -= 12.0;
        }
      }
    }
    return totalScore;
  }
}

