class Perfil {
  final String? imagen; // Puede ser nulo si no han subido foto
  final String bio;

  Perfil({
    this.imagen,
    required this.bio,
  });

  factory Perfil.fromJson(Map<String, dynamic> json) {
    return Perfil(
      imagen: json['imagen'],
      bio: json['bio'] ?? '',
    );
  }
}

class Usuario {
  final int id;
  final String username;
  final String email;
  final Perfil? perfil; // Mapea el perfil anidado del serializer

  Usuario({
    required this.id,
    required this.username,
    required this.email,
    this.perfil,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'],
      username: json['username'],
      email: json['email'] ?? '',
      // Si el perfil viene en el JSON, lo parseamos usando su propio fromJson
      perfil: json['perfil'] != null ? Perfil.fromJson(json['perfil']) : null,
    );
  }
}