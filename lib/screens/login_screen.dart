import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth/auth_cubit.dart';
import '../bloc/auth/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    // Usamos LayoutBuilder para detectar el tamaño de la pantalla (Criterio 4: Responsividad)
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) {
            // Diseño para PC / Tablet Horizontal (Dos columnas)
            return Row(
              children: [
                Expanded(child: _buildBrandingSide()),
                Expanded(child: _buildFormSide()),
              ],
            );
          } else {
            // Diseño para Celular (Una columna)
            return SingleChildScrollView(
              child: SizedBox(
                height: MediaQuery.of(context).size.height,
                child: _buildFormSide(),
              ),
            );
          }
        },
      ),
    );
  }

  // Lado Izquierdo: Diseño de Marketing (Solo PC)
  Widget _buildBrandingSide() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3E5F5), // Morado muy suave como la imagen
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.all(60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 15),
              const Text(
                'TaskFlow',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text('Centro de productividad', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 60),
          const Text(
            'Organiza tu tiempo,\nalcanza tus metas',
            style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, height: 1.2),
          ),
          const SizedBox(height: 20),
          const Text(
            'Gestiona tus tareas de forma inteligente\ny mejora tu productividad cada día.',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 40),
          // Aquí simulamos la ilustración con un icono grande o imagen
          const Center(
            child: Icon(Icons.calendar_today_outlined, size: 250, color: Colors.purple),
          ),
        ],
      ),
    );
  }

  // Lado Derecho: El Formulario (PC y Celular)
  Widget _buildFormSide() {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Bienvenido!'), backgroundColor: Colors.green),
          );
        }
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.mensaje), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 60.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '¡Bienvenido de vuelta!',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text('Inicia sesión para continuar', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),
              
              // Campo Email
              const Text('Correo electrónico', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: 'tu@email.com',
                  prefixIcon: const Icon(Icons.mail_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              
              // Campo Password
              const Text('Contraseña', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  hintText: 'Ingresa tu contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text('¿Olvidaste tu contraseña?', style: TextStyle(color: Colors.purple)),
                ),
              ),
              const SizedBox(height: 20),
              
              // Botón Principal (Criterio 6: Manejo de estado Loading)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: state is AuthLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: state is AuthLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Iniciar sesión', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
              
              const SizedBox(height: 20),
              const Center(child: Text('o')),
              const SizedBox(height: 20),
              
              // Botón Google (Estilo visual de la imagen)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.g_mobiledata, size: 30, color: Colors.red),
                  label: const Text('Continuar con Google', style: TextStyle(color: Colors.black)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('¿No tienes una cuenta?'),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Regístrate', style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleLogin() {
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();

    if (email.isNotEmpty && pass.isNotEmpty) {
      context.read<AuthCubit>().iniciarSesion(email, pass);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa los campos')),
      );
    }
  }
}