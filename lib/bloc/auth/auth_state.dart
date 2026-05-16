import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

// 1. Estado Inicial: El usuario ve el formulario vacío
class AuthInitial extends AuthState {}

// 2. Estado Cargando: El usuario le dio a "Ingresar" y esperamos la API (Criterio 6)
class AuthLoading extends AuthState {}

// 3. Estado Éxito: Login correcto. Guardamos el token e ID del usuario (Tu cuaderno)
class AuthSuccess extends AuthState {
  final String token;
  final int usuarioId;

  const AuthSuccess({required this.token, required this.usuarioId});

  @override
  List<Object?> get props => [token, usuarioId];
}

// 4. Estado Error: Contraseña incorrecta o sin internet (Criterio 9)
class AuthError extends AuthState {
  final String mensaje;
  const AuthError(this.mensaje);

  @override
  List<Object?> get props => [mensaje];
}