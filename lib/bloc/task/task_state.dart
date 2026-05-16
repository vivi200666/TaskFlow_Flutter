import 'package:equatable/equatable.dart';
import '../../models/task_model.dart';

abstract class TaskState extends Equatable {
  const TaskState();
  @override
  List<Object?> get props => [];
}

// Estado Inicial
class TaskInitial extends TaskState {}

// Estado de Carga (Criterio 6: Muestra el circulito de progreso)
class TaskLoading extends TaskState {}

// Estado de Éxito (Contiene la lista de tareas filtradas)
class TaskLoaded extends TaskState {
  final List<Tarea> tareasPersonales;
  final List<Tarea> tareasEquipo;

  const TaskLoaded({
    required this.tareasPersonales,
    required this.tareasEquipo,
  });

  @override
  List<Object?> get props => [tareasPersonales, tareasEquipo];
}

// Estado de Error (Criterio 9: Captura fallos sin bloquear la app)
class TaskError extends TaskState {
  final String mensaje;
  const TaskError(this.mensaje);

  @override
  List<Object?> get props => [mensaje];
}