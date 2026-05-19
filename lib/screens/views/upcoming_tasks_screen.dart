import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../bloc/task/task_cubit.dart';
import '../../bloc/task/task_state.dart';
import '../../bloc/auth/auth_cubit.dart';
import '../../bloc/auth/auth_state.dart';
import '../../models/task_model.dart';
import '../create_task_modal.dart';

class UpcomingTasksScreen extends StatelessWidget {
  const UpcomingTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upcoming Tasks',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tasks with due dates',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const CreateTaskModal(),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('New Task'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Task list
          Expanded(
            child: BlocBuilder<TaskCubit, TaskState>(
              builder: (context, state) {
                if (state is TaskLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is TaskError) {
                  return _buildErrorState(state.message);
                }

                if (state is TaskLoadedPersonal) {
                  // Convert maps to Task objects
                  final allTasks = state.tasks
                      .map((map) => Task.fromJson(map))
                      .toList();
                  // Filter tasks with due dates
                  final upcomingTasks = _filterUpcomingTasks(allTasks);

                  if (upcomingTasks.isEmpty) {
                    return _buildEmptyState();
                  }

                  return _buildGroupedTaskList(upcomingTasks);
                }

                return const Center(child: Text('Loading...'));
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Task> _filterUpcomingTasks(List<Task> tasks) {
    final now = DateTime.now();
    return tasks.where((task) {
      if (task.dueDate == null) return false;
      final dueDate = DateTime.parse(task.dueDate!);
      return dueDate.isAfter(now) || _isSameDay(dueDate, now);
    }).toList()
      ..sort((a, b) {
        final dateA = DateTime.parse(a.dueDate!);
        final dateB = DateTime.parse(b.dueDate!);
        return dateA.compareTo(dateB);
      });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildGroupedTaskList(List<Task> tasks) {
    final Map<String, List<Task>> groupedTasks = {};

    for (var task in tasks) {
      final dueDate = DateTime.parse(task.dueDate!);
      final key = _getDateGroupKey(dueDate);

      if (!groupedTasks.containsKey(key)) {
        groupedTasks[key] = [];
      }
      groupedTasks[key]!.add(task);
    }

    return ListView.builder(
      itemCount: groupedTasks.length,
      itemBuilder: (context, index) {
        final key = groupedTasks.keys.elementAt(index);
        final tasksInGroup = groupedTasks[key]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                key,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            // Tasks in group
            ...tasksInGroup.map((task) => _TaskCard(task: task)),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  String _getDateGroupKey(DateTime date) {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final nextWeek = now.add(const Duration(days: 7));

    if (_isSameDay(date, now)) {
      return 'Today';
    } else if (_isSameDay(date, tomorrow)) {
      return 'Tomorrow';
    } else if (date.isBefore(nextWeek)) {
      return 'This Week';
    } else {
      return DateFormat('MMMM yyyy').format(date);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No upcoming tasks',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tasks with due dates will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ========== TASK CARD (Simplified version) ==========
class _TaskCard extends StatelessWidget {
  final Task task;

  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final dueDate = DateTime.parse(task.dueDate!);
    final now = DateTime.now();
    final isOverdue = dueDate.isBefore(now);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isOverdue ? Colors.red.shade200 : Colors.grey.shade200,
        ),
      ),
      child: ListTile(
        leading: Checkbox(
          value: task.completed,
          onChanged: (value) {
            final authState = context.read<AuthCubit>().state;
            if (authState is! AuthSuccess) return;

            final newStatus = task.completed ? 'TODO' : 'DONE';
            _updateTaskStatus(context, task.id, newStatus, authState.token);
          },
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: task.completed ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                task.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  isOverdue ? Icons.warning : Icons.event,
                  size: 14,
                  color: isOverdue ? Colors.red : Colors.blue,
                ),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM d, yyyy').format(dueDate),
                  style: TextStyle(
                    fontSize: 12,
                    color: isOverdue ? Colors.red : Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') {
              _deleteTask(context, task);
            }
          },
          itemBuilder: (context) => [
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
      ),
    );
  }

  void _updateTaskStatus(BuildContext context, int taskId, String newStatus, String token) {
    context.read<TaskCubit>().updateTask(
          taskId,
          {'estado': newStatus},
          token,
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
                context.read<TaskCubit>().deleteTask(
                      task.id,
                      authState.token,
                    );
              }
              Navigator.pop(dialogContext);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}