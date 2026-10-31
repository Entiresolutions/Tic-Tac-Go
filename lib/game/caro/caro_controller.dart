// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:tic_tac_go/configs/app_config.dart';
import 'package:tic_tac_go/services/auth_service.dart';
import 'package:tic_tac_go/services/audio_service.dart';
import 'package:tic_tac_go/services/caro_service.dart';
import 'package:tic_tac_go/services/local_storage_service.dart';
import 'package:tic_tac_go/game/caro/winning_line_data.dart';
import 'package:tic_tac_go/game/caro/game_config.dart';
import 'package:tic_tac_go/game/caro/bot_engine.dart';

/// Move history record for undo functionality.
class CaroMoveRecord {
  final int row;
  final int col;
  final String symbol;
  final int? prevLastRow;
  final int? prevLastCol;

  const CaroMoveRecord({
    required this.row,
    required this.col,
    required this.symbol,
    this.prevLastRow,
    this.prevLastCol,
  });
}

/// Manages Caro/Tic Tac GO game logic, dynamic configs, bot AI, undo, hints,
/// early draw detection, and progression.
class CaroController extends ChangeNotifier {
  final GameConfig config;
  final GameLevel? level;
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
  int? myRating;
  int? opponentRating;
  int? myRatingChange;
  bool isConnected = false;
  bool isFinished = false;
  int? winnerId;
  int moveCount = 0;
  WinningLineData? winningLine;
  int? lastMoveRow;
  int? lastMoveCol;

  // Progression & Celebration
  bool isMasterBeaten = false;
  GameLevel? newlyUnlockedLevel;
  String? drawReason;

  // Hint & Undo
  Position? hintCell;
  final List<CaroMoveRecord> moveHistory = [];

  // Start Banner state
  bool isStartBannerShowing = true;

  // Bot mistake management
  final Set<int> _botMistakeTurns = {};
  int _botTurnCount = 0;
  Timer? _botTimer;

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
  int? timeLeft;
  int? initialTimeLeft;
  DateTime? turnStartTime;
  bool _isTimerRunning = false;
  bool isPaused = false;
  CaroService? _service;

  // Chat messages
  List<Map<String, dynamic>> chatMessages = [];
  int unreadMessageCount = 0;
  bool isChatOpen = false;

  CaroController({
    GameConfig? config,
    this.level,
    int? rows,
    int? cols,
    int? winLen,
    required this.matchId,
    this.isOffline = false,
    this.isVsBot = false,
    int? initialMyRating,
    int? initialOpponentRating,
  })  : config = config ??
            (level?.config ??
                GameConfig.create(
                  level: level ?? GameLevel.master,
                  rows: rows ?? 7,
                  cols: cols ?? 7,
                  winLen: winLen ?? 5,
                  botMistakes: 0,
                )),
        rows = rows ?? (config?.rows ?? (level?.rows ?? 7)),
        cols = cols ?? (config?.cols ?? (level?.cols ?? 7)),
        winLen = winLen ?? (config?.winLen ?? (level?.winLen ?? 5)) {
    myRating = initialMyRating ?? 1200;
    opponentRating = initialOpponentRating ?? (isVsBot ? 1400 : 1200);

    initBoard();
  }

  // ==========================================================
  // 🔧 Setup Board
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
    hintCell = null;
    drawReason = null;
    newlyUnlockedLevel = null;
    isMasterBeaten = false;
    isStartBannerShowing = true;
    moveHistory.clear();

    _cancelBotTimer();
    _botTurnCount = 0;
    _botMistakeTurns.clear();
    final mistakes = config.botMistakes;
    if (mistakes > 0) {
      final random = Random();
      while (_botMistakeTurns.length < mistakes) {
        _botMistakeTurns.add(random.nextInt(6) + 1);
      }
    }

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

  void dismissStartBanner() {
    if (!isStartBannerShowing) return;
    isStartBannerShowing = false;
    _startTimerIfNeeded();
    notifyListeners();
  }

