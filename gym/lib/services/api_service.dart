import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../models/attendance.dart';

class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
      // contentType: Headers.jsonContentType, // Let Dio deduce. Defaults to JSON if map, Multipart if FormData
    ),
  );

  ApiService() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          // Handle global errors here (e.g. 401 logout)
          return handler.next(e);
        },
      ),
    );
  }

  Future<Response> post(String path, {dynamic data}) async {
    return _dio.post(path, data: data);
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.get(path, queryParameters: queryParameters);
  }

  static Future<bool> changePassword(
    String oldPassword,
    String newPassword,
  ) async {
    final dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await dio.post(
        '/auth/change-password',
        data: {'old_password': oldPassword, 'new_password': newPassword},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<Attendance>> myHistory() async {
    try {
      final response = await _dio.get('/history');
      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        return data.map((json) => Attendance.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load history');
    }
  }

  Future<List<Attendance>> getAttendanceLogs({
    int page = 1,
    int limit = 20,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final response = await _dio.get(
        '/management/attendance',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (startDate != null) 'start_date': startDate,
          if (endDate != null) 'end_date': endDate,
        },
      );
      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        return data.map((json) => Attendance.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load attendance logs: $e');
    }
  }

  Future<bool> deleteMember(int id) async {
    try {
      final response = await _dio.delete('/management/members/$id');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
