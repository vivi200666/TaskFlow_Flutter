import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task_model.dart';
import '../models/category_model.dart';
import '../models/user_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/task_model.dart';
import '../models/category_model.dart';
import '../models/user_model.dart';
class ApiProvider {
  final String baseUrl = "http://127.0.0.1:8000/api";

  // ---------------------------------------------------------
  // 🔐 CONFIGURATION AND HEADERS
  // ---------------------------------------------------------
  Map<String, String> _getHeaders(String token) {
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  // ---------------------------------------------------------
  // 👤 AUTHENTICATION AND USERS
  // ---------------------------------------------------------
  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/token/');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username, "password": password}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception("Credenciales inválidas.");
    } else {
      throw Exception("Error del servidor: ${response.statusCode}");
    }
  }

  Future<List<User>> fetchUsers(String token) async {
    final url = Uri.parse('$baseUrl/usuarios/');
    final response = await http.get(url, headers: _getHeaders(token));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => User.fromJson(item)).toList();
    }
    throw Exception("Error fetching users: ${response.statusCode}");
  }

  // ---------------------------------------------------------
  // 📝 TASKS
  // ---------------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchTasks({required String token, int? workspaceId}) async {
    final uri = workspaceId != null
        ? Uri.parse('$baseUrl/tareas/?workspace=$workspaceId')
        : Uri.parse('$baseUrl/tareas/');
    final response = await http.get(uri, headers: _getHeaders(token));
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as List<dynamic>;
      return body.map((e) => e as Map<String, dynamic>).toList();
    }
    throw Exception('Error fetching tasks: ${response.statusCode} ${response.body}');
  }

  Future<Map<String, dynamic>> createTask(Map<String, dynamic> payload, String token) async {
    final url = Uri.parse('$baseUrl/tareas/');
    final response = await http.post(url, headers: _getHeaders(token), body: jsonEncode(payload));
    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception("Create task failed: ${response.statusCode} ${response.body}");
  }

  Future<Map<String, dynamic>> updateTask(int id, Map<String, dynamic> payload, String token) async {
    final url = Uri.parse('$baseUrl/tareas/$id/');
    final response = await http.patch(url, headers: _getHeaders(token), body: jsonEncode(payload));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception("Update task failed: ${response.statusCode} ${response.body}");
  }

  Future<void> updateTaskStatus(int id, String newStatus, String token) async {
    final url = Uri.parse('$baseUrl/tareas/$id/');
    final response = await http.patch(
      url,
      headers: _getHeaders(token),
      body: jsonEncode({"estado": newStatus}), // 'estado' JSON key preserved
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception("Error updating task status: ${response.statusCode}");
    }
  }

  Future<bool> deleteTask(int id, String token) async {
    final url = Uri.parse('$baseUrl/tareas/$id/');
    final response = await http.delete(url, headers: _getHeaders(token));
    return response.statusCode == 200 || response.statusCode == 204;
  }

  // ---------------------------------------------------------
  // 🏷️ CATEGORIES
  // ---------------------------------------------------------
  Future<List<Category>> fetchCategories(String token) async {
    final url = Uri.parse('$baseUrl/categorias/');
    final response = await http.get(url, headers: _getHeaders(token));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => Category.fromJson(item)).toList();
    }
    throw Exception("Error fetching categories: ${response.statusCode}");
  }

  Future<Category> createCategory(String name, String colorHex, String token) async {
    final url = Uri.parse('$baseUrl/categorias/');
    String normalized = colorHex.trim().replaceFirst('#', '').toUpperCase();

    final response = await http.post(
      url,
      headers: _getHeaders(token),
      body: jsonEncode({"nombre": name, "color": normalized}), // 'nombre' and 'color' JSON keys preserved
    );

    if (response.statusCode == 201) {
      return Category.fromJson(jsonDecode(response.body));
    }
    throw Exception("Create category failed: ${response.statusCode} ${response.body}");
  }
  Future<Category> updateCategory(int id, String name, String colorHex, String token) async {
    final url = Uri.parse('$baseUrl/categorias/$id/');
  // Mantenemos la lógica de normalización de color que ya usas
    String normalized = colorHex.trim().replaceFirst('#', '').toUpperCase();

    final response = await http.put(
      url,
      headers: _getHeaders(token),
      body: jsonEncode({"nombre": name, "color": normalized}),
    );

    if (response.statusCode == 200) {
      return Category.fromJson(jsonDecode(response.body));
    }
    throw Exception("Update category failed: ${response.statusCode}");
  }

  Future<bool> deleteCategory(int id, String token) async {
    final url = Uri.parse('$baseUrl/categorias/$id/');
    final response = await http.delete(url, headers: _getHeaders(token));
    return response.statusCode == 200 || response.statusCode == 204;
  }

  // ---------------------------------------------------------
  // 🏢 WORKSPACES
  // ---------------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchWorkspaces(String token) async {
    final url = Uri.parse('$baseUrl/workspaces/');
    final response = await http.get(url, headers: _getHeaders(token));
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as List<dynamic>;
      return body.map((e) => e as Map<String, dynamic>).toList();
    }
    throw Exception('Error fetching workspaces: ${response.statusCode} ${response.body}');
  }

  Future<bool> createWorkspace(String name, String description, String token) async {
    final url = Uri.parse('$baseUrl/workspaces/');
    final response = await http.post(
      url,
      headers: _getHeaders(token),
      body: jsonEncode({'nombre': name, 'descripcion': description}), // 'nombre' and 'descripcion' JSON keys preserved
    );
    if (response.statusCode == 201) return true;
    throw Exception('Create workspace failed: ${response.statusCode} ${response.body}');
  }

  Future<bool> joinWorkspace(String code, String token) async {
    final url = Uri.parse('$baseUrl/workspaces/unirse/');
    final response = await http.post(
      url,
      headers: _getHeaders(token),
      body: jsonEncode({'codigo': code}), // 'codigo' JSON key preserved
    );
    if (response.statusCode == 200 || response.statusCode == 204) return true;
    throw Exception('Join workspace failed: ${response.statusCode} ${response.body}');
  }

  Future<bool> deleteWorkspace(int id, String token) async {
    final url = Uri.parse('$baseUrl/workspaces/$id/');
    final response = await http.delete(url, headers: _getHeaders(token));
    return response.statusCode == 200 || response.statusCode == 204;
  }

  Future<List<Map<String, dynamic>>> fetchWorkspaceMembers(int workspaceId, String token) async {
    final url = Uri.parse('$baseUrl/workspaces/$workspaceId/members/');
    print('🔍 Llamando a: $url');  // 👈 Ver URL
    final response = await http.get(url, headers: _getHeaders(token));
    print('📦 Código respuesta: ${response.statusCode}');  // 👈 Ver código HTTP
    print('📄 Cuerpo: ${response.body}');                 // 👈 Ver respuesta completa
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    throw Exception('Failed to load workspace members');
  }
  // ---------------------------------------------------------
