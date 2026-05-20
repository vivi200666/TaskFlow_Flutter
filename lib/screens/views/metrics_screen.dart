import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/auth/auth_cubit.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/workspace/workspace_cubit.dart';
import '../../bloc/workspace/workspace_state.dart';

class MetricsScreen extends StatefulWidget {
  final int workspaceId;
  const MetricsScreen({super.key, required this.workspaceId});

  @override
  State<MetricsScreen> createState() => _MetricsScreenState();
}

class _MetricsScreenState extends State<MetricsScreen> {
  Map<String, dynamic> _metrics = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthSuccess) {
      setState(() {
        _error = 'No autenticado';
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final metrics = await context.read<WorkspaceCubit>().getWorkspaceMetrics(widget.workspaceId, authState.token);
      if (metrics.isEmpty) {
        setState(() {
          _error = 'No se recibieron datos del servidor';
          _loading = false;
        });
      } else {
        setState(() {
          _metrics = metrics;
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Métricas del Workspace'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMetrics,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadMetrics,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(_error!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadMetrics,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildGlobalMetrics(),
                        const SizedBox(height: 24),
                        _buildMemberProgress(),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildGlobalMetrics() {
    final totalTareas = _metrics['total_tareas'] ?? 0;
    final totalCompletadas = _metrics['total_completadas'] ?? 0;
    final progresoGlobal = _metrics['progreso_global'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("📊 Estadísticas generales",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard("Total tareas", totalTareas.toString(), Colors.blue),
              const SizedBox(width: 12),
              _buildStatCard("Tareas completadas", totalCompletadas.toString(), Colors.green),
              const SizedBox(width: 12),
              _buildStatCard("Progreso", "$progresoGlobal%", Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberProgress() {
    final productividad = _metrics['productividad_grupal'] ?? [];
    if (productividad is! List || productividad.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Text("No hay tareas asignadas a miembros"),
      );
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("👥 Progreso por miembro",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...productividad.map<Widget>((member) => _buildMemberRow(member)).toList(),
        ],
      ),
    );
  }

  Widget _buildMemberRow(Map<String, dynamic> member) {
    final username = member['username'] ?? 'Usuario';
    final total = member['total'] ?? 0;
    final completadas = member['completadas'] ?? 0;
    final progreso = member['progreso'] ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(username, style: const TextStyle(fontWeight: FontWeight.w500)),
              const Spacer(),
              Text("$completadas / $total", style: const TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progreso / 100,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation(Colors.purple),
          ),
          const SizedBox(height: 2),
          Text("${progreso.toStringAsFixed(0)}% completado",
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}