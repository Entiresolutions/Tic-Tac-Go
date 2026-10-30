// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:tic_tac_go/configs/app_config.dart';
import 'package:tic_tac_go/services/auth_service.dart';

class CaroService {
  // ==============================
  // 🔌 WebSocket fields
  // ==============================
  final String wsUrl;
  final void Function(Map<String, dynamic>) onMessage;
  final void Function() onClose;

  WebSocketChannel? _channel;

  CaroService({
    required this.wsUrl,
    required this.onMessage,
    required this.onClose,
  });

  /// Create or join an online Caro match
  static Future<int?> joinMatch({String gameName = "Caro"}) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception("Missing token");

      final uri = Uri.parse("${AppConfig.baseUrl}/api/matches/join");
      final res = await http.post(
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"game_name": gameName}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final id = data["match_id"];
        print("🎮 Joined match id: $id");
        return id;
      } else {
        print("❌ joinMatch failed (${res.statusCode}): ${res.body}");
      }
    } catch (e) {
      print("⚠️ joinMatch error: $e");
    }
    return null;
  }

  /// Get match information (if needed)
  static Future<Map<String, dynamic>?> getMatchInfo(int matchId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception("Missing token");

      final uri = Uri.parse("${AppConfig.baseUrl}/api/matches/$matchId");
      final res = await http.get(
        uri,
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        print("❌ getMatchInfo failed (${res.statusCode}): ${res.body}");
      }
    } catch (e) {
      print("⚠️ getMatchInfo error: $e");
    }
    return null;
  }

  Future<int?> quickJoinMatch() async {
    final token = await AuthService.getToken();
    final url = Uri.parse("${AppConfig.baseUrl}/api/matches/join");

    final res = await http.post(
      url,
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data["match_id"];
    } else {
      print("❌ Join failed: ${res.body}");
      return null;
    }
  }

  // ==============================
  // ⚡ WebSocket methods
  // ==============================

  Future<void> connect() async {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      print("✅ Connected to $wsUrl");

      _channel!.stream.listen(
        (data) {
          try {
            final msg = jsonDecode(data);
            if (msg is Map<String, dynamic>) onMessage(msg);
          } catch (e) {
            print("⚠️ Parse error: $e");
          }
        },
        onDone: () {
          print("🔌 Disconnected from WS");
          onClose();
        },
        onError: (err) {
          print("❌ WebSocket error: $err");
          onClose();
        },
      );
    } catch (e) {
      print("❌ Failed to connect WS: $e");
      onClose();
    }
  }

  void send(String text) {
    try {
      _channel?.sink.add(text);
    } catch (e) {
      print("⚠️ Send failed: $e");
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }
}
