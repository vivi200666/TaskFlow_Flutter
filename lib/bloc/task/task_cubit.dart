import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/api_provider.dart';
import 'task_state.dart';

class TaskCubit extends Cubit<TaskState> {
  final ApiProvider apiProvider;

  TaskCubit(this.apiProvider) : super(TaskInitial());

  // 1. CARGAR TAREAS: Esta ya la tienes bien
  Future<void> cargarYFiltrarTareas(String token) async {
    try {
      emit(TaskLoading());
      final todasLasTareas = await apiProvider.getTareas(token);

      if (todasLasTareas.isEmpty) {
        emit(TaskLoaded(tareasPersonales: [], tareasEquipo: []));
        return;
      }

      final personales = todasLasTareas
          .where((t) => t.estado == 'TODO' || t.estado == 'PROG') 
          .toList();

      final equipo = todasLasTareas
          .where((t) => t.estado == 'DONE')
          .toList();

      emit(TaskLoaded(tareasPersonales: personales, tareasEquipo: equipo));
    } catch (e) {
      print("DEBUG ERROR: $e");
      emit(TaskError("Error al cargar tareas: ${e.toString()}"));
    }
  }

  // 2. AGREGAR NUEVA TAREA: Esta es la que debes añadir
  Future<void> agregarNuevaTarea(String titulo, String descripcion, String token) async {
    try {
      // Llamamos al provider para que hable con Django
      await apiProvider.crearTarea(titulo, descripcion, token);
      
      // IMPORTANTE: Después de crearla, llamamos a cargarYFiltrarTareas
      // para que la lista se actualice sola en la pantalla
      await cargarYFiltrarTareas(token);
      
    } catch (e) {
      print("Error al agregar tarea: $e");
      emit(TaskError("No se pudo guardar la tarea."));
    }
  }

  // 3. MOVER TAREA (KANBAN): Esta también ya la tenías
  Future<void> moverTareaKanban(int tareaId, String nuevoEstado, String token) async {
    try {
      await apiProvider.actualizarEstadoTarea(tareaId, nuevoEstado, token);
      await cargarYFiltrarTareas(token);
    } catch (e) {
      print("Error al mover tarea: $e");
      emit(TaskError("No se pudo mover la tarea."));
    }
  }
}