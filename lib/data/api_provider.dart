import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task_model.dart';
import '../models/category_model.dart';
import '../models/user_model.dart';

class ApiProvider {
  // URL local apuntando directamente a tu Django
  final String baseUrl = "http://127.0.0.1:8000/api";

  // 🔐 REGLA DE ORO: Ahora todas las peticiones llevan el Header de Authorization
  Map<String, String> _getHeaders(String token) {
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token", // Esto es lo que pide Django para darte los datos
    };
  }

  // Repositorio de Tareas - Ahora pide el token
  Future<List<Tarea>> getTareas(String token) async {
    final url = Uri.parse('$baseUrl/tareas/');
    print("🌐 Llamando a: $url");
    print("🔑 Longitud del Token: ${token.length}");// Solo los primeros 10 caracteres por seguridad
    try {
      final response = await http.get(url, headers: _getHeaders(token));
      if (response.statusCode == 401) {
        print("❌ Error 401: ${response.body}"); // Django suele decir por qué rechazó el token
      }
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

  // Repositorio de Categorías - Ahora pide el token
  Future<List<Categoria>> getCategorias(String token) async {
    final url = Uri.parse('$baseUrl/categorias/');
    try {
      final response = await http.get(url, headers: _getHeaders(token));
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

  // Repositorio de Usuarios - Ahora pide el token
  Future<List<Usuario>> getUsuarios(String token) async {
    final url = Uri.parse('$baseUrl/usuarios/');
    try {
      final response = await http.get(url, headers: _getHeaders(token));
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

  // Función para hacer Login (Esta no necesita token porque apenas lo va a pedir)
  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/token/');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "password": password
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception("Credenciales incorrectas. Verifica tu usuario o contraseña.");
      } else {
        throw Exception("Error en el servidor: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error de conexión real: $e");
    }
  }
  Future<void> actualizarEstadoTarea(int id, String nuevoEstado, String token) async {
    final url = Uri.parse('$baseUrl/tareas/$id/'); // Asegúrate de que tu URL termine en /
    
    try {
      final response = await http.patch(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({
          "estado": nuevoEstado, // Django recibirá esto y actualizará el campo
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception("Error al actualizar estado: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Fallo de red al mover tarea: $e");
    }
  }
  Future<Tarea> crearTarea(String titulo, String descripcion, String token) async {
    final url = Uri.parse('$baseUrl/tareas/');
    
    final response = await http.post(
      url,
      headers: _getHeaders(token),
      body: jsonEncode({
        "titulo": titulo,
        "descripcion": descripcion,
        "estado": "TODO", // Estado inicial por defecto
        "completada": false,
      }),
    );

    if (response.statusCode == 201) {
      return Tarea.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("No se pudo crear la tarea");
    }
  }
}