  void _cancelBotTimer() {
    _botTimer?.cancel();
    _botTimer = null;
  }

  // ==========================================================
  // 💡 Hint & Undo Support
  // ==========================================================
  bool get canUndo =>
      !isFinished && moveHistory.isNotEmpty && !isStartBannerShowing;

  void requestHint() {
    if (isFinished || isPaused || isStartBannerShowing) return;
    if (isVsBot && currentTurn != mySymbol) return;

    final hint = BotEngine.findHintMove(
      board: board,
      config: config,
      playerSymbol: currentTurn,
    );
    hintCell = hint;
    notifyListeners();
  }

  void clearHint() {
    if (hintCell != null) {
      hintCell = null;
      notifyListeners();
    }
  }

  void undoMove() {
    if (!canUndo) return;

    _cancelBotTimer();
    hintCell = null;

    if (isVsBot) {
      // Revert bot's move first if it exists
      if (moveHistory.isNotEmpty && moveHistory.last.symbol == "O") {
        final botMove = moveHistory.removeLast();
        board[botMove.row][botMove.col] = "";
        moveCount = (moveCount - 1).clamp(0, rows * cols);
      }
      // Then revert user's move
      if (moveHistory.isNotEmpty && moveHistory.last.symbol == "X") {
        final userMove = moveHistory.removeLast();
        board[userMove.row][userMove.col] = "";
        moveCount = (moveCount - 1).clamp(0, rows * cols);
      }
      currentTurn = "X";
    } else {
      // 2 Players mode: revert exactly one move
      final lastMove = moveHistory.removeLast();
      board[lastMove.row][lastMove.col] = "";
      moveCount = (moveCount - 1).clamp(0, rows * cols);
      currentTurn = lastMove.symbol;
    }

    if (moveHistory.isNotEmpty) {
      lastMoveRow = moveHistory.last.row;
      lastMoveCol = moveHistory.last.col;
    } else {
      lastMoveRow = null;
      lastMoveCol = null;
    }

    // Reset turn timer to 30s
    _stopTimer();
    timeLeft = 30;
    initialTimeLeft = 30;
    turnStartTime = DateTime.now();
    notifyListeners();
    _startTimerIfNeeded();
  }

  // ==========================================================
  // 🌐 Connect to WebSocket (Online matches)
  // ==========================================================
  Future<void> connectToServer() async {
    if (isOffline) {
      isConnected = true;
      if (!isStartBannerShowing) {
        _startTimerIfNeeded();
      }
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
    } catch (e) {
      print("❌ connectToServer error: $e");
    }
  }

