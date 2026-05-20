import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/api_provider.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final ApiProvider apiProvider;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  AuthCubit(this.apiProvider) : super(AuthInitial());

  /// Try to login automatically by reading the persisted token.
  Future<void> tryAutoLogin() async {
    try {
      final token = await _secureStorage.read(key: 'token');
      final userIdStr = await _secureStorage.read(key: 'userId');
      final userId = userIdStr != null ? int.tryParse(userIdStr) ?? 0 : 0;

      if (token != null && token.isNotEmpty) {
        emit(AuthSuccess(token: token, userId: userId));
      } else {
        emit(AuthInitial());
      }
    } catch (_) {
      emit(AuthInitial());
    }
  }

  /// Perform login with username and password.
  Future<void> login(String username, String password) async {
    if (username.isEmpty || password.isEmpty) {
      emit(const AuthError("Por favor completa todos los campos."));
      return;
    }
    try {
      emit(AuthLoading());
      final data = await apiProvider.login(username, password);
      final String token = data['access'] ?? '';
      final int userId = data['user_id'] ?? 0;

      if (token.isEmpty) {
        emit(const AuthError("No se recibió token."));
        return;
      }

      await _secureStorage.write(key: 'token', value: token);
      await _secureStorage.write(key: 'userId', value: userId.toString());

      emit(AuthSuccess(token: token, userId: userId));
    } catch (e) {
      emit(AuthError(e.toString().replaceAll("Exception: ", "")));
    }
  }

  /// Register a new user
  Future<void> register(String username, String email, String password) async {
    if (username.isEmpty || password.isEmpty || email.isEmpty) {
      emit(const AuthError("Todos los campos son obligatorios."));
      return;
    }

    try {
      emit(AuthLoading());
      final data = await apiProvider.register(username, email, password);
      final String token = data['access'] ?? '';
      final int userId = data['user_id'] ?? 0;

      if (token.isEmpty) {
        emit(const AuthError("No se recibió el token de acceso."));
        return;
      }

      await _secureStorage.write(key: 'token', value: token);
      await _secureStorage.write(key: 'userId', value: userId.toString());

      emit(AuthSuccess(token: token, userId: userId));
    } catch (e) {
      emit(AuthError(e.toString().replaceAll("Exception: ", "")));
    }
  }

  /// Logout and clear persisted state.
  Future<void> logout() async {
    try {
      await _secureStorage.delete(key: 'token');
      await _secureStorage.delete(key: 'userId');
    } catch (_) {
      // ignore errors but continue resetting state
    } finally {
      emit(AuthInitial());
    }
  }
}