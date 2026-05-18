import 'package:flutter/material.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const CircleAvatar(radius: 60, child: Icon(Icons.person, size: 60)),
          const SizedBox(height: 20),
          const TextField(decoration: InputDecoration(labelText: "Nombre de Usuario")),
          const SizedBox(height: 15),
          const TextField(
            maxLines: 3,
            decoration: InputDecoration(labelText: "Biografía", alignLabelWithHint: true),
          ),
          const SizedBox(height: 30),
          ElevatedButton(onPressed: () {}, child: const Text("Actualizar Perfil")),
        ],
      ),
    );
  }
}