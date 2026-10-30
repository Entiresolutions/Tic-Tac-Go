import 'package:dio/dio.dart';
import '../models/room_model.dart';
import '../configs/app_config.dart';
import 'auth_service.dart';

class RoomService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  // Helper to add the token to the header
  static Future<Options> _getAuthOptions() async {
    final token = await AuthService.getToken();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  /// Create a new room
  static Future<RoomDetail> createRoom(CreateRoomRequest request) async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.post(
        '/api/rooms/create',
        data: request.toJson(),
        options: options,
      );

      return RoomDetail.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get the room list
  static Future<List<RoomListItem>> getRoomList({
    String? status,
    bool onlyPublic = true,
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.get(
        '/api/rooms/list',
        queryParameters: {
          if (status != null) 'status': status,
          'only_public': onlyPublic,
          'skip': skip,
          'limit': limit,
        },
        options: options,
      );

      return (response.data as List)
          .map((json) => RoomListItem.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Join a room using its room code
  static Future<RoomDetail> joinRoom({
    required String roomCode,
    String? password,
  }) async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.post(
        '/api/rooms/join',
        data: {
          'room_code': roomCode,
          if (password != null && password.isNotEmpty) 'password': password,
        },
        options: options,
      );

      return RoomDetail.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Join a room using its ID (from the list)
  static Future<RoomDetail> joinRoomById({
    required int roomId,
    String? password,
  }) async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.post(
        '/api/rooms/$roomId/join',
        data: {
          if (password != null && password.isNotEmpty) 'password': password,
        },
        options: options,
      );

      return RoomDetail.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get room details
  static Future<RoomDetail> getRoomDetail(int roomId) async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.get('/api/rooms/$roomId', options: options);

      return RoomDetail.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Toggle ready status
  static Future<Map<String, dynamic>> toggleReady({
    required int roomId,
    required bool isReady,
  }) async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.post(
        '/api/rooms/$roomId/ready',
        data: {'is_ready': isReady},
        options: options,
      );

      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Kick player (Host only)
  static Future<Map<String, dynamic>> kickPlayer({
    required int roomId,
    required int userId,
  }) async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.post(
        '/api/rooms/$roomId/kick',
        data: {'user_id': userId},
        options: options,
      );

      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Start the game (host only)
  static Future<Map<String, dynamic>> startGame(int roomId) async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.post(
        '/api/rooms/$roomId/start',
        options: options,
      );

      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Leave the room
  static Future<Map<String, dynamic>> leaveRoom(int roomId) async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.post(
        '/api/rooms/$roomId/leave',
        options: options,
      );

      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Delete the room (host only)
  static Future<Map<String, dynamic>> deleteRoom(int roomId) async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.delete(
        '/api/rooms/$roomId',
        options: options,
      );

      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Error handler
  static String _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic> && data.containsKey('detail')) {
        return data['detail'].toString();
      }
      return 'Error: ${e.response!.statusCode}';
    } else if (e.type == DioExceptionType.connectionTimeout) {
      return 'Connection timed out';
    } else if (e.type == DioExceptionType.receiveTimeout) {
      return 'Data receive timed out';
    } else {
      return 'Unable to connect to the server';
    }
  }
}
