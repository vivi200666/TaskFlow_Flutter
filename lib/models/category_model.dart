import 'package:flutter/material.dart';
class Category {
  final int id;
  final String name;
  final String color; // puede ser hex 'FF6B6B' o nombre 'ROJO'

  Category({
    required this.id,
    required this.name,
    required this.color,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    String raw = (json['color'] ?? '10B981').toString().trim();
    if (raw.startsWith('#')) {
      raw = raw.replaceFirst('#', '');
    }
    raw = raw.toUpperCase();

    // Mapeo de nombres de color a hexadecimal
    final Map<String, String> nameToHex = {
      'ROJO': 'FF0000',
      'AZUL': '0000FF',
      'VERDE': '00FF00',
      'AMARILLO': 'FFFF00',
      'GRIS': '808080',
      'MORADO': '800080',
      'NARANJA': 'FFA500',
      'RED': 'FF0000',
      'BLUE': '0000FF',
      'GREEN': '00FF00',
      'YELLOW': 'FFFF00',
      'GRAY': '808080',
      'PURPLE': '800080',
      'ORANGE': 'FFA500',
    };

    if (nameToHex.containsKey(raw)) {
      raw = nameToHex[raw]!;
    }

    if (raw.length == 6) {
      raw = 'FF$raw';
    }

    return Category(
      id: json['id'],
      name: json['nombre'],
      color: raw,
    );
  }

  // ✅ Método para obtener Color de forma segura
  Color getColor() {
    try {
      return Color(int.parse('0x$color'));
    } catch (e) {
      return Colors.grey;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': name,
      'color': color.startsWith('FF') && color.length == 8
          ? color.substring(2)
          : color,
    };
  }
}