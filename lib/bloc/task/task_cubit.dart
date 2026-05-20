import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/api_provider.dart';
import 'task_state.dart';

class TaskCubit extends Cubit<TaskState> {
  final ApiProvider apiProvider;

  TaskCubit(this.apiProvider) : super(TaskInitial());

  /// Load all personal tasks of the user (todas, sin filtrar)
  Future<void> loadPersonalTasks(String token) async {
    try {
      emit(TaskLoading());
      final list = await apiProvider.fetchTasks(token: token);
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
      final list = await apiProvider.fetchTasks(token: token, workspaceId: workspaceId);
      final orderedTasks = _orderByPriority(list);
      emit(TaskLoadedWorkspace(tasks: orderedTasks));
    } catch (e) {
      emit(TaskError('Error loading workspace tasks: $e'));
    }
  }

  /// Load ONLY completed tasks (estado == 'DONE')
  Future<void> loadCompletedTasks(String token) async {
    try {
      emit(TaskLoading());
      final list = await apiProvider.fetchTasks(token: token);
      final completedTasks = list.where((t) => t['estado'] == 'DONE').toList();
      final orderedTasks = _orderByPriority(completedTasks);
      emit(TaskLoadedPersonal(tasks: orderedTasks));
    } catch (e) {
      emit(TaskError('Error loading completed tasks: $e'));
    }
  }

  /// Load upcoming tasks (not DONE and with dueDate not null)
  Future<void> loadUpcomingTasks(String token) async {
    try {
      emit(TaskLoading());
      final list = await apiProvider.fetchTasks(token: token);
      final upcomingTasks = list.where((t) => 
        t['estado'] != 'DONE' && t['fecha_vencimiento'] != null
      ).toList();
      final orderedTasks = _orderByPriority(upcomingTasks);
      emit(TaskLoadedPersonal(tasks: orderedTasks));
    } catch (e) {
      emit(TaskError('Error loading upcoming tasks: $e'));
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

  /// Optimistic update for task status (to avoid flickering)
  Future<void> updateTaskStatus(int id, String newStatus, String token) async {
    try {
      // 1. Avisamos al backend
      await apiProvider.updateTaskStatus(id, newStatus, token);

      // 2. Actualizamos la lista que ya tenemos en memoria (Optimización)
      if (state is TaskLoadedWorkspace) {
        final currentTasks = List<Map<String, dynamic>>.from((state as TaskLoadedWorkspace).tasks);
        final index = currentTasks.indexWhere((t) => t['id'] == id);
        if (index != -1) {
          currentTasks[index]['estado'] = newStatus;
          emit(TaskLoadedWorkspace(tasks: _orderByPriority(currentTasks)));
        }
      } else if (state is TaskLoadedPersonal) {
        final currentTasks = List<Map<String, dynamic>>.from((state as TaskLoadedPersonal).tasks);
        final index = currentTasks.indexWhere((t) => t['id'] == id);
        if (index != -1) {
          currentTasks[index]['estado'] = newStatus;
          emit(TaskLoadedPersonal(tasks: _orderByPriority(currentTasks)));
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

  /// Order tasks by priority (A > M > B) and then by due date
  List<Map<String, dynamic>> _orderByPriority(List<Map<String, dynamic>> tasks) {
    final order = {'A': 0, 'M': 1, 'B': 2};
    final sorted = List<Map<String, dynamic>>.from(tasks);
    sorted.sort((a, b) {
      final pa = order[a['prioridad']] ?? 3;
      final pb = order[b['prioridad']] ?? 3;
      if (pa != pb) return pa.compareTo(pb);
      final da = a['fecha_vencimiento'] ?? '';
      final db = b['fecha_vencimiento'] ?? '';
      return da.toString().compareTo(db.toString());
    });
    return sorted;
  }
}