import 'package:equatable/equatable.dart';
import '../../models/category_model.dart'; // Para asociar al espacio de trabajo si es necesario

abstract class WorkspaceState extends Equatable {
  const WorkspaceState();
  @override
  List<Object?> get props => [];
}

// 1. Estado Inicial
class WorkspaceInitial extends WorkspaceState {}

// 2. Estado Cargando: Mientras se consultan los tableros en PostgreSQL (Exigido en tu cuaderno)
class WorkspaceLoading extends WorkspaceState {}

// 3. Estado Éxito / Cargado: Cuando los datos ya están listos (Exigido en tu cuaderno)
class WorkspaceLoaded extends WorkspaceState {
  final List<dynamic> espacios; // Aquí guardarás la lista de workspaces/tableros

  const WorkspaceLoaded({required this.espacios});

  @override
  List<Object?> get props => [espacios];
}

// 4. Estado Error: Si falla la red o el servidor en la nube/Ngrok (Criterio 9 de la rúbrica)
class WorkspaceError extends WorkspaceState {
  final String mensaje;
  const WorkspaceError(this.mensaje);

  @override
  List<Object?> get props => [mensaje];
}