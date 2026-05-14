import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/api_provider.dart';
import 'tareas_state.dart';

class TareasCubit extends Cubit<TareasState> {
  final ApiProvider apiProvider;

  // Al empezar, el estado es 'Initial'
  TareasCubit(this.apiProvider) : super(TareasInitial());

  // Función para pedir las tareas al Backend
  Future<void> cargarTareas() async {
    try {
      emit(TareasLoading()); // Avisamos que estamos cargando
      
      final lista = await apiProvider.getTareas();
      
      emit(TareasLoaded(lista)); // Enviamos las tareas a la pantalla
    } catch (e) {
      emit(TareasError("No se pudieron cargar las tareas: $e"));
    }
  }
}