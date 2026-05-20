import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/task/task_cubit.dart';
import '../../bloc/task/task_state.dart';
import '../../bloc/auth/auth_cubit.dart';
import '../../bloc/auth/auth_state.dart';
import '../../models/task_model.dart';

class KanbanScreen extends StatefulWidget {
  final int workspaceId;
  final bool isAdmin; // ✅ nuevo parámetro
  const KanbanScreen({super.key, required this.workspaceId, required this.isAdmin});

  @override
  State<KanbanScreen> createState() => _KanbanScreenState();
}

class _KanbanScreenState extends State<KanbanScreen> {
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUserIdAndTasks();
  }

  Future<void> _loadUserIdAndTasks() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthSuccess) {
      _currentUserId = authState.userId;
      // Cargar tareas solo una vez al iniciar
      context.read<TaskCubit>().loadWorkspaceTasks(widget.workspaceId, authState.token);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthSuccess) {
      return const Scaffold(body: Center(child: Text('No autenticado')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kanban Board'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<TaskCubit>().loadWorkspaceTasks(widget.workspaceId, authState.token);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: BlocBuilder<TaskCubit, TaskState>(
          builder: (context, state) {
            if (state is TaskLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is TaskError) {
              return Center(child: Text('Error: ${state.message}'));
            }
            if (state is TaskLoadedWorkspace) {
              final tasks = state.tasks.map((t) => Task.fromJson(t)).toList();
              if (tasks.isEmpty) {
                return const Center(child: Text('No hay tareas en este workspace'));
              }
              return _buildKanbanBoard(tasks);
            }
            return const Center(child: Text('Cargando tareas...'));
          },
        ),
      ),
    );
  }

  Widget _buildKanbanBoard(List<Task> tasks) {
    final todoTasks = tasks.where((t) => t.status == 'TODO').toList();
    final progTasks = tasks.where((t) => t.status == 'PROG').toList();
    final doneTasks = tasks.where((t) => t.status == 'DONE').toList();

    const double kanbanHeight = 600;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildColumn("To Do", todoTasks, Colors.blue, kanbanHeight),
        const SizedBox(width: 16),
        _buildColumn("In Progress", progTasks, Colors.orange, kanbanHeight),
        const SizedBox(width: 16),
        _buildColumn("Done", doneTasks, Colors.green, kanbanHeight),
      ],
    );
  }

  Widget _buildColumn(String title, List<Task> tasks, Color color, double height) {
    return Expanded(
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                    child: Text(tasks.length.toString(),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: tasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 8),
                          Text('No tasks', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) => _buildTaskCard(tasks[index], color),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(Task task, Color columnColor) {
    // ✅ Permisos: admin o el usuario asignado a la tarea
    final canEdit = widget.isAdmin || (_currentUserId != null && task.assignedTo == _currentUserId);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(task.title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ),
                if (task.assignedTo != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "User ${task.assignedTo}",
                      style: const TextStyle(fontSize: 9),
                    ),
                  ),
              ],
            ),
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(task.description,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildPriorityBadge(task.priority),
                if (task.categoryDetails != null) _buildCategoryBadge(task.categoryDetails!),
              ],
            ),
            const SizedBox(height: 8),
            if (canEdit)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (task.status != 'TODO')
                        _buildMoveButton(Icons.arrow_back, "Mover izquierda",
                            _getPreviousState(task.status), task.id),
                      if (task.status != 'DONE')
                        _buildMoveButton(Icons.arrow_forward, "Mover derecha",
                            _getNextState(task.status), task.id),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 16),
                    color: Colors.red,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _deleteTask(task),
                  ),
                ],
              )
            else
              const Text("Sin permisos para editar",
                  style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    final color = priority == 'A' ? Colors.red : priority == 'M' ? Colors.orange : Colors.green;
    final label = priority == 'A' ? 'High' : priority == 'M' ? 'Med' : 'Low';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildCategoryBadge(Map<String, dynamic> details) {
    Color categoryColor = Colors.grey;
    String categoryName = details['nombre'] ?? '';
    final rawColor = (details['color'] ?? '').toString().trim();
    try {
      String hex = rawColor.replaceAll('#', '');
      if (hex.length == 6) {
        categoryColor = Color(int.parse('0xFF$hex'));
      } else if (hex.length == 8) {
        categoryColor = Color(int.parse('0x$hex'));
      }
    } catch (_) {
      final name = rawColor.toLowerCase();
      final nameMap = {
        'rojo': Colors.red,
        'azul': Colors.blue,
        'verde': Colors.green,
        'amarillo': Colors.yellow,
        'gris': Colors.grey,
      };
      categoryColor = nameMap[name] ?? Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: categoryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: categoryColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: categoryColor, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(categoryName,
              style: TextStyle(fontSize: 9, color: categoryColor, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildMoveButton(IconData icon, String tooltip, String newState, int taskId) {
    return IconButton(
      icon: Icon(icon, size: 16),
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onPressed: () => _moveTask(taskId, newState),
    );
  }

  String _getPreviousState(String current) =>
      current == 'PROG' ? 'TODO' : current == 'DONE' ? 'PROG' : current;
  String _getNextState(String current) =>
      current == 'TODO' ? 'PROG' : current == 'PROG' ? 'DONE' : current;

  void _moveTask(int taskId, String newState) {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthSuccess) {
      context.read<TaskCubit>().updateTask(taskId, {'estado': newState}, authState.token);
    }
  }

  void _deleteTask(Task task) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Task?'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final authState = context.read<AuthCubit>().state;
              if (authState is AuthSuccess) {
                context.read<TaskCubit>().deleteTask(task.id, authState.token);
              }
              Navigator.pop(dialogContext);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}