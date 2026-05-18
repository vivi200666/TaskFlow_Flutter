import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// --- IMPORTACIONES DE PANTALLAS ---
import 'mi_dia_screen.dart';
import 'workspace_screen.dart'; // El Kanban ahora vive aquí dentro
import 'perfil_screen.dart';
import 'categorias_screen.dart';
import '../bloc/auth/auth_cubit.dart';
import '../bloc/auth/auth_state.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  // Lista de pantallas principales
  final List<Widget> _screens = [
    const MiDiaScreen(),        // 0: Mi Día (con métricas)
    const CategoriasScreen(),   // 1: Gestión de Categorías
    const WorkspaceScreen(),    // 2: Equipos / Workspace (Incluye Kanban)
    const PerfilScreen(),       // 3: Perfil (Bio, Imagen)
  ];

  final List<String> _titles = [
    "Resumen Diario",
    "Categorías",
    "Espacio de Equipo",
    "Mi Perfil",
  ];

  @override
  Widget build(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex > 3 ? 0 : _selectedIndex], // Ajuste por si el índice cambia
          style: const TextStyle(color: Color(0xFF2D3142), fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.grey),
            onPressed: () {},
          ),
          const SizedBox(width: 10),
        ],
      ),
      drawer: !isDesktop ? _buildSidebar(context) : null,
      body: Row(
        children: [
          if (isDesktop) _buildSidebar(context),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _screens[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }

  // --- CONSTRUCTOR DEL SIDEBAR ---
  Widget _buildSidebar(BuildContext context) {
    return Drawer(
      elevation: 0,
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // 1. HEADER DE USUARIO (Como tu imagen)
            _buildUserHeader(),
            
            const Divider(height: 1),

            // 2. LISTA DE NAVEGACIÓN
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildMenuItem(0, Icons.wb_sunny_outlined, "Mi Día"),
                  _buildMenuItem(1, Icons.category_outlined, "Categorías"),
                  
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Text("EQUIPOS", 
                      style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  _buildMenuItem(2, Icons.group_work_outlined, "Workspace Proyecto"),
                ],
              ),
            ),

            // 3. ACCIONES DE WORKSPACE Y LOGOUT (Abajo)
            const Divider(),
            _buildBottomActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader() {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        String nombre = "Usuario";
        String correo = "Cargando...";
        
        if (state is AuthSuccess) {
          // Aquí puedes mapear el nombre real si lo tienes en el estado
          correo = "Estudiante de Ingeniería"; 
        }

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 50, 16, 20),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundColor: Colors.purple,
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(correo, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings, size: 18, color: Colors.grey),
                onPressed: () => setState(() => _selectedIndex = 3),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.purple : Colors.grey),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.purple : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () {
        setState(() => _selectedIndex = index);
        if (Navigator.canPop(context)) Navigator.pop(context);
      },
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          ElevatedButton.icon(
            onPressed: () {
              // Aquí abriremos el diálogo de Crear Workspace mañana
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text("Nuevo Workspace"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 40),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _confirmarCerrarSesion(context),
            icon: const Icon(Icons.logout, size: 18, color: Colors.redAccent),
            label: const Text("Cerrar Sesión", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _confirmarCerrarSesion(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Salir?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("No")),
          TextButton(
            onPressed: () {
              context.read<AuthCubit>().cerrarSesion();
              Navigator.of(context).pushReplacementNamed('/');
            },
            child: const Text("Sí, cerrar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}