import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// --- IMPORTACIONES DE DATOS Y LÓGICA ---
import 'data/api_provider.dart';
import 'bloc/task/task_cubit.dart';
import 'bloc/category/category_cubit.dart';
import 'bloc/auth/auth_cubit.dart';
import 'bloc/workspace/workspace_cubit.dart';

// --- IMPORTACIÓN DE PANTALLAS ---
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart'; // Asegúrate de que esta ruta sea correcta

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Navigator key opcional si quieres controlar navegación globalmente
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // No podemos usar context directamente aquí para leer cubits porque aún no están montados.
    // Ejecutaremos tryAutoLogin() después de que el primer frame haya sido renderizado,
    // cuando los providers ya estén disponibles en el árbol.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        // Si AuthCubit está registrado en el árbol de providers, esto lo llamará.
        // Si no está registrado aún, el try/catch evita que la app rompa.
        context.read<AuthCubit>().tryAutoLogin();
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => ApiProvider()),
      ],
      child: MultiBlocProvider(
        providers: [
          // AuthCubit debe crearse antes que los cubits que dependen del token
          BlocProvider(
            create: (context) => AuthCubit(context.read<ApiProvider>()),
            lazy: false,
          ),
          BlocProvider(
            create: (context) => CategoryCubit(context.read<ApiProvider>()),
            lazy: false,
          ),
          BlocProvider(
            create: (context) => WorkspaceCubit(context.read<ApiProvider>()),
            lazy: false,
          ),
          BlocProvider(
            create: (context) => TaskCubit(context.read<ApiProvider>()),
            lazy: true,
          ),
        ],
        child: MaterialApp(
          navigatorKey: _navigatorKey,
          title: 'TaskFlow - Admin de Tareas',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.purple,
          ),
          // Pantalla inicial: LoginScreen (el cubit intentará auto-login en initState)
          home: const LoginScreen(),
        ),
      ),
    );
  }
}
