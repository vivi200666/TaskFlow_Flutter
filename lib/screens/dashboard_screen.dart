import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'login_screen.dart';
import 'create_task_modal.dart';
import 'views/my_day_screen.dart';
import 'views/upcoming_tasks_screen.dart';
import 'views/completed_screen.dart';
import 'views/category_screen.dart';
import 'views/workspace_screen.dart';

import '../bloc/auth/auth_cubit.dart';
import '../bloc/task/task_cubit.dart';
import '../bloc/auth/auth_state.dart';
import '../bloc/category/category_cubit.dart';
import '../bloc/category/category_state.dart';
import '../models/category_model.dart';
import '../bloc/workspace/workspace_cubit.dart';
import '../bloc/workspace/workspace_state.dart';

// Enum for views
enum CurrentView {
  myDay,
  upcomingTasks,
  completed,
  category,
  workspace,
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  CurrentView _currentView = CurrentView.myDay;
  int? _selectedCategoryId;
  int? _selectedWorkspaceId;
  String? _selectedCategoryName;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthSuccess) {
      context.read<CategoryCubit>().loadCategories(authState.token);
      // Cargar workspaces del usuario
      try {
        context.read<WorkspaceCubit>().loadWorkspaces(authState.token);
      } catch (_) {}
    }
  }

  void _changeView(
    CurrentView newView, {
    int? categoryId,
    int? workspaceId,
    String? categoryName,
  }) {
    final authState = context.read<AuthCubit>().state;
    
    if (authState is AuthSuccess) {
      final token = authState.token;
      final taskCubit = context.read<TaskCubit>();

      // Disparamos la carga según la vista a la que vamos
      switch (newView) {
      case CurrentView.myDay:
        taskCubit.loadPersonalTasks(token);
        break;
      case CurrentView.upcomingTasks:
        taskCubit.loadUpcomingTasks(token); // <--- Nuevo método
        break;
      case CurrentView.completed:
        taskCubit.loadCompletedTasks(token); // <--- Nuevo método
        break;
      case CurrentView.workspace:
        if (workspaceId != null) {
          taskCubit.loadWorkspaceTasks(workspaceId, token);
        }
        break;
      case CurrentView.category:
        taskCubit.emitLoading(); // Limpia mientras implementas carga por categoría
        break;
    }
    }

    setState(() {
      _currentView = newView;
      _selectedCategoryId = categoryId;
      _selectedWorkspaceId = workspaceId;
      _selectedCategoryName = categoryName;
    });
    
    Navigator.pop(context); // Cierra el drawer
  }

  String _getViewTitle() {
    switch (_currentView) {
      case CurrentView.myDay:
        return 'My Day';
      case CurrentView.upcomingTasks:
        return 'Upcoming Tasks';
      case CurrentView.completed:
        return 'Completed';
      case CurrentView.category:
        return _selectedCategoryName ?? 'Category';
      case CurrentView.workspace:
        return 'Workspace';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          _getViewTitle(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3142),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2D3142)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_task),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const CreateTaskModal(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              // TODO: Implement notifications
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _buildDrawer(),
      body: _buildMainContent(),
    );
  }

  // ========== DRAWER ==========

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            _buildDrawerHeader(),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildMainNavigation(),
                  const SizedBox(height: 16),
                  _buildCategoriesSection(),
                  const SizedBox(height: 16),
                  _buildWorkspacesSection(),
                ],
              ),
            ),
            const Divider(height: 1),
            _buildDrawerFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 50, 24, 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.task_alt, color: Colors.purple, size: 24),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TaskFlow',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'Productivity Center',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainNavigation() {
    return Column(
      children: [
        _buildMenuItem(
          icon: Icons.wb_sunny_outlined,
          label: 'My Day',
          isSelected: _currentView == CurrentView.myDay,
          onTap: () => _changeView(CurrentView.myDay),
        ),
        _buildMenuItem(
          icon: Icons.calendar_today_outlined,
          label: 'Upcoming Tasks',
          isSelected: _currentView == CurrentView.upcomingTasks,
          onTap: () => _changeView(CurrentView.upcomingTasks),
        ),
        _buildMenuItem(
          icon: Icons.check_circle_outline,
          label: 'Completed',
          isSelected: _currentView == CurrentView.completed,
          onTap: () => _changeView(CurrentView.completed),
        ),
      ],
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'CATEGORIES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 18),
                onPressed: () {
                  Navigator.pop(context);
                  _showCreateCategoryDialog();
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        BlocBuilder<CategoryCubit, CategoryState>(
          builder: (context, state) {
            if (state is CategoryLoading) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }

            if (state is CategoryLoaded) {
              if (state.categories.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'No categories',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                );
              }

              return Column(
                children: state.categories.map((category) {
                  return _buildCategoryItem(category);
                }).toList(),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildCategoryItem(Category category) {
    final isSelected = _currentView == CurrentView.category &&
        _selectedCategoryId == category.id;

    // 1. Tu lógica de colores (la dejamos igualita)
    final Map<String, Color> namedColors = {
      'rojo': Colors.red, 'azul': Colors.blue, 'verde': Colors.green,
      'amarillo': Colors.yellow, 'gris': Colors.grey,
    };
    Color dotColor = Colors.grey;
    try {
      final colorString = category.color.trim();
      if (colorString.isNotEmpty) {
        String hex = colorString.replaceAll('#', '');
        if (hex.length == 6) hex = 'FF$hex';
        dotColor = Color(int.parse(hex, radix: 16));
      }
    } catch (_) {
      final name = (category.color).toLowerCase().trim();
      if (namedColors.containsKey(name)) dotColor = namedColors[name]!;
    }

    // 2. El diseño del renglón
    return ListTile(
      dense: true,
      leading: Container(
        width: 12, height: 12,
        decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
      ),
      title: Text(
        category.name,
        style: TextStyle(
          fontSize: 14,
          color: isSelected ? Colors.purple : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      
      // --- ESTA ES LA PARTE QUE ME PREGUNTASTE ---
      // Ponemos los botones al final (derecha)
      trailing: Row(
        mainAxisSize: MainAxisSize.min, 
        children: [
          // BOTÓN EDITAR
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.blueGrey),
            onPressed: () => _showEditCategoryModal(context, category),
          ),
          // BOTÓN ELIMINAR
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
            onPressed: () => _confirmDeleteCategory(context, category),
          ),
        ],
      ),
      // -------------------------------------------

      selected: isSelected,
      selectedTileColor: Colors.purple.shade50,
      onTap: () => _changeView(
        CurrentView.category,
        categoryId: category.id,
        categoryName: category.name,
      ),
    );
  }


  // 1. FUNCIÓN PARA MOSTRAR EL MODAL DE EDICIÓN
  void _showEditCategoryModal(BuildContext context, Category category) {
    final nameController = TextEditingController(text: category.name);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar Categoría'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Nombre de la categoría'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final authState = context.read<AuthCubit>().state;
              if (authState is AuthSuccess) {
                // Aquí llamamos a tu Cubit con los datos sueltos
                context.read<CategoryCubit>().updateCategory(
                      category.id,
                      nameController.text,
                      category.color, // Mantenemos el color actual
                      authState.token,
                    );
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  // 2. FUNCIÓN PARA MOSTRAR EL DIÁLOGO DE ELIMINACIÓN
  void _confirmDeleteCategory(BuildContext context, Category category) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Eliminar categoría?'),
        content: Text('¿Estás segura de eliminar "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final authState = context.read<AuthCubit>().state;
              if (authState is AuthSuccess) {
                // Llamamos a borrar usando el ID y el Token
                context.read<CategoryCubit>().deleteCategory(
                      category.id,
                      authState.token,
                    );
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspacesSection() {
    return ExpansionTile(
      leading: const Icon(Icons.group_work_outlined, size: 20),
      title: const Text(
        'TEAM WORKSPACES',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
      ),
      children: [
        ListTile(
          dense: true,
          leading: const Icon(Icons.add, size: 18),
          title: const Text('Create Workspace', style: TextStyle(fontSize: 13)),
          onTap: () {
            Navigator.pop(context);
            _showCreateWorkspaceDialog();
          },
        ),
        ListTile(
          dense: true,
          leading: const Icon(Icons.login, size: 18),
          title: const Text('Join Workspace', style: TextStyle(fontSize: 13)),
          onTap: () {
            Navigator.pop(context);
            _showJoinWorkspaceDialog();
          },
        ),
        const Divider(),
        // Mostrar lista de workspaces si hay datos
        BlocBuilder<WorkspaceCubit, WorkspaceState>(
          builder: (context, state) {
            if (state is WorkspaceLoading) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            if (state is WorkspaceLoaded) {
              if (state.workspaces.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('No workspaces', style: TextStyle(color: Colors.grey, fontSize: 12)),
                );
              }
              return Column(
                children: state.workspaces.map((w) {
                  final id = (w is Map && w['id'] is int) ? w['id'] as int : null;
                  final nombre = (w is Map && w['nombre'] != null) ? w['nombre'].toString() : 'Workspace';
                  final descripcion = (w is Map && w['descripcion'] != null) ? w['descripcion'].toString() : null;
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.workspaces_filled, size: 18),
                    title: Text(nombre, style: const TextStyle(fontSize: 13)),
                    subtitle: descripcion != null ? Text(descripcion, maxLines: 1, overflow: TextOverflow.ellipsis) : null,
                    onTap: () {
                      _changeView(CurrentView.workspace, workspaceId: id);
                    },
                  );
                }).toList(),
              );
            }
            if (state is WorkspaceError) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(state.message, style: const TextStyle(color: Colors.red, fontSize: 12)),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.purple : Colors.grey),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.purple : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.purple.shade50,
      onTap: onTap,
    );
  }

  Widget _buildDrawerFooter() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ListTile(
            dense: true,
            leading: const Icon(Icons.settings, size: 20),
            title: const Text('Settings', style: TextStyle(fontSize: 13)),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to settings
            },
          ),
          ListTile(
            dense: true,
            leading: const Icon(Icons.logout, size: 20, color: Colors.redAccent),
            title: const Text(
              'Sign Out',
              style: TextStyle(fontSize: 13, color: Colors.redAccent),
            ),
            onTap: () {
              Navigator.pop(context);
              _confirmSignOut();
            },
          ),
        ],
      ),
    );
  }

  // ========== MAIN CONTENT ==========

  Widget _buildMainContent() {
    switch (_currentView) {
      case CurrentView.myDay:
        return const MyDayScreen();
      case CurrentView.upcomingTasks:
        return const UpcomingTasksScreen();
      case CurrentView.completed:
        return const CompletedScreen();
      case CurrentView.category:
        return CategoryScreen(categoryId: _selectedCategoryId!);
      case CurrentView.workspace:
        return WorkspaceScreen(workspaceId: _selectedWorkspaceId);
    }
  }

  // ========== DIALOGS ==========

  void _showCreateCategoryDialog() {
    final TextEditingController nameController = TextEditingController();
    // Color por defecto (sin '#', mayúsculas)
    String selectedColorHex = 'FF6B6B';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          // Lista de colores disponibles (hex sin '#')
          final List<Map<String, String>> palette = [
            {'name': 'Rojo', 'hex': 'FF6B6B'},
            {'name': 'Azul', 'hex': '4D8AFF'},
            {'name': 'Verde', 'hex': '34D399'},
            {'name': 'Amarillo', 'hex': 'FACC15'},
            {'name': 'Morado', 'hex': '8B5CF6'},
            {'name': 'Naranja', 'hex': 'FF8A4C'},
          ];

          Widget _buildColorCircle(String hex) {
            final bool isSelected = selectedColorHex.toUpperCase() == hex.toUpperCase();
            Color color;
            try {
              // Soporta RRGGBB o AARRGGBB; si es RRGGBB añadimos alpha FF
              final cleaned = hex.replaceAll('#', '').toUpperCase();
              if (cleaned.length == 6) {
                color = Color(int.parse('0xFF$cleaned'));
              } else if (cleaned.length == 8) {
                color = Color(int.parse('0x$cleaned'));
              } else {
                color = Colors.grey;
              }
            } catch (_) {
              color = Colors.grey;
            }

            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedColorHex = hex.replaceAll('#', '').toUpperCase();
                });
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: Colors.black.withOpacity(0.6), width: 2)
                      : Border.all(color: Colors.transparent, width: 2),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 18, color: Colors.white)
                    : null,
              ),
            );
          }

          return AlertDialog(
            title: const Text('New Category'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Choose color',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: palette.map((p) => _buildColorCircle(p['hex']!)).toList(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Name is required')),
                    );
                    return;
                  }

                  // Normalizar color: quitar '#' y pasar a mayúsculas
                  String normalized = selectedColorHex.replaceAll('#', '').toUpperCase();

                  // Enviar al cubit (CategoryCubit.createCategory)
                  final authState = context.read<AuthCubit>().state;
                  if (authState is AuthSuccess) {
                    context.read<CategoryCubit>().createCategory(
                          name,
                          normalized,
                          authState.token,
                        );
                  }

                  Navigator.pop(dialogContext);
                },
                child: const Text('Create'),
              ),
            ],
          );
        },
      ),
    );
  }

  // DIALOG: Crear Workspace
  void _showCreateWorkspaceDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Create Workspace'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        final name = nameController.text.trim();
                        final desc = descController.text.trim();
                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name is required')));
                          return;
                        }
                        final authState = context.read<AuthCubit>().state;
                        if (authState is! AuthSuccess) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not authenticated')));
                          return;
                        }

                        setState(() => isLoading = true);
                        try {
                          final success = await context.read<WorkspaceCubit>().createWorkspace(name, desc, authState.token);
                          setState(() => isLoading = false);
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Workspace created')));
                            await context.read<WorkspaceCubit>().loadWorkspaces(authState.token);
                            Navigator.pop(dialogContext);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not create workspace')));
                          }
                        } catch (e) {
                          setState(() => isLoading = false);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                child: isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Create'),
              ),
            ],
          );
        },
      ),
    );
  }

  // DIALOG: Unirse a Workspace por código
  void _showJoinWorkspaceDialog() {
    final TextEditingController codeController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Join Workspace'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(labelText: 'Access Code', border: OutlineInputBorder()),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        final code = codeController.text.trim();
                        if (code.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code is required')));
                          return;
                        }
                        final authState = context.read<AuthCubit>().state;
                        if (authState is! AuthSuccess) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not authenticated')));
                          return;
                        }

                        setState(() => isLoading = true);
                        try {
                          final success = await context.read<WorkspaceCubit>().joinWorkspace(code, authState.token);
                          setState(() => isLoading = false);
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Joined workspace')));
                            await context.read<WorkspaceCubit>().loadWorkspaces(authState.token);
                            Navigator.pop(dialogContext);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid code or join failed')));
                          }
                        } catch (e) {
                          setState(() => isLoading = false);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                child: isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Join'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sign Out?"),
        content: const Text("Are you sure you want to sign out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              // 1) Limpiar estados locales de cubits para evitar que la app quede en estado inconsistente
              try {
                context.read<TaskCubit>().reset();
              } catch (_) {}
              try {
                context.read<CategoryCubit>().reset();
              } catch (_) {}
              try {
                context.read<WorkspaceCubit>().reset();
              } catch (_) {}
              // 2) Cerrar sesión en AuthCubit (debe emitir estado inicial o similar)
              context.read<AuthCubit>().logout();

              // 3) Navegar al Login y eliminar historial de rutas
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text(
              "Sign Out",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}