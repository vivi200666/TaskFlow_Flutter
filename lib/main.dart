import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// --- IMPORTACIONES DE DATOS Y LÓGICA ---
import 'data/api_provider.dart';
import 'bloc/task/task_cubit.dart';
import 'bloc/auth/auth_cubit.dart';
import 'bloc/auth/auth_state.dart';

// --- IMPORTACIÓN DE PANTALLAS ---
import 'screens/dashboard_screen.dart'; 

void main() {
  // Eliminamos el const de aquí también para evitar problemas en el árbol superior
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => ApiProvider()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => TaskCubit(context.read<ApiProvider>()),
          ),
          BlocProvider(
            create: (context) => AuthCubit(context.read<ApiProvider>()),
          ),
        ],
        child: MaterialApp(
          title: 'TaskFlow - Admin de Tareas',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true, 
            colorSchemeSeed: Colors.purple,
          ),
          // La pantalla inicial
          home: const LoginScreen(),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    bool isDesktop = width > 800;

    return Scaffold(
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.mensaje),
                backgroundColor: Colors.red,
              ),
            );
          }
          if (state is AuthSuccess) {
            // 1. Cargamos tareas con el token obtenido
            context.read<TaskCubit>().cargarYFiltrarTareas(state.token);

            // 2. Navegación al Dashboard (SIN CONST)
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => DashboardScreen(), // ✅ Clase corregida
              ),
            );
          }
        },
        builder: (context, state) {
          return Row(
            children: [
              if (isDesktop)
                Expanded(
                  child: Container(
                    color: const Color(0xFFF3E5F5),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.task_alt, size: 100, color: Colors.purple),
                        SizedBox(height: 20),
                        Text(
                          "TaskFlow",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Organiza tu tiempo, alcanza tus metas",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        "¡Bienvenida de vuelta!",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 40),
                      TextField(
                        controller: _userController,
                        decoration: const InputDecoration(
                          labelText: 'Usuario',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _passController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Contraseña',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                        ),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        onPressed: state is AuthLoading
                            ? null
                            : () {
                                context.read<AuthCubit>().iniciarSesion(
                                      _userController.text.trim(),
                                      _passController.text.trim(),
                                    );
                              },
                        child: state is AuthLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text("Iniciar Sesión"),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}