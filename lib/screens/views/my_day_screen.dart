import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../bloc/task/task_cubit.dart';
import '../../bloc/task/task_state.dart';
import '../../bloc/auth/auth_cubit.dart';
import '../../bloc/auth/auth_state.dart';
import '../../models/task_model.dart';
import '../create_task_modal.dart';

class MyDayScreen extends StatelessWidget {
  const MyDayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateFormat('EEEE, MMMM d, yyyy').format(now);
    final authState = context.watch<AuthCubit>().state;
  // 2. DISPARADOR: Si estamos logueados y el Cubit de tareas está en "Initial"
    if (authState is AuthSuccess) {
      final taskCubit = context.read<TaskCubit>();
      if (taskCubit.state is TaskInitial) {
        // Usamos microtask para que no choque con el dibujo de la pantalla
        Future.microtask(() => taskCubit.loadPersonalTasks(authState.token));
      }
    }

    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'My Day',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            today,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),

          // Quick add task field
          _buildQuickAddField(context),
          const SizedBox(height: 24),

          // Task list con BlocListener para refrescar automáticamente
          Expanded(
            child: BlocListener<TaskCubit, TaskState>(
              listener: (context, state) {
                final authState = context.read<AuthCubit>().state;
                if (authState is! AuthSuccess) return;

                // Cuando se crea, actualiza o elimina una tarea, recargar la lista
                if (state is TaskCreated ||
                    state is TaskUpdated ||
                    state is TaskDeleted) {
                  context.read<TaskCubit>().loadPersonalTasks(authState.token);
                }
              },
              child: BlocBuilder<TaskCubit, TaskState>(
                builder: (context, state) {
                  if (state is TaskLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is TaskError) {
                    return _buildErrorState(state.message);
                  }

                  if (state is TaskLoadedPersonal) {
                    final todayTasks = state.tasks
                        .map((map) => Task.fromJson(map))
                        .toList();

                    if (todayTasks.isEmpty) {
                      return _buildEmptyState();
                    }

                    return _buildTaskList(todayTasks);
                  }

                  return const Center(child: Text('Loading...'));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAddField(BuildContext context) {
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => const CreateTaskModal(),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.add_circle_outline, color: Colors.grey.shade600),
            const SizedBox(width: 12),
            Text(
              'Add a new task...',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList(List<Task> tasks) {
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _TaskCard(task: task);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No tasks for today',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add a new task',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error loading tasks',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: SingleChildScrollView(
              child: Text(
                message,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ========== TASK CARD WIDGET ==========
class _TaskCard extends StatelessWidget {
  final Task task;

  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: task.completed,
                  onChanged: (value) {
                    _toggleTaskCompletion(context, task);
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          decoration: task.completed
                              ? TextDecoration.lineThrough
                              : null,
                          color: task.completed
                              ? Colors.grey.shade500
                              : Colors.grey.shade800,
                        ),
                      ),
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            decoration: task.completed
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 12),
                      _buildTaskMetadata(),
                    ],
                  ),
                ),

                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editTask(context, task);
                    } else if (value == 'delete') {
                      _deleteTask(context, task);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskMetadata() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildPriorityBadge(),
        if (task.categoryDetails != null) _buildCategoryBadge(),
        if (task.dueDate != null) _buildDueDateBadge(),
      ],
    );
  }

  Widget _buildPriorityBadge() {
    Color color;
    String label;
    IconData icon;

    switch (task.priority) {
      case 'A':
        color = Colors.red;
        label = 'High';
        icon = Icons.flag;
        break;
      case 'M':
        color = Colors.orange;
        label = 'Medium';
        icon = Icons.flag;
        break;
      case 'B':
        color = Colors.green;
        label = 'Low';
        icon = Icons.flag;
        break;
      default:
        color = Colors.grey;
        label = 'None';
        icon = Icons.flag_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBadge() {
    // Conversión segura del color (evita excepción si no es hex)
    Color categoryColor;
    try {
      categoryColor = Color(int.parse('0xFF${task.categoryDetails!['color']}'));
    } catch (_) {
      categoryColor = Colors.grey;
    }
    final categoryName = task.categoryDetails!['nombre'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: categoryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: categoryColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: categoryColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            categoryName,
            style: TextStyle(
              fontSize: 11,
              color: categoryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDueDateBadge() {
    final dueDate = DateTime.parse(task.dueDate!);
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;

    Color color;
    IconData icon;
    String label;

    if (difference < 0) {
      color = Colors.red;
      icon = Icons.warning;
      label = 'Overdue';
    } else if (difference == 0) {
      color = Colors.orange;
      icon = Icons.today;
      label = 'Today';
    } else if (difference == 1) {
      color = Colors.blue;
      icon = Icons.event;
      label = 'Tomorrow';
    } else {
      color = Colors.grey;
      icon = Icons.event;
      label = DateFormat('MMM d').format(dueDate);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _toggleTaskCompletion(BuildContext context, Task task) {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthSuccess) return;

    final newStatus = task.completed ? 'TODO' : 'DONE';
    _updateTaskStatus(context, task.id, newStatus, authState.token);
  }

  void _updateTaskStatus(
    BuildContext context,
    int taskId,
    String newStatus,
    String token,
  ) {
    context.read<TaskCubit>().updateTask(taskId, {'estado': newStatus}, token);
  }

  void _editTask(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (context) => CreateTaskModal(task: task), 
    );
  }

  void _deleteTask(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Task?'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
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
