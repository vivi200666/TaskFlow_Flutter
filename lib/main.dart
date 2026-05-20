import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'data/api_provider.dart';
import 'bloc/task/task_cubit.dart';
import 'bloc/category/category_cubit.dart';
import 'bloc/auth/auth_cubit.dart';
import 'bloc/workspace/workspace_cubit.dart';

import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart'; // ← nueva importación

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
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
          BlocProvider(create: (context) => AuthCubit(context.read<ApiProvider>()), lazy: false),
          BlocProvider(create: (context) => CategoryCubit(context.read<ApiProvider>()), lazy: false),
          BlocProvider(create: (context) => WorkspaceCubit(context.read<ApiProvider>()), lazy: false),
          BlocProvider(create: (context) => TaskCubit(context.read<ApiProvider>()), lazy: true),
        ],
        child: MaterialApp(
          navigatorKey: _navigatorKey,
          title: 'TaskFlow - Admin de Tareas',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.purple),
          initialRoute: '/login',
          routes: {
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/dashboard': (context) => const DashboardScreen(),
          },
        ),
      ),
    );
  }
}