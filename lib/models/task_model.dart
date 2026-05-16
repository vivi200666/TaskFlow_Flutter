class Tarea {
  final int id;
  final String titulo;
  final String descripcion;
  final String estado;
  final bool completada;

  Tarea({
    required this.id, 
    required this.titulo, 
    required this.descripcion, 
    required this.estado,
    required this.completada
  });

  // Este es el método clave: convierte el JSON de Django a objeto Dart 
  factory Tarea.fromJson(Map<String, dynamic> json) {
    return Tarea(
      id: json['id'],
      titulo: json['titulo'],
      descripcion: json['descripcion'] ?? '',
      estado: json['estado'],
      completada: json['completada'],
    );
  }
}