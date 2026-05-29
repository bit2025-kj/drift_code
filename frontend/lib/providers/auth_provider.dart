import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nafa_edu/core/api/api_client.dart';
import 'package:nafa_edu/core/api/api_endpoints.dart';
import 'package:nafa_edu/models/user_model.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? error;

  const AuthState({required this.status, this.user, this.error});

  // Use a sentinel so callers can explicitly pass null to clear the error,
  // while omitting the parameter preserves the current error value.
  static const _keep = Object();
  AuthState copyWith({AuthStatus? status, UserModel? user, Object? error = _keep}) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        error: identical(error, _keep) ? this.error : error as String?,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState(status: AuthStatus.loading)) {
    _api.onSessionExpired = () {
      logoutLocal();
    };
    _checkAuth();
  }

  final _api = ApiClient.instance;

  Future<void> _checkAuth() async {
    final loggedIn = await _api.isLoggedIn;
    if (loggedIn) {
      try {
        final res = await _api.dio.get(ApiEndpoints.me);
        state = AuthState(status: AuthStatus.authenticated, user: UserModel.fromJson(res.data));
      } catch (_) {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final res = await _api.dio.post(ApiEndpoints.login, data: {
        'email': email,
        'password': password,
      });
      await _api.saveTokens(
        accessToken: res.data['access_token'],
        refreshToken: res.data['refresh_token'],
        userId: res.data['user_id'],
        userName: res.data['full_name'],
        isTeacher: res.data['is_teacher'],
      );
      await _checkAuth();
      return true;
    } catch (e) {
      state = state.copyWith(error: _parseError(e));
      return false;
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
    int? levelId,
    int? classeId,
    String? ville,
  }) async {
    try {
      final res = await _api.dio.post(ApiEndpoints.register, data: {
        'full_name': fullName,
        'email': email,
        'password': password,
        if (phone != null) 'phone': phone,
        if (levelId != null) 'level_id': levelId,
        if (classeId != null) 'classe_id': classeId,
        if (ville != null) 'ville': ville,
      });
      await _api.saveTokens(
        accessToken: res.data['access_token'],
        refreshToken: res.data['refresh_token'],
        userId: res.data['user_id'],
        userName: res.data['full_name'],
        isTeacher: res.data['is_teacher'],
      );
      await _checkAuth();
      return true;
    } catch (e) {
      state = state.copyWith(error: _parseError(e));
      return false;
    }
  }

  Future<void> refreshUser() => _checkAuth();

  /// Déconnexion locale sans appel API (utilisé lors d'expiration de session)
  Future<void> logoutLocal() async {
    await _api.clearTokens();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> logout() async {
    try {
      await _api.dio.post(ApiEndpoints.logout);
    } catch (_) {}
    await logoutLocal();
  }

  String _parseError(dynamic e) {
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          return 'Le serveur met du temps à répondre (démarrage Render). Réessayez dans quelques secondes.';
        case DioExceptionType.connectionError:
          return 'Impossible de joindre le serveur. Vérifiez votre connexion internet.';
        default:
          final data = e.response?.data;
          if (data is Map && data['detail'] != null) return data['detail'].toString();
          final status = e.response?.statusCode;
          if (status != null) return 'Erreur serveur ($status). Réessayez.';
      }
    }
    return 'Une erreur est survenue. Vérifiez votre connexion.';
  }

  /// Ping silencieux pour réveiller Render avant une action utilisateur.
  Future<void> warmUp() async {
    try {
      await _api.dio.get('/health',
          options: Options(sendTimeout: const Duration(seconds: 90), receiveTimeout: const Duration(seconds: 90)));
    } catch (_) {}
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (_) => AuthNotifier(),
);
