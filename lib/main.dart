import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'data/api_provider.dart';
import 'bloc/tareas_cubit.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      // 1. Inyectamos el Provider de la API
      providers: [
        RepositoryProvider(create: (context) => ApiProvider()),
      ],
      child: MultiBlocProvider(
        // 2. Inyectamos el Cubit y le pasamos el Provider
        providers: [
          BlocProvider(
            create: (context) => TareasCubit(
              context.read<ApiProvider>(),
            )..cargarTareas(), // Llamamos a cargar tareas de una vez
          ),
        ],
        child: MaterialApp(
          title: 'Admin de Tareas',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.blue,
          ),
          home: const HomeScreen(),
        ),
      ),
    );
  }
}