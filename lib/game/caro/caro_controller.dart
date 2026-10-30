// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:tic_tac_go/configs/app_config.dart';
import 'package:tic_tac_go/services/auth_service.dart';
import 'package:tic_tac_go/services/audio_service.dart';
import 'package:tic_tac_go/services/caro_service.dart';
import 'package:tic_tac_go/services/local_storage_service.dart';
import 'package:tic_tac_go/game/caro/winning_line_data.dart';

/// Manages Caro game logic (board, chat, and WebSocket connection).
class CaroController extends ChangeNotifier {
  final int rows;
  final int cols;
  final int winLen;
  final int matchId;
  final bool isOffline;
  final bool isVsBot;

  List<List<String>> board = [];
  String currentTurn = "X";
  String? mySymbol;
  String? opponentSymbol;
  int? myUserId;
  int? opponentUserId;
  String? myUsername;
  String? opponentUsername;
  int? myRating; // My rating
  int? opponentRating; // Opponent's rating
  int? myRatingChange; // Rating change after the match (from the server)
  bool isConnected = false;
  bool isFinished = false;
  int? winnerId;
  int moveCount = 0;
  WinningLineData? winningLine;
  int? lastMoveRow;
  int? lastMoveCol;

  // Rematch
  bool rematchRequested = false;
  bool opponentRematchRequested = false;
  bool opponentLeft = false;
  int rematchRequestCount = 0;
  int? newMatchId;

  // Score tracking across rematches
  int myWins = 0;
  int opponentWins = 0;
  int draws = 0;

  // Timer
  int? timeLeft; // seconds
  int? initialTimeLeft; // Initial value at the start of the turn
  DateTime? turnStartTime;
  bool _isTimerRunning = false; // Flag tracking the timer state
  bool isPaused = false; // Pause state
  CaroService? _service;

  // 🗨️ Chat messages (displayed in the panel)
  List<Map<String, dynamic>> chatMessages = [];
  int unreadMessageCount = 0; // Number of unread messages
  bool isChatOpen = false; // Chat panel state

  CaroController({
    this.rows = 7,
    this.cols = 7,
    this.winLen = 5,
    required this.matchId,
    this.isOffline = false,
    this.isVsBot = false,
    int? initialMyRating, // Initial rating
    int? initialOpponentRating, // Initial opponent rating
  }) {
    // Set initial ratings if provided
    myRating = initialMyRating ?? 1200;
    opponentRating = initialOpponentRating ?? 1200;
    print(
      "🎮 CaroController created with ratings: my=$myRating, opponent=$opponentRating (offline=$isOffline, vsBot=$isVsBot)",
    );

    // Initialize the board in the constructor
    initBoard();
  }

  // ==========================================================
  // 🔧 Setup board
  // ==========================================================
  void initBoard() {
    board = List.generate(rows, (_) => List.filled(cols, ""));
    currentTurn = "X";
    winningLine = null;
    lastMoveRow = null;
    lastMoveCol = null;
    isFinished = false;
    winnerId = null;
    moveCount = 0;
    timeLeft = 30;
    initialTimeLeft = 30;
    turnStartTime = DateTime.now();
    chatMessages.clear();
    rematchRequested = false;
    opponentRematchRequested = false;
    opponentLeft = false;

    if (isOffline) {
      mySymbol = "X";
      opponentSymbol = "O";
      myUserId = 1;
      opponentUserId = 2;
      myUsername = myUsername ?? "You (X)";
      opponentUsername = isVsBot ? "Bot AI (O)" : "Friend (O)";
      isConnected = true;
    } else {
      mySymbol = null;
      opponentSymbol = null;
      myUserId = null;
      opponentUserId = null;
    }
  }

  // ==========================================================
  // 🌐 Connect to the WebSocket using the existing matchId
  // ==========================================================
  Future<void> connectToServer() async {
    if (isOffline) {
      isConnected = true;
      _startTimerIfNeeded();
      notifyListeners();
      return;
    }

    try {
      final token = (await AuthService.getToken()) ?? "guest_token";

      final wsUrl = AppConfig.wsMatchUrl(matchId, token);
      _service = CaroService(
        wsUrl: wsUrl,
        onMessage: _handleServerMessage,
        onClose: _handleDisconnect,
      );

      await _service!.connect();
      isConnected = true;
      notifyListeners();

      print("🎮 Connected to Caro match $matchId");
    } catch (e) {
      print("❌ connectToServer error: $e");
    }
  }

