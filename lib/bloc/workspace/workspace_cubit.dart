import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/api_provider.dart';
import 'workspace_state.dart';

class WorkspaceCubit extends Cubit<WorkspaceState> {
  final ApiProvider apiProvider;

  WorkspaceCubit(this.apiProvider) : super(WorkspaceInitial());

  // Función lógica para cargar los espacios de trabajo
  Future<void> cargarEspacios() async {
    try {
      emit(WorkspaceLoading()); // 1. Cambia a estado "Cargando" (Círculo de progreso en UI)

      // Nota: Aquí se llamará al endpoint de Django correspondiente a tus Workspaces.
      // Por ahora, simulamos una pequeña espera de red para probar el estado y usamos datos base.
      await Future.delayed(const Duration(milliseconds: 800));
      
      final listaSimulada = [
        {"id": 1, "nombre": "Proyecto de Aula", "descripcion": "Tareas del grupo"},
        {"id": 2, "nombre": "Trabajo Flutter", "descripcion": "Fases del proyecto"}
      ];

      emit(WorkspaceLoaded(espacios: listaSimulada)); // 2. Cambia a estado "Éxito" con los datos
    } catch (e) {
      // Control de excepciones (Criterio 9)
      emit(WorkspaceError("No se pudieron cargar los espacios de trabajo: ${e.toString()}"));
    }
  }
}