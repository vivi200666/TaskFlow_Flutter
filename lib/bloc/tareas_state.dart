import 'package:equatable/equatable.dart';
import '../models/tarea_model.dart';

abstract class TareasState extends Equatable {
  const TareasState();
  @override
  List<Object> get props => [];
}

// 1. Estado inicial
class TareasInitial extends TareasState {}

// 2. Estado cargando (para mostrar el circulito de progreso)
class TareasLoading extends TareasState {}

// 3. Estado con éxito (cuando ya tenemos la lista)
class TareasLoaded extends TareasState {
  final List<Tarea> tareas;
  const TareasLoaded(this.tareas);
  @override
  List<Object> get props => [tareas];
}

// 4. Estado de error
class TareasError extends TareasState {
  final String mensaje;
  const TareasError(this.mensaje);
  @override
  List<Object> get props => [mensaje];
}