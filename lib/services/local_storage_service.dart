import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../game/caro/game_config.dart';
import '../models/match_history_model.dart';
import '../models/leaderboard_model.dart';
import '../models/profile_model.dart';
import '../models/user_model.dart';

/// Service managing all offline/local game storage (Profile, History, Leaderboard, Stats, Levels)
/// using SharedPreferences. No backend or database required.
class LocalStorageService {
  static const String _keyProfile = 'local_user_profile';
  static const String _keyMatches = 'local_match_history';
  static const String keyIsDarkMode = 'is_dark_mode';
  static const String keyBotUnlockedLevel = 'bot_unlocked_level';

  static SharedPreferences? _prefs;

  @visibleForTesting
  static void resetPrefsForTesting([SharedPreferences? prefs]) => _prefs = prefs;

  static Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Get highest unlocked bot level (defaults to Beginner)
  static Future<GameLevel> getBotUnlockedLevel() async {
    try {
      final prefs = await _getPrefs();
      final index = prefs.getInt(keyBotUnlockedLevel) ?? 0;
      if (index < 0 || index >= GameLevel.values.length) return GameLevel.beginner;
      return GameLevel.values[index];
    } catch (_) {
      return GameLevel.beginner;
    }
  }

  /// Unlocks next bot progression level if newly achieved
  static Future<bool> unlockBotLevel(GameLevel nextLevel) async {
    try {
      final prefs = await _getPrefs();
      final current = await getBotUnlockedLevel();
      if (nextLevel.index > current.index) {
        await prefs.setInt(keyBotUnlockedLevel, nextLevel.index);
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Get current dark mode preference (defaults to false / Light Mode)
  static Future<bool> isDarkMode() async {
    try {
      final prefs = await _getPrefs();
      return prefs.getBool(keyIsDarkMode) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Save dark mode preference
  static Future<void> setDarkMode(bool isDark) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setBool(keyIsDarkMode, isDark);
    } catch (_) {}
  }

  /// Initialize default local user profile if not present
  static Future<MyProfile> getOrCreateProfile() async {
    final prefs = await _getPrefs();
    final profileStr = prefs.getString(_keyProfile);
    if (profileStr != null) {
      try {
        final map = jsonDecode(profileStr) as Map<String, dynamic>;
        return MyProfile.fromJson(map);
      } catch (e) {
        // Fallback to default if corrupt
      }
    }

    final defaultProfile = MyProfile(
      id: 1,
      username: 'Player 1',
      email: 'player@local.game',
      avatarUrl: null,
      bio: 'Caro Master in training',
      provider: 'local',
      createdAt: DateTime.now(),
      rating: 1200,
      totalMatches: 0,
      wins: 0,
      losses: 0,
      draws: 0,
      winRate: 0.0,
      totalFriends: 0,
    );

    await saveProfile(defaultProfile);
    return defaultProfile;
  }

  /// Save profile changes locally
  static Future<void> saveProfile(MyProfile profile) async {
    final prefs = await _getPrefs();
    final map = {
      'id': profile.id,
      'username': profile.username,
      'email': profile.email,
      'avatar_url': profile.avatarUrl,
      'bio': profile.bio,
      'provider': profile.provider,
      'created_at': profile.createdAt.toIso8601String(),
      'rating': profile.rating,
      'total_matches': profile.totalMatches,
      'wins': profile.wins,
      'losses': profile.losses,
      'draws': profile.draws,
      'win_rate': profile.winRate,
      'total_friends': profile.totalFriends,
    };
    await prefs.setString(_keyProfile, jsonEncode(map));
  }

  /// Get profile as UserModel for UI header
  static Future<UserModel> getCurrentUserModel() async {
    final profile = await getOrCreateProfile();
    return UserModel(
      id: profile.id,
      username: profile.username,
      email: profile.email,
      avatarUrl: profile.avatarUrl,
      rating: profile.rating,
    );
  }

  /// Record finished match result and update stats & rating
  static Future<void> recordMatch({
    required String opponentUsername,
    required String? opponentAvatarUrl,
    required String opponentSymbol,
    required String mySymbol,
    required String result, // 'win', 'loss', 'draw'
    required int totalMoves,
    required int durationSeconds,
    required bool isVsBot,
    String? levelName,
    int boardRows = 7,
    int boardCols = 7,
  }) async {
    final profile = await getOrCreateProfile();

    int newWins = profile.wins + (result == 'win' ? 1 : 0);
    int newLosses = profile.losses + (result == 'loss' ? 1 : 0);
    int newDraws = profile.draws + (result == 'draw' ? 1 : 0);
    int newTotal = profile.totalMatches + 1;
    double newWinRate = newTotal > 0 ? (newWins / newTotal) * 100 : 0.0;

    // Rating calculation
    int ratingDelta = 0;
    if (result == 'win') {
      ratingDelta = isVsBot ? 15 : 20;
    } else if (result == 'loss') {
      ratingDelta = isVsBot ? -10 : -15;
    }
    int newRating = (profile.rating + ratingDelta).clamp(400, 3000);

    final updatedProfile = MyProfile(
      id: profile.id,
      username: profile.username,
      email: profile.email,
      avatarUrl: profile.avatarUrl,
      bio: profile.bio,
      provider: profile.provider,
      createdAt: profile.createdAt,
      rating: newRating,
      totalMatches: newTotal,
      wins: newWins,
      losses: newLosses,
      draws: newDraws,
      winRate: double.parse(newWinRate.toStringAsFixed(1)),
      totalFriends: profile.totalFriends,
    );
    await saveProfile(updatedProfile);

    // Save match in history
    final prefs = await _getPrefs();
    final matchId = DateTime.now().millisecondsSinceEpoch;
    final historyItem = MatchHistoryItem(
      matchId: matchId,
      gameName: isVsBot
          ? 'Tic Tac GO (vs Bot${levelName != null ? ' - $levelName' : ''})'
          : 'Tic Tac GO (2 Players${levelName != null ? ' - $levelName' : ''})',
      status: 'finished',
      result: result,
      opponentUsername: opponentUsername,
      opponentAvatarUrl: opponentAvatarUrl,
      opponentSymbol: opponentSymbol,
      mySymbol: mySymbol,
      boardRows: boardRows,
      boardCols: boardCols,
      totalMoves: totalMoves,
      createdAt: DateTime.now().subtract(Duration(seconds: durationSeconds)),
      startedAt: DateTime.now().subtract(Duration(seconds: durationSeconds)),
      finishedAt: DateTime.now(),
      durationSeconds: durationSeconds,
    );

    final historyList = await getMatches();
    historyList.insert(0, historyItem);

    final encoded = historyList.map((item) => {
      'match_id': item.matchId,
      'game_name': item.gameName,
      'status': item.status,
      'result': item.result,
      'opponent_username': item.opponentUsername,
      'opponent_avatar_url': item.opponentAvatarUrl,
      'opponent_symbol': item.opponentSymbol,
      'my_symbol': item.mySymbol,
      'board_rows': item.boardRows,
      'board_cols': item.boardCols,
      'total_moves': item.totalMoves,
      'created_at': item.createdAt.toIso8601String(),
      'started_at': item.startedAt?.toIso8601String(),
      'finished_at': item.finishedAt?.toIso8601String(),
      'duration_seconds': item.durationSeconds,
    }).toList();

    await prefs.setString(_keyMatches, jsonEncode(encoded));
  }

  /// Retrieve match history
  static Future<List<MatchHistoryItem>> getMatches({String? result}) async {
    final prefs = await _getPrefs();
    final str = prefs.getString(_keyMatches);
    if (str == null || str.isEmpty) return [];

    try {
      final list = jsonDecode(str) as List;
      final items = list
          .map((m) => MatchHistoryItem.fromJson(m as Map<String, dynamic>))
          .toList();
      if (result != null && result.isNotEmpty) {
        return items.where((i) => i.result == result).toList();
      }
      return items;
    } catch (e) {
      return [];
    }
  }

  /// Retrieve leaderboard entries with local player included
  static Future<List<LeaderboardEntry>> getLeaderboard({String? search}) async {
    final profile = await getOrCreateProfile();

    final botEntries = [
      LeaderboardEntry(
        rank: 1,
        userId: 901,
        username: "Grandmaster AI",
        rating: 2150,
        wins: 142,
        losses: 12,
        draws: 8,
        totalGames: 162,
        winRate: 87.7,
        isOnline: true,
        isFriend: false,
        hasPendingRequest: false,
      ),
      LeaderboardEntry(
        rank: 2,
        userId: 902,
        username: "Dragon Slayer",
        rating: 1850,
        wins: 89,
        losses: 35,
        draws: 14,
        totalGames: 138,
        winRate: 64.5,
        isOnline: true,
        isFriend: true,
        hasPendingRequest: false,
      ),
      LeaderboardEntry(
        rank: 3,
        userId: 903,
        username: "CaroBot (Hard)",
        rating: 1600,
        wins: 54,
        losses: 40,
        draws: 10,
        totalGames: 104,
        winRate: 51.9,
        isOnline: true,
        isFriend: false,
        hasPendingRequest: false,
      ),
      LeaderboardEntry(
        rank: 4,
        userId: profile.id,
        username: profile.username,
        avatarUrl: profile.avatarUrl,
        rating: profile.rating,
        wins: profile.wins,
        losses: profile.losses,
        draws: profile.draws,
        totalGames: profile.totalMatches,
        winRate: profile.winRate,
        isOnline: true,
        isFriend: false,
        hasPendingRequest: false,
        isCurrentUser: true,
      ),
      LeaderboardEntry(
        rank: 5,
        userId: 904,
        username: "Beginner Bot",
        rating: 1100,
        wins: 15,
        losses: 45,
        draws: 5,
        totalGames: 65,
        winRate: 23.1,
        isOnline: true,
        isFriend: false,
        hasPendingRequest: false,
      ),
    ];

    // Sort by rating desc
    botEntries.sort((a, b) => b.rating.compareTo(a.rating));

    // Reassign ranks
    final ranked = <LeaderboardEntry>[];
    for (int i = 0; i < botEntries.length; i++) {
      final e = botEntries[i];
      ranked.add(LeaderboardEntry(
        rank: i + 1,
        userId: e.userId,
        username: e.username,
        avatarUrl: e.avatarUrl,
        rating: e.rating,
        wins: e.wins,
        losses: e.losses,
        draws: e.draws,
        totalGames: e.totalGames,
        winRate: e.winRate,
        isOnline: e.isOnline,
        isFriend: e.isFriend,
        hasPendingRequest: e.hasPendingRequest,
        isCurrentUser: e.isCurrentUser,
      ));
    }

    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      return ranked.where((e) => e.username.toLowerCase().contains(q)).toList();
    }

    return ranked;
  }
}
