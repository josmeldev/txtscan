import 'package:flutter/material.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0D1A2A),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Primera fila de estadísticas
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Porcentaje de\nFalsos\nPositivos',
                      value: '8%',
                      valueColor: Colors.red,
                      backgroundColor: Colors.grey.shade100,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Porcentaje de\nPrecisión',
                      value: '92%',
                      valueColor: Colors.green,
                      backgroundColor: Colors.grey.shade100,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Segunda fila de estadísticas
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Tiempo\nPromedio de\nRespuesta',
                      value: '3s',
                      valueColor: Colors.green,
                      backgroundColor: Colors.grey.shade100,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Tasa de Falsos\nNegativos',
                      value: '7%',
                      valueColor: Colors.red,
                      backgroundColor: Colors.grey.shade100,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color valueColor,
    required Color backgroundColor,
  }) {
    return Container(
      height: 160,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
