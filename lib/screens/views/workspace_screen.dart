import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../bloc/task/task_cubit.dart';
import '../../bloc/task/task_state.dart';
import '../../bloc/auth/auth_cubit.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/workspace/workspace_cubit.dart';
import '../../bloc/workspace/workspace_state.dart';
import '../../models/task_model.dart';

class WorkspaceScreen extends StatefulWidget {
  final int? workspaceId;
  const WorkspaceScreen({super.key, this.workspaceId});

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String _selectedPriority = 'M';
  DateTime? _selectedDate;
  int? _selectedUserId;
  bool _showCode = false;
  bool _showKanban = false;
  List<Map<String, dynamic>> _workspaceMembers = [];

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthSuccess || widget.workspaceId == null) return;

    context.read<TaskCubit>().loadWorkspaceTasks(widget.workspaceId!, authState.token);

    final members = await context.read<WorkspaceCubit>().getWorkspaceMembers(widget.workspaceId!, authState.token);
    if (mounted) {
      setState(() {
        _workspaceMembers = members;
        if (_selectedUserId != null && !_workspaceMembers.any((m) => m['id'] == _selectedUserId)) {
          _selectedUserId = null;
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<TaskCubit, TaskState>(
          listener: (context, state) {
            final authState = context.read<AuthCubit>().state;
            if (authState is! AuthSuccess) return;
            if (state is TaskCreated || state is TaskUpdated || state is TaskDeleted) {
              if (widget.workspaceId != null) {
                context.read<TaskCubit>().loadWorkspaceTasks(widget.workspaceId!, authState.token);
              }
            }
          },
        ),
      ],
      child: BlocBuilder<WorkspaceCubit, WorkspaceState>(
        builder: (context, wsState) {
          if (wsState is WorkspaceLoaded) {
            final currentWS = wsState.workspaces.firstWhere(
              (w) => w['id'] == widget.workspaceId,
              orElse: () => null,
            );
            if (currentWS == null) return const Center(child: Text("Workspace no encontrado"));

            return Scaffold(
              backgroundColor: const Color(0xFFF8F9FA),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(currentWS),
                    const SizedBox(height: 24),
                    _buildMetrics(),
                    const SizedBox(height: 24),
                    _buildQuickForm(),
                    const SizedBox(height: 24),
                    _buildToggleBar(),
                    if (_showKanban) ...[
                      const SizedBox(height: 16),
                      _buildKanbanView(),
                    ],
                  ],
                ),
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  // ========== CABECERA CON CÓDIGO DE INVITACIÓN ==========
  Widget _buildHeader(Map<String, dynamic> ws) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(ws['nombre'] ?? 'Workspace',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(ws['descripcion'] ?? '',
              style: TextStyle(color: Colors.grey.shade600)),
          const Divider(height: 32),
          Row(
            children: [
              const Icon(Icons.vpn_key_outlined, size: 18, color: Colors.purple),
              const SizedBox(width: 8),
              const Text("Código de equipo:",
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      _showCode ? (ws['codigo'] ?? '---') : "••••••••",
                      style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: () => setState(() => _showCode = !_showCode),
                      child: Icon(_showCode ? Icons.visibility_off : Icons.visibility,
                          size: 18, color: Colors.purple),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ========== MÉTRICAS ==========
  Widget _buildMetrics() {
    return BlocBuilder<TaskCubit, TaskState>(
      builder: (context, state) {
        if (state is TaskLoadedWorkspace) {
          final tasks = state.tasks.map((t) => Task.fromJson(t)).toList();
          final todo = tasks.where((t) => t.status == 'TODO').length;
          final prog = tasks.where((t) => t.status == 'PROG').length;
          final done = tasks.where((t) => t.status == 'DONE').length;

          return Row(
            children: [
              _metricCard("Por hacer", todo, Colors.blue),
              const SizedBox(width: 12),
              _metricCard("En curso", prog, Colors.orange),
              const SizedBox(width: 12),
              _metricCard("Finalizado", done, Colors.green),
            ],
          );
        }
        return const SizedBox(height: 80, child: Center(child: LinearProgressIndicator()));
      },
    );
  }

  Widget _metricCard(String title, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(count.toString(),
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title,
                style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }

  // ========== FORMULARIO RÁPIDO ==========
  Widget _buildQuickForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.add_task, color: Colors.teal, size: 20),
              SizedBox(width: 8),
              Text('Nueva tarea rápida',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: '¿Qué hay que hacer?',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildPriorityDropdown(),
                const SizedBox(width: 8),
                _buildDatePicker(),
                const SizedBox(width: 8),
                _buildUserDropdown(),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _submitTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('+ Crear', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descController,
            decoration: InputDecoration(
              hintText: 'Descripción (opcional)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedPriority,
          items: const [
            DropdownMenuItem(value: 'A', child: Text('🔴 Alta')),
            DropdownMenuItem(value: 'M', child: Text('🟡 Media')),
            DropdownMenuItem(value: 'B', child: Text('🟢 Baja')),
          ],
          onChanged: (val) => setState(() => _selectedPriority = val!),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return OutlinedButton.icon(
      onPressed: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime(2100),
        );
        if (date != null) setState(() => _selectedDate = date);
      },
      icon: const Icon(Icons.calendar_today, size: 16),
      label: Text(_selectedDate == null ? 'Fecha' : DateFormat('dd/MM').format(_selectedDate!)),
      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12)),
    );
  }

  Widget _buildUserDropdown() {
    final members = _workspaceMembers;
    if (members.isEmpty) {
      return OutlinedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.person_outline, size: 16),
        label: const Text('Sin miembros'),
        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12)),
      );
    }
    final validSelected = _selectedUserId != null && members.any((m) => m['id'] == _selectedUserId)
        ? _selectedUserId
        : null;
    if (validSelected != _selectedUserId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedUserId = validSelected);
      });
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: validSelected,
          hint: const Text('Asignar a...'),
          items: members.map((member) {
            return DropdownMenuItem<int>(
              value: member['id'],
              child: Text(member['username'] ?? 'Usuario'),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedUserId = val),
        ),
      ),
    );
  }

  Future<void> _submitTask() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El título es obligatorio')),
      );
      return;
    }

    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthSuccess) return;

    final formattedDate = _selectedDate != null
        ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
        : null;

    final payload = <String, dynamic>{
      'titulo': title,
      'descripcion': _descController.text.trim(),
      'prioridad': _selectedPriority,
      'fecha_vencimiento': formattedDate,
      'workspace': widget.workspaceId,
    };
    if (_selectedUserId != null) {
      payload['asignado_a'] = _selectedUserId;
    }

    await context.read<TaskCubit>().createTask(payload, authState.token);

    _titleController.clear();
    _descController.clear();
    setState(() {
      _selectedDate = null;
    });
  }

  // ========== BARRA DE ALTERNANCIA ==========
  Widget _buildToggleBar() {
    return Row(
      children: [
        const Text("Tareas del equipo",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Spacer(),
        TextButton.icon(
          onPressed: () => setState(() => _showKanban = !_showKanban),
          icon: Icon(_showKanban ? Icons.list : Icons.view_kanban),
          label: Text(_showKanban ? "Ver Lista" : "Ver Kanban"),
        ),
      ],
    );
  }

  // ========== VISTA KANBAN (corregida sin errores de layout) ==========
  Widget _buildKanbanView() {
    return BlocBuilder<TaskCubit, TaskState>(
      builder: (context, state) {
        if (state is TaskLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is TaskError) {
          return _buildErrorState(state.message);
        }
        if (state is TaskLoadedWorkspace) {
          final tasks = state.tasks.map((t) => Task.fromJson(t)).toList();
          if (tasks.isEmpty) {
            return Center(
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No hay tareas en este workspace',
                      style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  Text('Crea una tarea con el formulario de arriba',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            );
          }
          return _buildKanbanBoard(tasks);
        }
        return const Center(child: Text('Cargando tareas...'));
      },
    );
  }

  Widget _buildKanbanBoard(List<Task> tasks) {
    final todoTasks = tasks.where((t) => t.status == 'TODO').toList();
    final progTasks = tasks.where((t) => t.status == 'PROG').toList();
    final doneTasks = tasks.where((t) => t.status == 'DONE').toList();

    // Altura fija para todo el Kanban (evita problemas con Expanded)
    const double kanbanHeight = 550;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildKanbanColumn("To Do", todoTasks, Colors.blue, kanbanHeight),
        const SizedBox(width: 16),
        _buildKanbanColumn("In Progress", progTasks, Colors.orange, kanbanHeight),
        const SizedBox(width: 16),
        _buildKanbanColumn("Done", doneTasks, Colors.green, kanbanHeight),
      ],
    );
  }

  // Nueva implementación de columna sin usar Expanded dentro de la columna
  Widget _buildKanbanColumn(String title, List<Task> tasks, Color color, double height) {
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
            // Encabezado fijo
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
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(tasks.length.toString(),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
                  ),
                ],
              ),
            ),
            // Lista de tareas con scroll interno
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
            Text(task.title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
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
            ),
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

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error al cargar el workspace',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey.shade800)),
          const SizedBox(height: 8),
          Text(message,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}