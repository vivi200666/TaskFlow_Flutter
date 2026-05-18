import 'package:flutter/material.dart';

class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({super.key});

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  final List<Color> _coloresDisponibles = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.pink,
  ];

  Color _colorSeleccionado = Colors.blue;
  final _nombreController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Gestionar Categorías",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildFormularioCreacion(),
          const Divider(height: 40),
          const Expanded(
            child: Center(child: Text("Listado de Categorías (PostgreSQL)")),
          ),
        ],
      ),
    );
  }

  Widget _buildFormularioCreacion() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        // ✅ Corregido: Envolviendo la Column en Padding
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: "Nombre de la Categoría",
              ),
            ),
            const SizedBox(height: 15),
            const Text("Selecciona un color:"),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _coloresDisponibles
                  .map(
                    (color) => GestureDetector(
                      onTap: () => setState(() => _colorSeleccionado = color),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _colorSeleccionado == color
                                ? Colors.black
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(backgroundColor: color, radius: 15),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Aquí irá la lógica del BLoC para PostgreSQL
              },
              child: const Text("Guardar Categoría"),
            ),
          ],
        ),
      ),
    );
  }
}