  void _handleServerMessage(Map<String, dynamic> msg) {
    final type = msg["type"];
    final payload = msg["payload"] ?? {};

    switch (type) {
      case "joined":
        mySymbol = payload["you"]?["symbol"];
        myUserId = payload["you"]?["user_id"];
        opponentSymbol = mySymbol == "X" ? "O" : "X";
        currentTurn = payload["turn"] ?? "X";
        moveCount = payload["turn_no"] ?? 0;

        final timeLimitRaw = payload["time_left"];
        if (timeLimitRaw != null) {
          timeLeft = int.tryParse(timeLimitRaw.toString()) ?? 30;
        }

        final players = payload["players"] as List?;
        if (players != null) {
          for (var p in players) {
            final uid = p["user_id"];
            final username = p["username"];
            final rating = p["rating"];

            if (uid == myUserId) {
              myUsername = username;
              myRating = rating;
            } else {
              opponentUserId = uid;
              opponentUsername = username;
              opponentRating = rating;
            }
          }
        }

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
        _startTimerIfNeeded();
        break;

      case "start":
        currentTurn = payload["turn"];
        final timeLimitStart = payload["time_limit"];
        timeLeft = int.tryParse(timeLimitStart.toString()) ?? 30;
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
        _stopTimer();

        final timeLimitMove = payload["time_limit"];
        timeLeft = int.tryParse(timeLimitMove.toString()) ?? 30;

        notifyListeners();
        _startTimerIfNeeded();
        break;

      case "win":
        isFinished = true;
        winnerId = payload["winner_user_id"];
        if (winnerId == myUserId) {
          myWins++;
        } else {
          opponentWins++;
        }

        final line = payload["line"] as List?;
        if (line != null) {
          winningLine = WinningLineData(
            line.map((p) => Position(p["x"], p["y"])).toList(),
          );
        }

        notifyListeners();
        break;

      case "draw":
        isFinished = true;
        winnerId = null;
        draws++;
        notifyListeners();
        break;

      case "timeout":
      case "surrender":
        isFinished = true;
        winnerId = payload["winner_user_id"];
        if (winnerId == myUserId) {
          myWins++;
        } else {
          opponentWins++;
        }
        notifyListeners();
        break;

      case "disconnect":
      case "player_left":
        final leftUserId = payload["user_id"] ?? payload["disconnected_user_id"];
        if (leftUserId != myUserId) {
          opponentLeft = true;
        }
        if (!isFinished) {
          isFinished = true;
          winnerId = payload["winner_user_id"];
        }
        notifyListeners();
        break;

      case "chat":
        chatMessages.add({
          "from": payload["from"],
          "message": payload["message"],
          "time": payload["time"],
        });
        if (!isChatOpen) unreadMessageCount++;
        notifyListeners();
        break;

      case "rematch_request":
        rematchRequestCount = payload["total_requests"] ?? 0;
        final fromUserId = payload["from_user_id"];
        if (fromUserId != myUserId) {
          opponentRematchRequested = true;
        }
        notifyListeners();
        break;

      case "rematch_accepted":
        newMatchId = payload["new_match_id"];
        notifyListeners();
        break;

      case "rematch_cancelled":
        opponentLeft = true;
        rematchRequested = false;
        opponentRematchRequested = false;
        notifyListeners();
        break;

      default:
        break;
    }
  }

  // ==========================================================
  // ⏱️ Turn Timer
  // ==========================================================
  void _startTimerIfNeeded() {
    if (isStartBannerShowing) return;
    if (timeLeft == null || isFinished || _isTimerRunning) return;

    initialTimeLeft = timeLeft;
    turnStartTime = DateTime.now();
    _isTimerRunning = true;
    _updateTimer();
  }

  void _updateTimer() {
    if (!_isTimerRunning ||
        isFinished ||
        isStartBannerShowing ||
        turnStartTime == null ||
        initialTimeLeft == null) {
      _isTimerRunning = false;
      return;
    }

    final elapsed = DateTime.now().difference(turnStartTime!).inSeconds;
    final remaining = (initialTimeLeft! - elapsed).clamp(0, 999);

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
  // ⏸️ Pause & Resume
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
    if (!isStartBannerShowing) {
      _startTimerIfNeeded();
    }
    notifyListeners();
  }

  void resetGame() {
    _stopTimer();
    isPaused = false;
    initBoard();
    notifyListeners();
  }

