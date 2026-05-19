class Profile {
  final String? image; // can be null if no photo uploaded
  final String bio;

  Profile({
    this.image,
    required this.bio,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      image: json['imagen'],
      bio: json['bio'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'imagen': image,
      'bio': bio,
    };
  }

  Profile copyWith({
    String? image,
    String? bio,
  }) {
    return Profile(
      image: image ?? this.image,
      bio: bio ?? this.bio,
    );
  }
}

class User {
  final int id;
  final String username;
  final String email;
  final Profile? profile;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.profile,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'] ?? '',
      profile: json['perfil'] != null ? Profile.fromJson(json['perfil']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'perfil': profile?.toJson(),
    };
  }

  User copyWith({
    int? id,
    String? username,
    String? email,
    Profile? profile,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      profile: profile ?? this.profile,
    );
  }
}