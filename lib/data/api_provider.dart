import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task_model.dart';
import '../models/category_model.dart';
import '../models/user_model.dart';

class ApiProvider {
  // Aquí pegarás el enlace que te genere Ngrok (ejemplo)
  final String baseUrl = "https://unmasking-saggy-cuddle.ngrok-free.dev/api";

  // Repositorio de Tareas
  Future<List<Tarea>> getTareas() async {
    final url = Uri.parse('$baseUrl/tareas/');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => Tarea.fromJson(item)).toList();
      } else {
        throw Exception("Error al traer tareas: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Fallo de conexión en tareas: $e");
    }
  }

  // Repositorio de Categorías
  Future<List<Categoria>> getCategorias() async {
    final url = Uri.parse('$baseUrl/categorias/');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => Categoria.fromJson(item)).toList();
      } else {
        throw Exception("Error al traer categorías: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Fallo de conexión en categorías: $e");
    }
  }

  // Repositorio de Usuarios
  Future<List<Usuario>> getUsuarios() async {
    final url = Uri.parse('$baseUrl/usuarios/');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => Usuario.fromJson(item)).toList();
      } else {
        throw Exception("Error al traer usuarios: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Fallo de conexión en usuarios: $e");
    }
  }
  // Función para hacer Login en Django
  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/token/'); // O el endpoint que use tu Django (ej: /login/)
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
        // Django suele retornar {"token": "xyz", "user_id": 1} o similar
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception("Credenciales incorrectas. Verifica tu usuario o contraseña.");
      } else {
        throw Exception("Error en el servidor: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("No se pudo conectar al servidor. Revisa tu conexión.");
    }
  }
}