// 📊 WORKSPACE METRICS
// ---------------------------------------------------------
  Future<Map<String, dynamic>> fetchWorkspaceMetrics(int workspaceId, String token) async {
    final url = Uri.parse('$baseUrl/workspaces/$workspaceId/metricas/');
    final response = await http.get(url, headers: _getHeaders(token));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Error fetching workspace metrics: ${response.statusCode}');
  }
  Future<Map<String, dynamic>> register(String username, String email, String password) async {
    final url = Uri.parse('$baseUrl/register/');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": username,
        "email": email,
        "password": password,
      }),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      // Intentar extraer el mensaje de error del backend
      String errorMessage;
      try {
        final errorJson = jsonDecode(response.body);
        errorMessage = errorJson['error'] ?? 'Error al registrar usuario.';
      } catch (_) {
        errorMessage = 'Error al registrar usuario. Código: ${response.statusCode}';
      }
      throw Exception(errorMessage);
    }
  }
  // ========== USER PROFILE ==========
  Future<Map<String, dynamic>> fetchProfile(String token) async {
    final url = Uri.parse('$baseUrl/profile/');
    final response = await http.get(url, headers: _getHeaders(token));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Error fetching profile: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data, String token, {String? imagePath, List<int>? imageBytes}) async {
    final url = Uri.parse('$baseUrl/profile/');
    final request = http.MultipartRequest('PUT', url)
      ..headers['Authorization'] = 'Bearer $token';
    
    // Añadir campos de texto
    data.forEach((key, value) {
      if (value != null) request.fields[key] = value.toString();
    });
    
    // Manejar imagen de diferentes formas según plataforma
    if (imageBytes != null && imageBytes.isNotEmpty) {
      // Para web o móvil cuando ya tenemos los bytes
      final multipartFile = http.MultipartFile.fromBytes(
        'imagen',
        imageBytes,
        filename: 'profile.jpg',
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(multipartFile);
    } else if (imagePath != null && imagePath.isNotEmpty) {
      // Solo para móvil (iOS/Android): usar fromPath
      // Pero también podemos leer los bytes del archivo para unificar
      // Para simplificar, usaremos solo la versión con bytes y pediremos al ProfileScreen que lea los bytes.
      // Por ahora, lanzamos excepción en web si se usa imagePath sin bytes.
      throw Exception('Para web, proporciona imageBytes. Usa XFile.readAsBytes().');
    }
    
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    if (response.statusCode == 200) {
      return jsonDecode(responseBody);
    }
    throw Exception('Error updating profile: ${response.statusCode}');
  }
}