  // ==========================================================
  // ♟️ Game Moves & Early Draw Detection
  // ==========================================================
  void sendMove(int x, int y) {
    if (isStartBannerShowing) return;
    if (isFinished || isPaused) return;
    if (x < 0 || x >= rows || y < 0 || y >= cols) return;
    if (board[x][y].isNotEmpty) return;

    if (isOffline) {
      if (isVsBot && currentTurn != mySymbol) return;

      hintCell = null;
      final symbol = currentTurn;
      board[x][y] = symbol;

      moveHistory.add(CaroMoveRecord(
        row: x,
        col: y,
        symbol: symbol,
        prevLastRow: lastMoveRow,
        prevLastCol: lastMoveCol,
      ));

      lastMoveRow = x;
      lastMoveCol = y;
      moveCount++;
      _stopTimer();
      AudioService.instance.playMovePlacement();

      // 1. Win Check
      final winPositions = _checkWinCondition(x, y, symbol);
      if (winPositions != null) {
        isFinished = true;
        winnerId = (symbol == "X" ? myUserId : opponentUserId);
        winningLine = WinningLineData(winPositions);
        if (winnerId == myUserId) {
          myWins++;
          myRatingChange = isVsBot ? 15 : 20;
          myRating = (myRating ?? 1200) + myRatingChange!;

          // Progression unlock logic on winning against Bot
          if (isVsBot && level != null) {
            if (level == GameLevel.master) {
              isMasterBeaten = true;
            }
            final nextIdx = level!.index + 1;
            if (nextIdx < GameLevel.values.length) {
              final nextLevel = GameLevel.values[nextIdx];
              LocalStorageService.unlockBotLevel(nextLevel);
              newlyUnlockedLevel = nextLevel;
            }
          }
        } else {
          opponentWins++;
          myRatingChange = isVsBot ? -10 : -15;
          myRating = (myRating ?? 1200) + myRatingChange!;
        }
        _recordOfflineMatchResult(winnerId == myUserId ? 'win' : 'loss');
        notifyListeners();
        return;
      }

      // 2. Full Board Draw Check
      if (moveCount >= rows * cols) {
        isFinished = true;
        draws++;
        myRatingChange = 0;
        _recordOfflineMatchResult('draw');
        notifyListeners();
        return;
      }

      // 3. Early Dead-Position Draw Check
      final nextTurn = (symbol == "X" ? "O" : "X");
      if (config.isDeadPosition(board, nextTurn)) {
        isFinished = true;
        draws++;
        drawReason = "No winning line left";
        myRatingChange = 0;
        _recordOfflineMatchResult('draw');
        notifyListeners();
        return;
      }

      currentTurn = nextTurn;
      timeLeft = 30;
      initialTimeLeft = 30;
      turnStartTime = DateTime.now();
      notifyListeners();
      _startTimerIfNeeded();

      // Trigger bot turn after 350ms delay
      if (isVsBot && currentTurn == "O" && !isFinished) {
        _cancelBotTimer();
        _botTimer = Timer(const Duration(milliseconds: 350), () {
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

    _botTurnCount++;
    final bool isMistake = _botMistakeTurns.contains(_botTurnCount);

    final bestMove = BotEngine.findBestMove(
      board: board,
      config: config,
      botSymbol: "O",
      humanSymbol: "X",
      isMistakeTurn: isMistake,
    );

    _executeBotMove(bestMove.x, bestMove.y);
  }

  void _executeBotMove(int x, int y) {
    if (isFinished || board[x][y].isNotEmpty) return;

    board[x][y] = "O";
    moveHistory.add(CaroMoveRecord(
      row: x,
      col: y,
      symbol: "O",
      prevLastRow: lastMoveRow,
      prevLastCol: lastMoveCol,
    ));

    lastMoveRow = x;
    lastMoveCol = y;
    moveCount++;
    _stopTimer();
    AudioService.instance.playMovePlacement();

    // 1. Bot Win Check
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

    // 2. Full Board Draw Check
    if (moveCount >= rows * cols) {
      isFinished = true;
      draws++;
      myRatingChange = 0;
      _recordOfflineMatchResult('draw');
      notifyListeners();
      return;
    }

    // 3. Early Dead-Position Draw Check
    if (config.isDeadPosition(board, "X")) {
      isFinished = true;
      draws++;
      drawReason = "No winning line left";
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
      levelName: level?.displayName,
      boardRows: rows,
      boardCols: cols,
    );
  }

  // ==========================================================
  // 💬 Chat & Online Actions
  // ==========================================================
  void openChat() {
    isChatOpen = true;
    unreadMessageCount = 0;
    notifyListeners();
  }

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
    _service?.send(jsonEncode({"type": "rematch", "payload": {}}));
  }

  void _handleDisconnect() {
    _stopTimer();
    _cancelBotTimer();
    isConnected = false;
    notifyListeners();
  }

  void disconnect() {
    _stopTimer();
    _cancelBotTimer();
    _service?.disconnect();
    isConnected = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopTimer();
    _cancelBotTimer();
    _service?.disconnect();
    super.dispose();
  }
}
