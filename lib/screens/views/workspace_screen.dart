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
import '../create_task_modal.dart';
import 'kanban_screen.dart';
import 'metrics_screen.dart';

class WorkspaceScreen extends StatefulWidget {
  final int? workspaceId;
  const WorkspaceScreen({super.key, this.workspaceId});

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  bool _isSaving = false;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String _selectedPriority = 'M';
  DateTime? _selectedDate;
  int? _selectedUserId;
  bool _showCode = false;
  List<Map<String, dynamic>> _workspaceMembers = [];
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  @override
  void didUpdateWidget(WorkspaceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workspaceId != widget.workspaceId) {
      _fetchInitialData();
    }
  }

  Future<void> _fetchInitialData() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthSuccess || widget.workspaceId == null) return;

    context.read<TaskCubit>().loadWorkspaceTasks(widget.workspaceId!, authState.token);

    // Cargar miembros usando el endpoint (ahora existente)
    List<Map<String, dynamic>> members = [];
    try {
      members = await context.read<WorkspaceCubit>().getWorkspaceMembers(widget.workspaceId!, authState.token);
    } catch (e) {
      print('Error obteniendo miembros: $e');
    }

    if (mounted) {
      final wsState = context.read<WorkspaceCubit>().state;
      int? adminId;
      String? adminUsername;
      if (wsState is WorkspaceLoaded) {
        final currentWS = wsState.workspaces.firstWhere(
          (w) => w['id'] == widget.workspaceId,
          orElse: () => null,
        );
        if (currentWS != null) {
          final adminRaw = currentWS['admin'];
          if (adminRaw is int) {
            adminId = adminRaw;
            adminUsername = 'Administrador';
          } else if (adminRaw is Map) {
            adminId = adminRaw['id'];
            adminUsername = adminRaw['username'] ?? 'Administrador';
          }
          _isAdmin = (adminId == authState.userId);
        }
      }

      List<Map<String, dynamic>> finalMembers = List.from(members);
      if (adminId != null && !finalMembers.any((m) => m['id'] == adminId)) {
        finalMembers.add({'id': adminId, 'username': adminUsername ?? 'Administrador'});
      }
      finalMembers.sort((a, b) => (a['username'] ?? '').compareTo(b['username'] ?? ''));
      setState(() {
        _workspaceMembers = finalMembers;
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
              appBar: AppBar(
                title: const Text('Workspace'),
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.bar_chart),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MetricsScreen(workspaceId: widget.workspaceId!),
                        ),
                      );
                    },
                    tooltip: 'Ver métricas',
                  ),
                ],
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => KanbanScreen(
                        workspaceId: widget.workspaceId!,
                        isAdmin: _isAdmin,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.view_kanban),
                label: const Text("Ver Kanban"),
                backgroundColor: Colors.purple,
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(currentWS),
                    const SizedBox(height: 24),
                    _buildQuickForm(),
                    const SizedBox(height: 24),
                    _buildTaskList(),
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

  // ========== CABECERA (sin cambios) ==========
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
    if (_workspaceMembers.isEmpty) {
      return OutlinedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.person_outline, size: 16),
        label: const Text('Sin miembros'),
        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12)),
      );
    }
    final validSelected = _selectedUserId != null && _workspaceMembers.any((m) => m['id'] == _selectedUserId)
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
          items: _workspaceMembers.map((member) {
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

  // ========== CREAR TAREA COMPLETO ==========
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

    if (_selectedUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes asignar la tarea a un miembro del equipo')),
      );
      return;
    }

    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final formattedDate = _selectedDate != null
          ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
          : null;

      final payload = <String, dynamic>{
        'titulo': title,
        'descripcion': _descController.text.trim(),
        'prioridad': _selectedPriority,
        'fecha_vencimiento': formattedDate,
        'workspace': widget.workspaceId,
        'asignado_a': _selectedUserId,
      };

      await context.read<TaskCubit>().createTask(payload, authState.token);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Tarea creada'), backgroundColor: Colors.green),
      );

      _titleController.clear();
      _descController.clear();
      setState(() {
        _selectedDate = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ========== LISTA DE TAREAS CON PESTAÑAS ==========
  Widget _buildTaskList() {
    return BlocBuilder<TaskCubit, TaskState>(
      builder: (context, state) {
        if (state is TaskLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is TaskError) {
          return Center(child: Text('Error al cargar tareas: ${state.message}'));
        }
        if (state is TaskLoadedWorkspace) {
          final tasks = state.tasks.map((t) => Task.fromJson(t)).toList();
          if (tasks.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
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

          // Construir mapa de nombres de miembros
          final Map<int, String> membersMap = {};
          for (var member in _workspaceMembers) {
            final id = member['id'] as int;
            final username = member['username'] as String? ?? 'Usuario';
            membersMap[id] = username;
          }

          final authState = context.read<AuthCubit>().state;
          final currentUserId = authState is AuthSuccess ? authState.userId : null;

          return DefaultTabController(
            length: 3,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TabBar(
                    indicatorColor: Colors.purple,
                    labelColor: Colors.purple,
                    unselectedLabelColor: Colors.grey,
                    tabs: const [
                      Tab(text: 'To Do'),
                      Tab(text: 'In Progress'),
                      Tab(text: 'Done'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: TabBarView(
                    children: [
                      _buildTaskListByStatus(tasks, 'TODO', membersMap, currentUserId),
                      _buildTaskListByStatus(tasks, 'PROG', membersMap, currentUserId),
                      _buildTaskListByStatus(tasks, 'DONE', membersMap, currentUserId),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildTaskListByStatus(List<Task> allTasks, String status, Map<int, String> membersMap, int? currentUserId) {
    final filteredTasks = allTasks.where((t) => t.status == status).toList();
    final order = {'A': 0, 'M': 1, 'B': 2};
    filteredTasks.sort((a, b) => order[a.priority]!.compareTo(order[b.priority]!));

    if (filteredTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text('No tasks', style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredTasks.length,
      itemBuilder: (context, index) => _TaskCard(
        task: filteredTasks[index],
        isAdmin: _isAdmin,
        currentUserId: currentUserId,
        membersMap: membersMap,
      ),
    );
  }
}

// ========== TARJETA DE TAREA ==========
class _TaskCard extends StatelessWidget {
  final Task task;
  final bool isAdmin;
  final int? currentUserId;
  final Map<int, String> membersMap;

  const _TaskCard({
    required this.task,
    required this.isAdmin,
    required this.currentUserId,
    required this.membersMap,
  });

  @override
  Widget build(BuildContext context) {
    final canEdit = isAdmin || (currentUserId != null && task.assignedTo == currentUserId);
    final assignedName = task.assignedTo != null
        ? (membersMap[task.assignedTo] ?? 'User ${task.assignedTo}')
        : null;

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
                if (canEdit)
                  Checkbox(
                    value: task.status == 'DONE',
                    onChanged: (_) => _updateStatus(context, task.status == 'DONE' ? 'TODO' : 'DONE'),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  )
                else
                  Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: task.status == 'DONE' ? const Icon(Icons.check, size: 16, color: Colors.green) : null,
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
                          decoration: task.status == 'DONE' ? TextDecoration.lineThrough : null,
                          color: task.status == 'DONE' ? Colors.grey.shade500 : Colors.grey.shade800,
                        ),
                      ),
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            decoration: task.status == 'DONE' ? TextDecoration.lineThrough : null,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 12),
                      _buildMetadata(assignedName),
                    ],
                  ),
                ),
                if (canEdit)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editTask(context);
                      } else if (value == 'delete') {
                        _deleteTask(context);
                      } else if (value == 'TODO' || value == 'PROG' || value == 'DONE') {
                        _updateStatus(context, value);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'TODO', child: Text('To Do')),
                      const PopupMenuItem(value: 'PROG', child: Text('In Progress')),
                      const PopupMenuItem(value: 'DONE', child: Text('Done')),
                      const PopupMenuDivider(),
                      const PopupMenuItem(value: 'edit', child: Row(
                        children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')],
                      )),
                      const PopupMenuItem(value: 'delete', child: Row(
                        children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))],
                      )),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadata(String? assignedName) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildPriorityBadge(),
        if (task.categoryDetails != null) _buildCategoryBadge(),
        if (task.dueDate != null) _buildDueDateBadge(),
        if (assignedName != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.purple.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person, size: 12, color: Colors.purple),
                const SizedBox(width: 4),
                Text(assignedName, style: const TextStyle(fontSize: 11, color: Colors.purple, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
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
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildCategoryBadge() {
    final categoryColor = Color(int.parse('0xFF${task.categoryDetails!['color']}'));
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
          Container(width: 8, height: 8, decoration: BoxDecoration(color: categoryColor, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(categoryName, style: TextStyle(fontSize: 11, color: categoryColor, fontWeight: FontWeight.w600)),
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
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _updateStatus(BuildContext context, String newStatus) {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthSuccess) {
      context.read<TaskCubit>().updateTask(task.id, {'estado': newStatus}, authState.token);
    }
  }

  void _editTask(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CreateTaskModal(task: task),
    );
  }

  void _deleteTask(BuildContext context) {
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