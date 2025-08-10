import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PrecisionScreen extends StatefulWidget {
  const PrecisionScreen({super.key});

  @override
  State<PrecisionScreen> createState() => _PrecisionScreenState();
}

class _PrecisionScreenState extends State<PrecisionScreen> {
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  List<Map<String, dynamic>> _datosTabla = [];
  bool _isLoading = false;
  int _totalVP = 0;
  int _totalFP = 0;

  @override
  void initState() {
    super.initState();
    // Inicializar con fechas por defecto (último mes)
    _fechaFin = DateTime.now();
    _fechaInicio = DateTime.now().subtract(const Duration(days: 30));
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    if (_fechaInicio == null || _fechaFin == null) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final DatabaseReference ref = FirebaseDatabase.instance
          .ref('users/${user.uid}/detected_messages');

      final snapshot = await ref.get();
      
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        _procesarDatos(data);
      }
    } catch (e) {
      print('Error cargando datos: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _procesarDatos(Map<String, dynamic> mensajes) {
    // Filtrar mensajes por rango de fechas
    final mensajesFiltrados = <String, dynamic>{};
    
    mensajes.forEach((key, value) {
      final mensaje = Map<String, dynamic>.from(value);
      final timestamp = mensaje['validated_at'] ?? mensaje['timestamp'];
      
      if (timestamp != null) {
        final fechaMensaje = DateTime.fromMillisecondsSinceEpoch(timestamp);
        if (fechaMensaje.isAfter(_fechaInicio!) && 
            fechaMensaje.isBefore(_fechaFin!.add(const Duration(days: 1)))) {
          mensajesFiltrados[key] = mensaje;
        }
      }
    });

    // Agrupar por fecha y contar VP y FP
    final Map<String, Map<String, int>> datosPorFecha = {};
    
    mensajesFiltrados.forEach((key, mensaje) {
      final timestamp = mensaje['validated_at'] ?? mensaje['timestamp'];
      final fechaMensaje = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final fechaStr = '${fechaMensaje.day.toString().padLeft(2, '0')}/${fechaMensaje.month.toString().padLeft(2, '0')}/${fechaMensaje.year}';
      
      if (!datosPorFecha.containsKey(fechaStr)) {
        datosPorFecha[fechaStr] = {'VP': 0, 'FP': 0};
      }
      
      final validationType = mensaje['validation_type'] ?? '';
      if (validationType == 'VP') {
        datosPorFecha[fechaStr]!['VP'] = datosPorFecha[fechaStr]!['VP']! + 1;
      } else if (validationType == 'FP') {
        datosPorFecha[fechaStr]!['FP'] = datosPorFecha[fechaStr]!['FP']! + 1;
      }
    });

    // Convertir a lista y calcular totales
    _datosTabla.clear();
    _totalVP = 0;
    _totalFP = 0;

    datosPorFecha.forEach((fecha, datos) {
      final vp = datos['VP']!;
      final fp = datos['FP']!;
      final precision = (vp + fp) > 0 ? (vp / (vp + fp)) * 100 : 0.0;
      
      _datosTabla.add({
        'fecha': fecha,
        'vp': vp,
        'fp': fp,
        'precision': precision,
      });
      
      _totalVP += vp;
      _totalFP += fp;
    });

    // Ordenar por fecha (más reciente primero)
    _datosTabla.sort((a, b) {
      final partsA = a['fecha'].split('/');
      final partsB = b['fecha'].split('/');
      final fechaA = DateTime(int.parse(partsA[2]), int.parse(partsA[1]), int.parse(partsA[0]));
      final fechaB = DateTime(int.parse(partsB[2]), int.parse(partsB[1]), int.parse(partsB[0]));
      return fechaB.compareTo(fechaA);
    });

    setState(() {});
  }

  Future<void> _seleccionarFecha(bool esInicio) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: esInicio ? _fechaInicio : _fechaFin,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (fecha != null) {
      setState(() {
        if (esInicio) {
          _fechaInicio = fecha;
        } else {
          _fechaFin = fecha;
        }
      });
      _cargarDatos();
    }
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return 'Seleccionar';
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Reportes', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0D1A2A),
        centerTitle: true,
        leading: Container(),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 24),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Porcentaje de Precisión',
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
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _seleccionarFecha(true),
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
                              Text(_formatearFecha(_fechaInicio), style: const TextStyle(fontSize: 14)),
                              const Spacer(),
                              Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _seleccionarFecha(false),
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
                              Text(_formatearFecha(_fechaFin), style: const TextStyle(fontSize: 14)),
                              const Spacer(),
                              Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                const Text(
                  '*Verdadero Positivo (VP)',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const Text(
                  '*Falso Positivo (FP)',
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
                            Expanded(child: Text('VP', style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(child: Text('FP', style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(child: Text('Precisión', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                        ),
                      ),
                      if (_datosTabla.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          child: const Text(
                            'No hay datos para el rango de fechas seleccionado',
                            style: TextStyle(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        )
                      else
                        ..._datosTabla.map((dato) => _buildTableRow(
                          dato['fecha'], 
                          dato['vp'].toString(), 
                          dato['fp'].toString(), 
                          '${dato['precision'].toStringAsFixed(1)}%'
                        )).toList(),
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
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${(_totalVP > _totalFP ? _totalVP : _totalFP)}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                Text('${((_totalVP > _totalFP ? _totalVP : _totalFP) * 0.75).round()}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                Text('${((_totalVP > _totalFP ? _totalVP : _totalFP) * 0.5).round()}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                Text('${((_totalVP > _totalFP ? _totalVP : _totalFP) * 0.25).round()}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                Text('0', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    width: 40,
                                    height: _totalVP > 0 && (_totalVP + _totalFP) > 0 ? (120 * _totalVP / (_totalVP > _totalFP ? _totalVP : _totalFP)) : 10,
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Container(
                                    width: 40,
                                    height: _totalFP > 0 && (_totalVP + _totalFP) > 0 ? (120 * _totalFP / (_totalVP > _totalFP ? _totalVP : _totalFP)) : 10,
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
                              Text('Verdadero Positivo ($_totalVP)', style: const TextStyle(fontSize: 12)),
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
                              Text('Falso Positivo ($_totalFP)', style: const TextStyle(fontSize: 12)),
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

  Widget _buildTableRow(String fecha, String vp, String fp, String precision) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(fecha, style: const TextStyle(fontSize: 14))),
          Expanded(child: Text(vp, style: const TextStyle(fontSize: 14))),
          Expanded(child: Text(fp, style: const TextStyle(fontSize: 14))),
          Expanded(child: Text(precision, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
