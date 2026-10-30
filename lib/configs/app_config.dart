import 'package:flutter_dotenv/flutter_dotenv.dart';

/// General app configuration, loaded from .env.
class AppConfig {
  /// Base HTTP URL for the REST API.
  static String get baseUrl =>
      dotenv.env['BASE_URL'] ?? 'http://localhost:8000';

  /// Base WebSocket URL for real-time updates (automatically converts http ↔ ws).
  static String get wsBaseUrl {
    final url = baseUrl;
    if (url.startsWith('https')) {
      return url.replaceFirst('https', 'wss');
    } else {
      return url.replaceFirst('http', 'ws');
    }
  }

  /// Generates the complete match WebSocket URL.
  static String wsMatchUrl(int matchId, String token) {
    return "$wsBaseUrl/ws/match/$matchId?token=$token";
  }

  /// Generates the complete matchmaking WebSocket URL.
  static String wsMatchmakingUrl(String token) {
    // Ensure proper WebSocket path with /ws/ prefix
    final baseWs = wsBaseUrl;
    // Remove trailing slash if exists
    final cleanBase = baseWs.endsWith('/')
        ? baseWs.substring(0, baseWs.length - 1)
        : baseWs;
    return "$cleanBase/ws/matchmaking?token=$token";
  }
}
