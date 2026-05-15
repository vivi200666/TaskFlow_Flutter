class Categoria {
  final int id;
  final String nombre;
  final String color;

  Categoria({
    required this.id,
    required this.nombre,
    required this.color,
  });

  // El método fromJson que lee lo que envía Django
  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'],
      nombre: json['nombre'],
      color: json['color'] ?? '#10b981', // Color por defecto si viene nulo
    );
  }
}