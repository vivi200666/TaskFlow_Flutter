import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/tarea_model.dart';

class ApiProvider {
  // Aquí pondrás tu IP (ejemplo: 192.168.x.x)
  final String baseUrl = "http://TU_IP_LOCAL:8000/api";
  
  Future<List<Tarea>> getTareas() async {
    final url = Uri.parse('$baseUrl/tareas/');
    
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => Tarea.fromJson(item)).toList();
      } else {
        throw Exception("Error del servidor: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("No se pudo conectar al servidor: $e");
    }
  }
} 