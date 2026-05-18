import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/api_provider.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final ApiProvider apiProvider;

  AuthCubit(this.apiProvider) : super(AuthInitial());

  // Función lógica para iniciar sesión
  Future<void> iniciarSesion(String username, String password) async {
    // Validación básica antes de quemar datos (Criterio 9)
    if (username.isEmpty || password.isEmpty) {
      emit(const AuthError("Por favor, llena todos los campos obligatorios."));
      return;
    }

    try {
      emit(AuthLoading()); // Emitimos estado de carga (Criterio 6)

      final data = await apiProvider.login(username, password);
      
      // ✅ CORRECCIÓN: SimpleJWT usa 'access' para el token
      final String token = data['access'] ?? '';
      final int usuarioId = data['user_id'] ?? 0;

      // Emitimos éxito guardando los datos requeridos (Tu cuaderno)
      emit(AuthSuccess(token: token, usuarioId: usuarioId));
    } catch (e) {
      // Control de excepciones con mensajes limpios (Criterio 9)
      emit(AuthError(e.toString().replaceAll("Exception: ", "")));
    }
  }

  // Función para cerrar sesión y limpiar el estado
  void cerrarSesion() {
    emit(AuthInitial());
  }
}