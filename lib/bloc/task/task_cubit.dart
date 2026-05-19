import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/api_provider.dart';
import 'task_state.dart';

class TaskCubit extends Cubit<TaskState> {
  final ApiProvider apiProvider;

  TaskCubit(this.apiProvider) : super(TaskInitial());

  /// Load all personal tasks of the user
  Future<void> loadPersonalTasks(String token) async {
    try {
      emit(TaskLoading());
      final list = await apiProvider.fetchTasks(token: token); // renamed
      final orderedTasks = _orderByPriority(list);
      emit(TaskLoadedPersonal(tasks: orderedTasks));
    } catch (e) {
      emit(TaskError('Error loading personal tasks: $e'));
    }
  }

  /// Load tasks of a specific workspace
  Future<void> loadWorkspaceTasks(int workspaceId, String token) async {
    try {
      emit(TaskLoading());
      final list = await apiProvider.fetchTasks(token: token, workspaceId: workspaceId); // renamed
      final orderedTasks = _orderByPriority(list);
      emit(TaskLoadedWorkspace(tasks: orderedTasks));
    } catch (e) {
      emit(TaskError('Error loading workspace tasks: $e'));
    }
  }

  /// Create new task (personal or workspace)
  Future<void> createTask(Map<String, dynamic> payload, String token) async {
    try {
      emit(TaskLoading());
      final task = await apiProvider.createTask(payload, token);
      emit(TaskCreated(task: task));
    } catch (e) {
      emit(TaskError('Error creating task: $e'));
    }
    print('Payload enviado: $payload');
    print('Token: $token');
  }

  /// Update task (mark completed, move in Kanban, etc.)
  Future<void> updateTask(int id, Map<String, dynamic> payload, String token) async {
    try {
      emit(TaskLoading());
      final task = await apiProvider.updateTask(id, payload, token);
      emit(TaskUpdated(task: task));
    } catch (e) {
      emit(TaskError('Error updating task: $e'));
    }
  }

  /// Delete task
  Future<void> deleteTask(int id, String token) async {
    try {
      emit(TaskLoading());
      final success = await apiProvider.deleteTask(id, token);
      if (success) {
        emit(TaskDeleted(id: id));
      } else {
        emit(TaskError('Could not delete task'));
      }
    } catch (e) {
      emit(TaskError('Error deleting task: $e'));
    }
  }

  /// Reset state (useful on logout)
  void reset() {
    emit(TaskInitial());
  }

  /// Order tasks by priority (A > M > B)
  List<Map<String, dynamic>> _orderByPriority(List<Map<String, dynamic>> tasks) {
    final order = {'A': 0, 'M': 1, 'B': 2};
    tasks.sort((a, b) {
      final pa = order[a['prioridad']] ?? 3;
      final pb = order[b['prioridad']] ?? 3;
      if (pa != pb) return pa.compareTo(pb);
      final da = a['fecha_vencimiento'] ?? '';
      final db = b['fecha_vencimiento'] ?? '';
      return da.toString().compareTo(db.toString());
    });
    return tasks;
  }
  Future<void> loadCompletedTasks(String token) async {
    try {
      emit(TaskLoading());
      final list = await apiProvider.fetchTasks(token: token);
      
      // Filtramos solo las que tienen estado 'realizada' (o el nombre que uses en tu DB)
      final completed = list.where((t) => t['estado'] == 'realizada').toList();
      
      // Reutilizamos TaskLoadedPersonal o puedes crear TaskLoadedCompleted en tu state
      emit(TaskLoadedPersonal(tasks: completed)); 
    } catch (e) {
      emit(TaskError('Error al cargar tareas completadas: $e'));
    }
  }
  Future<void> loadUpcomingTasks(String token) async {
    try {
      emit(TaskLoading());
      final list = await apiProvider.fetchTasks(token: token);
      
      // Filtramos las que NO están terminadas y tienen fecha
      final upcoming = list.where((t) => 
        t['estado'] != 'realizada' && t['fecha_vencimiento'] != null
      ).toList();
      
      emit(TaskLoadedPersonal(tasks: upcoming));
    } catch (e) {
      emit(TaskError('Error al cargar próximas tareas: $e'));
    }
  }
  // En task_cubit.dart

  Future<void> updateTaskStatus(int id, String newStatus, String token) async {
    try {
      // 1. Avisamos al backend
      await apiProvider.updateTaskStatus(id, newStatus, token);

      // 2. Actualizamos la lista que ya tenemos en memoria (Optimización)
      if (state is TaskLoadedWorkspace) {
        final currentTasks = List<Map<String, dynamic>>.from((state as TaskLoadedWorkspace).tasks);
        
        // Buscamos la tarea y le cambiamos el estado localmente
        final index = currentTasks.indexWhere((t) => t['id'] == id);
        if (index != -1) {
          currentTasks[index]['estado'] = newStatus;
          // Emitimos el nuevo estado con la lista modificada para que la UI se refresque
          emit(TaskLoadedWorkspace(tasks: _orderByPriority(currentTasks)));
        }
      }
    } catch (e) {
      emit(TaskError('Error al mover la tarea: $e'));
    }
  }
  /// Emite estado de carga para limpiar la UI inmediatamente al cambiar de vista
  void emitLoading() {
    emit(TaskLoading());
  }
        
  

}
