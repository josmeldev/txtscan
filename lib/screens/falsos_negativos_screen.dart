import 'package:flutter/material.dart';

class FalsosNegativosScreen extends StatelessWidget {
  const FalsosNegativosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Reportes', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0D1A2A),
        centerTitle: true,
        leading: Container(), // Quitar el botón de back automático
        actions: [
          // Botón de cerrar en la esquina superior derecha
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 24),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título principal
            const Text(
              'Tasa de Falsos Negativos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            // Filtros de fecha
            Row(
              children: [
                // Fecha Inicio
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        const Text('Fecha Inicio', style: TextStyle(fontSize: 14)),
                        const Spacer(),
                        Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Fecha Fin
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        const Text('Fecha Fin', style: TextStyle(fontSize: 14)),
                        const Spacer(),
                        Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Descripción de los datos
            const Text(
              '*Verdadero Positivo (VP)',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const Text(
              '*Falso Negativo(FN)',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            
            // Tabla de datos
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  // Header de la tabla
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Expanded(flex: 2, child: Text('Fecha', style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(child: Text('FN', style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(child: Text('VP', style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(child: Text('Tasa de FN', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                  // Filas de datos
                  _buildTableRow('24/04/2025', 'x', 'y', '8 %'),
                  _buildTableRow('23/04/2025', 'x', 'y', '9%'),
                  _buildTableRow('22/04/2025', 'x', 'y', '7%'),
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            // Gráfico de barras
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  // Eje Y (números)
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Etiquetas del eje Y
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('4', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            Text('3', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            Text('2', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            Text('1', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            Text('0', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          ],
                        ),
                        const SizedBox(width: 8),
                        // Barras del gráfico
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Barra azul (Falso Positivo)
                              Container(
                                width: 40,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 20),
                              // Barra naranja (Verdadero negativo)
                              Container(
                                width: 40,
                                height: 130,
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Leyenda
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text('Falso Positivo', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text('Verdadero negativo', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableRow(String fecha, String fn, String vp, String tasaFN) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(fecha, style: const TextStyle(fontSize: 14))),
          Expanded(child: Text(fn, style: const TextStyle(fontSize: 14))),
          Expanded(child: Text(vp, style: const TextStyle(fontSize: 14))),
          Expanded(child: Text(tasaFN, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
