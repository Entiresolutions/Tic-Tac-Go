import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tic_tac_go/game/caro/game_config.dart';
import 'package:tic_tac_go/game/caro/caro_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (MethodCall methodCall) async => 1,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (MethodCall methodCall) async => 1,
    );
  });

  group('Early Dead-Position Draw Detection', () {
    test('3x3 position where every line is blocked triggers early draw', () {
      final config = GameLevel.beginner.config; // 3x3, winLen: 3
      expect(config.rows, 3);
      expect(config.cols, 3);
      expect(config.winLen, 3);

      // Board state:
      // X | O | X
      // X | O | O
      // O | X | (empty)
      final List<List<String>> board = [
        ['X', 'O', 'X'],
        ['X', 'O', 'O'],
        ['O', 'X', ''],
      ];

      // Even though (2,2) is empty, every row, column, and diagonal contains
      // both X and O. Neither player can ever complete 3 in a row.
      final isDeadForX = config.isDeadPosition(board, 'X');
      final isDeadForO = config.isDeadPosition(board, 'O');

      expect(isDeadForX, isTrue);
      expect(isDeadForO, isTrue);
    });

    test('3x3 position where a line is still open does NOT trigger draw', () {
      final config = GameLevel.beginner.config; // 3x3, winLen: 3

      // Board state:
      // X | X | (empty)  <- X can win with 1 move!
      // O | O | (empty)  <- O can win too!
      //   |   | (empty)
      final List<List<String>> board = [
        ['X', 'X', ''],
        ['O', 'O', ''],
        ['', '', ''],
      ];

      final isDead = config.isDeadPosition(board, 'X');
      expect(isDead, isFalse);
    });

    test('All 6 GameLevel configurations match specification', () {
      // 1. Beginner: 3x3, win streak 3, bot mistakes 3
      expect(GameLevel.beginner.rows, 3);
      expect(GameLevel.beginner.cols, 3);
      expect(GameLevel.beginner.winLen, 3);
      expect(GameLevel.beginner.botMistakes, 3);

      // 2. Easy: 4x4, win streak 3, bot mistakes 2
      expect(GameLevel.easy.rows, 4);
      expect(GameLevel.easy.cols, 4);
      expect(GameLevel.easy.winLen, 3);
      expect(GameLevel.easy.botMistakes, 2);

      // 3. Medium: 5x5, win streak 4, bot mistakes 2
      expect(GameLevel.medium.rows, 5);
      expect(GameLevel.medium.cols, 5);
      expect(GameLevel.medium.winLen, 4);
      expect(GameLevel.medium.botMistakes, 2);

      // 4. Hard: 6x6, win streak 5, bot mistakes 2
      expect(GameLevel.hard.rows, 6);
      expect(GameLevel.hard.cols, 6);
      expect(GameLevel.hard.winLen, 5);
      expect(GameLevel.hard.botMistakes, 2);

      // 5. Very Hard: 7x7, win streak 7, bot mistakes 1
      expect(GameLevel.veryHard.rows, 7);
      expect(GameLevel.veryHard.cols, 7);
      expect(GameLevel.veryHard.winLen, 7);
      expect(GameLevel.veryHard.botMistakes, 1);

      // 6. Master: 8x8, win streak 8, bot mistakes 0
      expect(GameLevel.master.rows, 8);
      expect(GameLevel.master.cols, 8);
      expect(GameLevel.master.winLen, 8);
      expect(GameLevel.master.botMistakes, 0);
    });

    test('CaroController triggers early draw when dead position occurs', () async {
      final controller = CaroController(
        level: GameLevel.beginner,
        matchId: 1001,
        isOffline: true,
        isVsBot: false,
      );

      // Set up board just 1 move before the dead position:
      // X | O | X
      // X | O | O
      // O |   |  
      controller.board = [
        ['X', 'O', 'X'],
        ['X', 'O', 'O'],
        ['O', '', ''],
      ];
      controller.currentTurn = 'X';
      controller.isStartBannerShowing = false;

      // X plays at (2, 1) -> every line is now blocked
      controller.sendMove(2, 1);

      expect(controller.isFinished, isTrue);
      expect(controller.drawReason, equals('No winning line left'));
      expect(controller.draws, equals(1));
    });

    test('Undo reverts moves and resets turn timer', () {
      final controller = CaroController(
        level: GameLevel.beginner,
        matchId: 1002,
        isOffline: true,
        isVsBot: false,
      );
      controller.isStartBannerShowing = false;

      controller.sendMove(0, 0); // X moves
      expect(controller.board[0][0], equals('X'));
      expect(controller.currentTurn, equals('O'));
      expect(controller.canUndo, isTrue);

      controller.undoMove();
      expect(controller.board[0][0], equals(''));
      expect(controller.currentTurn, equals('X'));
      expect(controller.timeLeft, equals(30));
    });
  });
}
