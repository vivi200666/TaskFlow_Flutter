import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/task/task_cubit.dart';
import '../bloc/task/task_state.dart';
import '../bloc/auth/auth_cubit.dart';
import '../bloc/auth/auth_state.dart';

class MiDiaScreen extends StatelessWidget {
  const MiDiaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Usamos Column para mantener tu título arriba
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Mis Tareas Personales", 
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 20),
            
            // LISTA DINÁMICA CON BLOC
            Expanded(
              child: BlocBuilder<TaskCubit, TaskState>(
                builder: (context, state) {
                  if (state is TaskLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is TaskLoaded) {
                    if (state.tareasPersonales.isEmpty) {
                      return const Center(child: Text("¡Día libre! No hay tareas."));
                    }
                    return ListView.builder(
                      itemCount: state.tareasPersonales.length,
                      itemBuilder: (context, index) {
                        final tarea = state.tareasPersonales[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: const Icon(Icons.circle_outlined, color: Colors.purple),
                            title: Text(tarea.titulo),
                            subtitle: Text(tarea.descripcion),
                          ),
                        );
                      },
                    );
                  } else if (state is TaskError) {
                    return Center(child: Text(state.mensaje, style: const TextStyle(color: Colors.red)));
                  }
                  return const Center(child: Text("Cargando tus tareas..."));
                },
              ),
            ),
          ],
        ),
      ),
      
      // EL CAMPO PARA AGREGAR TAREAS (Pegado al teclado)
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _buildQuickAddTask(context),
      ),
    );
  }

  Widget _buildQuickAddTask(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    
    // Sacamos el token para enviarlo a la API
    final authState = context.read<AuthCubit>().state;
    String token = (authState is AuthSuccess) ? authState.token : "";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: "Agregar una nueva tarea...",
          prefixIcon: const Icon(Icons.add_circle, color: Colors.purple),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) {
            // Acción real del Cubit
            context.read<TaskCubit>().agregarNuevaTarea(
              value.trim(), 
              "Tarea creada desde Mi Día", 
              token
            );
            controller.clear();
          }
        },
      ),
    );
  }
}