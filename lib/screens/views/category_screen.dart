import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/task/task_cubit.dart';
import '../../bloc/task/task_state.dart';
import '../../bloc/auth/auth_cubit.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/category/category_cubit.dart';
import '../../bloc/category/category_state.dart';
import '../../models/task_model.dart';
import '../create_task_modal.dart';

class CategoryScreen extends StatefulWidget {
  final int categoryId;
  const CategoryScreen({super.key, required this.categoryId});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar tareas personales al entrar a la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthCubit>().state;
      if (authState is AuthSuccess) {
        context.read<TaskCubit>().loadPersonalTasks(authState.token);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la categoría
          BlocBuilder<CategoryCubit, CategoryState>(
            builder: (context, state) {
              if (state is CategoryLoaded) {
                final category = state.categories.firstWhere(
                  (cat) => cat.id == widget.categoryId,
                  orElse: () => state.categories.first,
                );
                final categoryColor = Color(int.parse('0xFF${category.color}'));
                return Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(color: categoryColor.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.label, color: categoryColor, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(category.name, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                          const SizedBox(height: 4),
                          Text('Category tasks', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => CreateTaskModal(initialCategoryId: widget.categoryId),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('New Task'),
                      style: ElevatedButton.styleFrom(backgroundColor: categoryColor, foregroundColor: Colors.white),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: 24),

          // Lista de tareas con manejo de TaskInitial
          Expanded(
            child: BlocListener<TaskCubit, TaskState>(
              listener: (context, state) {
                final authState = context.read<AuthCubit>().state;
                if (authState is! AuthSuccess) return;
                // Recargar tareas personales después de crear/actualizar/eliminar
                if (state is TaskCreated || state is TaskUpdated || state is TaskDeleted) {
                  context.read<TaskCubit>().loadPersonalTasks(authState.token);
                }
              },
              child: BlocBuilder<TaskCubit, TaskState>(
                builder: (context, state) {
                  // Manejar estado inicial
                  if (state is TaskInitial) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is TaskLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is TaskError) {
                    return _buildErrorState(state.message);
                  }
                  if (state is TaskLoadedPersonal || state is TaskLoadedWorkspace) {
                    final personalTasks = state is TaskLoadedPersonal ? state.tasks : [];
                    final workspaceTasks = state is TaskLoadedWorkspace ? state.tasks : [];
                    final allTasks = [...personalTasks, ...workspaceTasks];
                    // Filtrar solo tareas de la categoría actual
                    final categoryTasks = allTasks.where((task) => task['categoria'] == widget.categoryId).toList();

                    if (categoryTasks.isEmpty) {
                      return _buildEmptyState();
                    }
                    return _buildTaskList(categoryTasks.map((e) => Task.fromJson(e)).toList());
                  }
                  return const Center(child: Text('Unexpected state'));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(List<Task> tasks) {
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) => _CategoryTaskCard(task: tasks[index]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.label_outline, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No tasks in this category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Text('Create a task and assign it to this category', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
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
          Text('Error loading tasks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey.shade800)),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(fontSize: 14, color: Colors.grey.shade600), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ========== TARJETA DE TAREA (sin cambios) ==========
class _CategoryTaskCard extends StatelessWidget {
  final Task task;
  const _CategoryTaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final isCompleted = task.status == 'DONE';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        leading: Checkbox(
          value: isCompleted,
          onChanged: (value) {
            final authState = context.read<AuthCubit>().state;
            if (authState is! AuthSuccess) return;
            final newState = isCompleted ? 'TODO' : 'DONE';
            context.read<TaskCubit>().updateTask(task.id, {"estado": newState}, authState.token);
          },
        ),
        title: Text(task.title, style: TextStyle(fontWeight: FontWeight.w600, decoration: isCompleted ? TextDecoration.lineThrough : null)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description.isNotEmpty) ...[const SizedBox(height: 4), Text(task.description, maxLines: 2, overflow: TextOverflow.ellipsis)],
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [_buildPriorityBadge(), _buildStateBadge()]),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') _deleteTask(context, task);
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')])),
            const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityBadge() {
    Color color;
    String label;
    switch (task.priority) {
      case 'A':
        color = Colors.red;
        label = 'High';
        break;
      case 'M':
        color = Colors.orange;
        label = 'Medium';
        break;
      case 'B':
        color = Colors.green;
        label = 'Low';
        break;
      default:
        color = Colors.grey;
        label = 'None';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withOpacity(0.3))),
      child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildStateBadge() {
    Color color;
    String label;
    switch (task.status) {
      case 'TODO':
        color = Colors.blue;
        label = 'To Do';
        break;
      case 'PROG':
        color = Colors.orange;
        label = 'In Progress';
        break;
      case 'DONE':
        color = Colors.green;
        label = 'Done';
        break;
      default:
        color = Colors.grey;
        label = task.status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withOpacity(0.3))),
      child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }

  void _deleteTask(BuildContext context, Task task) {
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