  // ==========================================================
  // 🧠 Handle messages from the server
  // ==========================================================
  void _handleServerMessage(Map<String, dynamic> msg) {
    final type = msg["type"];
    final payload = msg["payload"] ?? {};

    print("📨 Received message: $type"); // DEBUG
    print("   Payload: $payload"); // DEBUG

    switch (type) {
      case "joined":
        // Receive the full snapshot from the server
        mySymbol = payload["you"]?["symbol"];
        myUserId = payload["you"]?["user_id"];
        opponentSymbol = mySymbol == "X" ? "O" : "X";
        currentTurn = payload["turn"] ?? "X";
        moveCount = payload["turn_no"] ?? 0;

        // Parse timeLeft carefully
        final timeLimitRaw = payload["time_left"];
        if (timeLimitRaw != null) {
          if (timeLimitRaw is int) {
            timeLeft = timeLimitRaw;
          } else if (timeLimitRaw is double) {
            timeLeft = timeLimitRaw.toInt();
          } else {
            timeLeft = int.tryParse(timeLimitRaw.toString());
          }
        }
        print("⏰ Time left from server: $timeLimitRaw → $timeLeft");

        // Load players
        final players = payload["players"] as List?;
        print(
          "🔍 DEBUG: Players from server: $players",
        ); // Debug full players data
        if (players != null) {
          for (var p in players) {
            final uid = p["user_id"];
            final username = p["username"];
            final rating = p["rating"]; // Get the rating from the server

            print(
              "🔍 DEBUG: Player - uid: $uid, username: $username, rating: $rating",
            ); // Debug each player

            if (uid == myUserId) {
              myUsername = username;
              myRating = rating;
              print("✅ Set myRating = $myRating"); // Confirm set
            } else {
              opponentUserId = uid;
              opponentUsername = username;
              opponentRating = rating;
              print("✅ Set opponentRating = $opponentRating"); // Confirm set
            }
          }
        }

        print(
          "👤 FINAL: My username: $myUsername (Rating: $myRating), Opponent: $opponentUsername (Rating: $opponentRating)",
        );

        // Load the board from the server
        final boardData = payload["board"] as List?;
        if (boardData != null && boardData.isNotEmpty) {
          for (int i = 0; i < boardData.length && i < rows; i++) {
            final row = boardData[i] as List;
            for (int j = 0; j < row.length && j < cols; j++) {
              board[i][j] = row[j]?.toString() ?? "";
            }
          }
        }

        notifyListeners();
        print("🙋 Joined match as $mySymbol (user_id: $myUserId)");
        _startTimerIfNeeded();
        break;

      case "start":
        currentTurn = payload["turn"];

        final timeLimitStart = payload["time_limit"];
        if (timeLimitStart != null) {
          if (timeLimitStart is int) {
            timeLeft = timeLimitStart;
          } else if (timeLimitStart is double) {
            timeLeft = timeLimitStart.toInt();
          } else {
            timeLeft = int.tryParse(timeLimitStart.toString()) ?? 30;
          }
        } else {
          // Fallback: use the default 30 seconds if the server doesn't send time_limit
          timeLeft = 30;
        }
        print("🚀 Game started — turn = $currentTurn, timeLeft = $timeLeft");

        notifyListeners();
        _startTimerIfNeeded();
        break;
      case "move":
        final x = payload["x"];
        final y = payload["y"];
        final symbol = payload["symbol"];
        board[x][y] = symbol;
        AudioService.instance.playMovePlacement();
        currentTurn = payload["next_turn"];
        moveCount = payload["turn_no"] ?? moveCount + 1;

        // CRITICAL: Stop timer cũ trước khi reset time
        _stopTimer();

        final timeLimitMove = payload["time_limit"];
        if (timeLimitMove != null) {
          if (timeLimitMove is int) {
            timeLeft = timeLimitMove;
          } else if (timeLimitMove is double) {
            timeLeft = timeLimitMove.toInt();
          } else {
            timeLeft = int.tryParse(timeLimitMove.toString()) ?? 30;
          }
        } else {
          // Fallback: reset to 30 seconds
          timeLeft = 30;
        }

        print(
          "📍 Move: ($x,$y) by $symbol, next turn: $currentTurn, timeLeft = $timeLeft",
        );

        notifyListeners();
        _startTimerIfNeeded();
        break;
      case "win":
        isFinished = true;
        winnerId = payload["winner_user_id"];

        // Update score
        if (winnerId == myUserId) {
          myWins++;
        } else {
          opponentWins++;
        }

        // Parse the rating change from the server
        final ratingChanges =
            payload["rating_changes"] as Map<String, dynamic>?;
        if (ratingChanges != null && myUserId != null) {
          myRatingChange = ratingChanges[myUserId.toString()];
          print("💎 Rating change: $myRatingChange");
        }

        // Parse winning line
        final line = payload["line"] as List?;
        if (line != null) {
          winningLine = WinningLineData(
            line.map((p) => Position(p["x"], p["y"])).toList(),
          );
        }

        notifyListeners();
        print("🏆 Winner: user $winnerId (Score: $myWins-$opponentWins)");
        break;

      case "draw":
        isFinished = true;
        winnerId = null;
        draws++;

        // Parse the rating change from the server (draw = 0)
        final ratingChanges =
            payload["rating_changes"] as Map<String, dynamic>?;
        if (ratingChanges != null && myUserId != null) {
          myRatingChange = ratingChanges[myUserId.toString()];
          print("💎 Rating change: $myRatingChange");
        }

        notifyListeners();
        print("🤝 Game ended in a draw (Total draws: $draws)");
        break;

      case "timeout":
        isFinished = true;
        winnerId = payload["winner_user_id"];
        timeLeft = 0; // Set to 0 to stop the timer

        // Update score
        if (winnerId == myUserId) {
          myWins++;
        } else {
          opponentWins++;
        }

        // Parse the rating change from the server
        final ratingChanges =
            payload["rating_changes"] as Map<String, dynamic>?;
        if (ratingChanges != null && myUserId != null) {
          myRatingChange = ratingChanges[myUserId.toString()];
          print("💎 Rating change: $myRatingChange");
        }

        notifyListeners();
        print(
          "⏰ Timeout! Loser: ${payload["loser_user_id"]}, Winner: user $winnerId (Score: $myWins-$opponentWins)",
        );
        break;

      case "surrender":
        isFinished = true;
        winnerId = payload["winner_user_id"];

        // Update score
        if (winnerId == myUserId) {
          myWins++;
        } else {
          opponentWins++;
        }

        // Parse the rating change from the server
        final ratingChanges =
            payload["rating_changes"] as Map<String, dynamic>?;
        if (ratingChanges != null && myUserId != null) {
          myRatingChange = ratingChanges[myUserId.toString()];
          print("💎 Rating change: $myRatingChange");
        }

        notifyListeners();
        print(
          "🏳️ Player ${payload["surrendered_user_id"]} surrendered (Score: $myWins-$opponentWins)",
        );
        break;

      case "disconnect":
        final disconnectedUserId = payload["disconnected_user_id"];

        // If the opponent disconnects while the end-game dialog is open or the game is in progress
        if (disconnectedUserId != myUserId) {
          opponentLeft = true;
          print("🔌 Opponent left! User $disconnectedUserId disconnected");
        }

        // Set the winner only if the game hasn't finished
        if (!isFinished) {
          isFinished = true;
          winnerId = payload["winner_user_id"];
        }

        notifyListeners();
        break;

      case "player_left":
        // Special case: a player leaves while the end-game dialog is open
        final leftUserId = payload["user_id"];
        if (leftUserId != myUserId) {
          opponentLeft = true;
          print("👋 Opponent left the room! User $leftUserId");
          notifyListeners();
        }
        break;

      case "chat":
        chatMessages.add({
          "from": payload["from"],
          "message": payload["message"],
          "time": payload["time"],
        });

        // Increment the unread count if the chat is closed
        if (!isChatOpen) {
          unreadMessageCount++;
        }

        notifyListeners();
        break;

      case "rematch_request":
        // Someone requested a rematch
        rematchRequestCount = payload["total_requests"] ?? 0;
        final fromUserId = payload["from_user_id"];

        // If the opponent requested a rematch
        if (fromUserId != myUserId) {
          opponentRematchRequested = true;
        }

        print(
          "🔄 Rematch request from user $fromUserId ($rematchRequestCount/2)",
        );
        notifyListeners();
        break;

      case "rematch_accepted":
        // Both players accepted; a new match is available
        newMatchId = payload["new_match_id"];
        print("✅ Rematch accepted! New match: $newMatchId");
        notifyListeners();
        break;

      case "rematch_cancelled":
        // Rematch was canceled because a player left
        opponentLeft = true;
        rematchRequested = false;
        opponentRematchRequested = false;
        print("❌ Rematch cancelled! Opponent left");
        notifyListeners();
        break;

      case "pong":
        // Response to ping
        break;

      case "error":
        print("⚠️ Error from server: $payload");
        break;

      default:
        print("📩 Unknown message: $msg");
    }
  }

