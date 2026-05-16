import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/task/task_cubit.dart';
import '../bloc/task/task_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Tareas de Django'),
        centerTitle: true,
      ),
      body: BlocBuilder<TareasCubit, TareasState>(
        builder: (context, state) {
          if (state is TareasLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is TareasLoaded) {
            return ListView.builder(
              itemCount: state.tareas.length,
              itemBuilder: (context, index) {
                final tarea = state.tareas[index];
                return ListTile(
                  title: Text(tarea.titulo),
                  subtitle: Text(tarea.descripcion),
                  trailing: Icon(
                    tarea.completada ? Icons.check_circle : Icons.pending,
                    color: tarea.completada ? Colors.green : Colors.orange,
                  ),
                );
              },
            );
          } else if (state is TareasError) {
            return Center(child: Text(state.mensaje));
          }
          return const Center(child: Text('Presiona el botón para cargar'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.read<TareasCubit>().cargarTareas(),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}