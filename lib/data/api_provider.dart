import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/tarea_model.dart';
import '../models/categoria_model.dart';
import '../models/usuario_model.dart';

class ApiProvider {
  // Aquí pegarás el enlace que te genere Ngrok (ejemplo)
  final String baseUrl = "https://TU_ENLACE_DE_NGROK.ngrok-free.app/api";

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
}