  // Timer countdown
  void _startTimerIfNeeded() {
    if (timeLeft == null || isFinished || _isTimerRunning) return;

    // Save the initial value and start time
    initialTimeLeft = timeLeft;
    turnStartTime = DateTime.now();
    _isTimerRunning = true;
    _updateTimer();
  }

  void _updateTimer() {
    // CRITICAL: Check if disposed or stopped
    if (!_isTimerRunning ||
        isFinished ||
        turnStartTime == null ||
        initialTimeLeft == null) {
      _isTimerRunning = false;
      return;
    }

    // Calculate the remaining time based on elapsed time
    final elapsed = DateTime.now().difference(turnStartTime!).inSeconds;
    final remaining = (initialTimeLeft! - elapsed).clamp(0, 999);

    // Update UI
    if (remaining != timeLeft) {
      timeLeft = remaining;
      notifyListeners();
    }

    if (timeLeft! > 0 && !isFinished && _isTimerRunning) {
      Future.delayed(const Duration(seconds: 1), _updateTimer);
    } else {
      _isTimerRunning = false;
    }
  }

  void _stopTimer() {
    _isTimerRunning = false;
    turnStartTime = null;
  }

  // ==========================================================
  // ⏸️ Pause & Resume & Reset
  // ==========================================================
  void pauseGame() {
    if (isFinished || isPaused) return;
    isPaused = true;
    _stopTimer();
    notifyListeners();
  }

