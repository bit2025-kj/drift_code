import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nafa_edu/config/constants.dart';

class ApiClient {
  static ApiClient? _instance;
  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  // Callback d'expiration de session
  void Function()? onSessionExpired;

  ApiClient._() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: AppConstants.apiTimeout,
      receiveTimeout: AppConstants.apiTimeout,
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: AppConstants.keyAccessToken);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final path = error.requestOptions.path;
        final isAuthRequest = path.contains('/auth/refresh') ||
                              path.contains('/auth/login') ||
                              path.contains('/auth/register');

        if (error.response?.statusCode == 401 && !isAuthRequest) {
          final refreshed = await _refreshToken();
          if (refreshed) {
            final token = await _storage.read(key: AppConstants.keyAccessToken);
            error.requestOptions.headers['Authorization'] = 'Bearer $token';
            final response = await _dio.fetch(error.requestOptions);
            handler.resolve(response);
            return;
          } else {
            // Signalement de l'expiration de session
            onSessionExpired?.call();
          }
        }
        handler.next(error);
      },
    ));

    if (AppConstants.baseUrl.contains('localhost')) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true, responseBody: false, logPrint: (o) => print('[API] $o'),
      ));
    }
  }

  static ApiClient get instance => _instance ??= ApiClient._();

  Future<bool> _refreshToken() async {
    try {
      final refresh = await _storage.read(key: AppConstants.keyRefreshToken);
      if (refresh == null) return false;
      final response = await _dio.post('/auth/refresh', data: {'refresh_token': refresh});
      await _storage.write(key: AppConstants.keyAccessToken, value: response.data['access_token']);
      await _storage.write(key: AppConstants.keyRefreshToken, value: response.data['refresh_token']);
      return true;
    } catch (_) {
      await clearTokens();
      return false;
    }
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String userName,
    required bool isTeacher,
  }) async {
    await _storage.write(key: AppConstants.keyAccessToken, value: accessToken);
    await _storage.write(key: AppConstants.keyRefreshToken, value: refreshToken);
    await _storage.write(key: AppConstants.keyUserId, value: userId);
    await _storage.write(key: AppConstants.keyUserName, value: userName);
    await _storage.write(key: AppConstants.keyIsTeacher, value: isTeacher.toString());
  }

  Future<void> clearTokens() async => _storage.deleteAll();
  Future<String?> get accessToken => _storage.read(key: AppConstants.keyAccessToken);
  Future<bool> get isLoggedIn async => (await accessToken) != null;

  Dio get dio => _dio;
}
