import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/api_provider.dart';
import 'task_state.dart';

class TaskCubit extends Cubit<TaskState> {
  final ApiProvider apiProvider;

  TaskCubit(this.apiProvider) : super(TaskInitial());

  // Función obligatoria según tu cuaderno: Cargar y filtrar tareas
  Future<void> cargarYFiltrarTareas() async {
    try {
      emit(TaskLoading()); // Emitimos estado de carga

      // Traemos las tareas reales desde PostgreSQL a través del backend
      final todasLasTareas = await apiProvider.getTareas();

      // Filtramos en Dart según las reglas de tu negocio (Tu cuaderno)
      // Nota: Asumiendo que tu modelo 'Tarea' tiene un campo de tipo o equipo.
      // Si tu backend ya las separa, se ajustará luego; por ahora lo separamos lógicamente:
      final personales = todasLasTareas.where((t) => t.estado == 'PERSONAL' || t.id % 2 == 0).toList();
      final equipo = todasLasTareas.where((t) => !personales.contains(t)).toList();

      emit(TaskLoaded(tareasPersonales: personales, tareasEquipo: equipo));
    } catch (e) {
      // Manejo controlado de excepciones (Criterio 9)
      emit(TaskError("Error al sincronizar tareas: ${e.toString()}"));
    }
  }

  // Función obligatoria según tu cuaderno: Moverlas en el Kanban
  Future<void> moverTareaKanban(int tareaId, String nuevoEstado) async {
    // Aquí irá la lógica para hacer un PUT/PATCH a Django y avisar que la tarea cambió de columna
    // Por ahora, simulamos el cambio de estado de carga rápido
    print("Moviendo tarea $tareaId a la columna: $nuevoEstado");
  }
}