  void resumeGame() {
    if (!isPaused) return;
    isPaused = false;
    _startTimerIfNeeded();
    notifyListeners();
  }

  void togglePause() {
    if (isFinished) return;
    if (isPaused) {
      resumeGame();
    } else {
      pauseGame();
    }
  }

  void resetGame() {
    _stopTimer();
    isPaused = false;
    initBoard();
    _startTimerIfNeeded();
    notifyListeners();
  }

  // ==========================================================
  // ✉️ Move & surrender & rematch (Online & Offline)
  // ==========================================================
  void sendMove(int x, int y) {
    if (isFinished || isPaused) return;
    if (x < 0 || x >= rows || y < 0 || y >= cols) return;
    if (board[x][y].isNotEmpty) return;

    if (isOffline) {
      if (isVsBot && currentTurn != mySymbol) return;

      final symbol = currentTurn;
      board[x][y] = symbol;
      lastMoveRow = x;
      lastMoveCol = y;
      moveCount++;
      _stopTimer();
      AudioService.instance.playMovePlacement();

      final winPositions = _checkWinCondition(x, y, symbol);
      if (winPositions != null) {
        isFinished = true;
        winnerId = (symbol == "X" ? myUserId : opponentUserId);
        winningLine = WinningLineData(winPositions);
        if (winnerId == myUserId) {
          myWins++;
          myRatingChange = isVsBot ? 15 : 20;
          myRating = (myRating ?? 1200) + myRatingChange!;
        } else {
          opponentWins++;
          myRatingChange = isVsBot ? -10 : -15;
          myRating = (myRating ?? 1200) + myRatingChange!;
        }
        _recordOfflineMatchResult(winnerId == myUserId ? 'win' : 'loss');
        notifyListeners();
        return;
      }

      if (moveCount >= rows * cols) {
        isFinished = true;
        draws++;
        myRatingChange = 0;
        _recordOfflineMatchResult('draw');
        notifyListeners();
        return;
      }

      currentTurn = (symbol == "X" ? "O" : "X");
      timeLeft = 30;
      initialTimeLeft = 30;
      turnStartTime = DateTime.now();
      notifyListeners();
      _startTimerIfNeeded();

      if (isVsBot && currentTurn == "O" && !isFinished) {
        Future.delayed(const Duration(milliseconds: 350), () {
          if (!isFinished && currentTurn == "O") {
            _makeBotMove();
          }
        });
      }
      return;
    }

    if (!isConnected) return;
    final data = jsonEncode({
      "type": "move",
      "payload": {"x": x, "y": y},
    });
    _service?.send(data);
  }

