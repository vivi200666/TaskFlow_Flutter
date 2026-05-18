import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/task/task_cubit.dart';
import '../bloc/task/task_state.dart';
import '../bloc/auth/auth_cubit.dart';
import '../bloc/auth/auth_state.dart';
import '../models/task_model.dart';

class KanbanScreen extends StatelessWidget {
  const KanbanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtenemos el token del AuthCubit para las peticiones
    final authState = context.read<AuthCubit>().state;
    String token = "";
    if (authState is AuthSuccess) {
      token = authState.token;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 20),
      child: BlocBuilder<TaskCubit, TaskState>(
        builder: (context, state) {
          if (state is TaskLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TaskError) {
            return Center(child: Text(state.mensaje, style: const TextStyle(color: Colors.red)));
          }

          if (state is TaskLoaded) {
            // Combinamos todas las tareas para distribuirlas en columnas
            final todas = [...state.tareasPersonales, ...state.tareasEquipo];

            return Row(
              children: [
                _buildKanbanColumn(context, "TODO", "To Do", todas, Colors.orange, token),
                _buildKanbanColumn(context, "PROG", "In Progress", todas, Colors.blue, token),
                _buildKanbanColumn(context, "DONE", "Done", todas, Colors.green, token),
              ],
            );
          }

          return const Center(child: Text("No hay tareas disponibles."));
        },
      ),
    );
  }

  Widget _buildKanbanColumn(
    BuildContext context,
    String estadoKey,
    String titulo,
    List<Tarea> tareas,
    Color color,
    String token,
  ) {
    // Filtramos las tareas que pertenecen a esta columna según tu TaskModel
    final tareasFiltradas = tareas.where((t) => t.estado.toUpperCase() == estadoKey).toList();

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Encabezado de la columna
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: color, width: 3)),
              ),
              child: Text(
                "$titulo (${tareasFiltradas.length})",
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            // Lista de tarjetas
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: tareasFiltradas.length,
                itemBuilder: (context, index) {
                  final tarea = tareasFiltradas[index];
                  return _buildTaskCard(context, tarea, token);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, Tarea tarea, String token) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tarea.titulo,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Text(
              tarea.descripcion,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            // Botones de cambio de estado rápido (Interatividad funcional)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (tarea.estado != 'TODO')
                  _moveButton(context, tarea, 'TODO', Icons.arrow_back_ios, token),
                if (tarea.estado != 'PROG')
                  _moveButton(context, tarea, 'PROG', Icons.play_arrow, token),
                if (tarea.estado != 'DONE')
                  _moveButton(context, tarea, 'DONE', Icons.check_circle, token),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _moveButton(BuildContext context, Tarea tarea, String nuevoEstado, IconData icono, String token) {
    return IconButton(
      constraints: const BoxConstraints(),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      icon: Icon(icono, size: 18, color: Colors.blueGrey),
      onPressed: () {
        // Llamada a la función de tu TaskCubit para mover la tarea
        context.read<TaskCubit>().moverTareaKanban(tarea.id, nuevoEstado, token);
      },
    );
  }
}