  List<Position>? _checkWinCondition(int x, int y, String symbol) {
    final directions = [
      [0, 1],
      [1, 0],
      [1, 1],
      [1, -1],
    ];

    for (final dir in directions) {
      final dx = dir[0];
      final dy = dir[1];
      final line = <Position>[Position(x, y)];

      int r = x + dx;
      int c = y + dy;
      while (r >= 0 &&
          r < rows &&
          c >= 0 &&
          c < cols &&
          board[r][c] == symbol) {
        line.add(Position(r, c));
        r += dx;
        c += dy;
      }

      r = x - dx;
      c = y - dy;
      while (r >= 0 &&
          r < rows &&
          c >= 0 &&
          c < cols &&
          board[r][c] == symbol) {
        line.add(Position(r, c));
        r -= dx;
        c -= dy;
      }

      if (line.length >= winLen) {
        return line;
      }
    }
    return null;
  }

  void _makeBotMove() {
    if (isFinished) return;

    // Dynamic difficulty: as the player wins more matches, bot becomes significantly smarter
    // myWins 0: basic AI
    // myWins 1-2: strategic AI (forks, blocking open-twos)
    // myWins 3+: master AI (lookahead, center control, optimal defensive & offensive valuation)

    // 1. Instant Win check (streak of 3 for O)
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (board[r][c].isEmpty) {
          board[r][c] = "O";
          if (_checkWinCondition(r, c, "O") != null) {
            board[r][c] = "";
            _executeBotMove(r, c);
            return;
          }
          board[r][c] = "";
        }
      }
    }

    // 2. Immediate Block check (stop player X from getting streak of 3)
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (board[r][c].isEmpty) {
          board[r][c] = "X";
          if (_checkWinCondition(r, c, "X") != null) {
            board[r][c] = "";
            _executeBotMove(r, c);
            return;
          }
          board[r][c] = "";
        }
      }
    }

    // 3. For higher win counts (experienced bot), check 2-in-a-row threats & forks
    int bestScore = -1;
    Position? bestPos;

    final centerR = rows ~/ 2;
    final centerC = cols ~/ 2;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (board[r][c].isNotEmpty) continue;

        int score = 0;

        // Position evaluation: center preference
        final distToCenter = (r - centerR).abs() + (c - centerC).abs();
        score += (rows - distToCenter) * 2;

        // Check potential lines of length 3 in all directions
        final directions = [
          [0, 1],
          [1, 0],
          [1, 1],
          [1, -1],
        ];

        for (final dir in directions) {
          final dr = dir[0];
          final dc = dir[1];

          // Check window of winLen (5) centered around (r, c)
          for (int step = -(winLen - 1); step <= 0; step++) {
            int currentO = 0;
            int currentX = 0;
            bool validWindow = true;

            for (int k = 0; k < winLen; k++) {
              final nr = r + (step + k) * dr;
              final nc = c + (step + k) * dc;

              if (nr < 0 || nr >= rows || nc < 0 || nc >= cols) {
                validWindow = false;
                break;
              }

              if (nr == r && nc == c) {
                // this is candidate cell
                continue;
              }

              if (board[nr][nc] == "O") currentO++;
              if (board[nr][nc] == "X") currentX++;
            }

            if (validWindow) {
              // Bot attack scoring
              if (currentX == 0) {
                if (currentO == 4) {
                  score += 600; // 4 in window + candidate = 5 in a row WIN!
                } else if (currentO == 3) {
                  score += 180; // 3 in a row building towards 5
                } else if (currentO == 2) {
                  score += 40;
                } else if (currentO == 1) {
                  score += 10;
                } else {
                  score += 2;
                }
              }

              // Player defense scoring (blocks player build-up)
              if (currentO == 0) {
                if (currentX == 4) {
                  score += 550; // Critical block: stop player from getting 5 in a row!
                } else if (currentX == 3) {
                  // Block player 3-in-a-row threat
                  score += (myWins >= 2) ? 180 : 100;
                } else if (currentX == 2) {
                  score += (myWins >= 2) ? 50 : 25;
                } else if (currentX == 1) {
                  score += (myWins >= 2) ? 15 : 6;
                } else {
                  score += 2;
                }
              }
            }
          }

          // Immediate neighbor bonus
          for (int d = -1; d <= 1; d += 2) {
            final nr = r + d * dr;
            final nc = c + d * dc;
            if (nr >= 0 && nr < rows && nc >= 0 && nc < cols) {
              if (board[nr][nc] == "O") score += (myWins >= 1 ? 12 : 5);
              if (board[nr][nc] == "X") score += (myWins >= 2 ? 15 : 6);
            }
          }
        }

        if (score > bestScore) {
          bestScore = score;
          bestPos = Position(r, c);
        }
      }
    }

    final target = bestPos ?? Position(rows ~/ 2, cols ~/ 2);
    _executeBotMove(target.x, target.y);
  }

  void _executeBotMove(int x, int y) {
    if (isFinished || board[x][y].isNotEmpty) return;
    board[x][y] = "O";
    lastMoveRow = x;
    lastMoveCol = y;
    moveCount++;
    _stopTimer();
    AudioService.instance.playMovePlacement();

    final winPositions = _checkWinCondition(x, y, "O");
    if (winPositions != null) {
      isFinished = true;
      winnerId = opponentUserId;
      winningLine = WinningLineData(winPositions);
      opponentWins++;
      myRatingChange = -10;
      myRating = (myRating ?? 1200) + myRatingChange!;
      _recordOfflineMatchResult('loss');
      notifyListeners();
      return;
    }

    if (moveCount >= rows * cols) {
      isFinished = true;
      draws++;
      myRatingChange = 0;
      _recordOfflineMatchResult('draw');
      notifyListeners();
      return;
    }

    currentTurn = "X";
    timeLeft = 30;
    initialTimeLeft = 30;
    turnStartTime = DateTime.now();
    notifyListeners();
    _startTimerIfNeeded();
  }

  void _recordOfflineMatchResult(String result) {
    LocalStorageService.recordMatch(
      opponentUsername: opponentUsername ?? (isVsBot ? "Bot AI" : "Friend"),
      opponentAvatarUrl: null,
      opponentSymbol: opponentSymbol ?? "O",
      mySymbol: mySymbol ?? "X",
      result: result,
      totalMoves: moveCount,
      durationSeconds: 30,
      isVsBot: isVsBot,
    );
  }

  // ==========================================================
  // 💬 Chat methods
  // ==========================================================

  /// Opens the chat panel and resets the unread count.
  void openChat() {
    isChatOpen = true;
    unreadMessageCount = 0;
    notifyListeners();
  }

  /// Closes the chat panel.
  void closeChat() {
    isChatOpen = false;
    notifyListeners();
  }

  void sendChat(String text) {
    if (isOffline) {
      chatMessages.add({
        "from": "You",
        "message": text.trim(),
        "time":
            "${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}",
      });
      notifyListeners();
      return;
    }
    if (!isConnected || text.trim().isEmpty) return;
    final data = jsonEncode({
      "type": "chat",
      "payload": {"message": text.trim()},
    });
    _service?.send(data);
  }

  void surrender() {
    if (isFinished) return;
    if (isOffline) {
      isFinished = true;
      winnerId = (currentTurn == "X" ? opponentUserId : myUserId);
      if (winnerId == myUserId) {
        myWins++;
        myRatingChange = isVsBot ? 15 : 20;
        myRating = (myRating ?? 1200) + myRatingChange!;
        _recordOfflineMatchResult('win');
      } else {
        opponentWins++;
        myRatingChange = isVsBot ? -10 : -15;
        myRating = (myRating ?? 1200) + myRatingChange!;
        _recordOfflineMatchResult('loss');
      }
      notifyListeners();
      return;
    }
    if (!isConnected) return;
    final data = jsonEncode({"type": "surrender", "payload": {}});
    _service?.send(data);
  }

  void requestRematch() {
    if (!isFinished) return;
    if (isOffline) {
      newMatchId = (matchId + 1);
      rematchRequested = true;
      opponentRematchRequested = true;
      notifyListeners();
      return;
    }
    if (!isConnected) return;
    rematchRequested = true;
    notifyListeners();

    final data = jsonEncode({"type": "rematch", "payload": {}});
    _service?.send(data);
    print("🔄 Rematch request sent");
  }

  // ==========================================================
  // 🔌 Disconnect
  // ==========================================================
  void _handleDisconnect() {
    _stopTimer(); // Stop the timer when disconnecting
    isConnected = false;
    notifyListeners();
  }

  void disconnect() {
    _stopTimer(); // Stop the timer before disconnecting
    _service?.disconnect();
    isConnected = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopTimer(); // Stop the timer when disposing
    _service?.disconnect();
    super.dispose();
  }
}
