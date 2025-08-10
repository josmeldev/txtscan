import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'falsos_positivos_screen.dart';
import 'precision_screen.dart';
import 'tiempo_promedio_screen.dart';
import 'falsos_negativos_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isLoading = true;
  int _totalMessages = 0;
  int _falsosPositivos = 0;
  int _verdaderosPositivos = 0;
  int _falsosNegativos = 0;
  int _verdaderosNegativos = 0;
  double _averageTime = 0.0;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final snapshot = await _database
          .child('users')
          .child(user.uid)
          .child('detected_messages')
          .once();

      if (snapshot.snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
        
        int fp = 0, vp = 0, fn = 0, vn = 0;
        double totalTime = 0.0;
        int messagesWithTime = 0;

        data.forEach((key, value) {
          final message = Map<String, dynamic>.from(value);
          final validationType = message['validation_type'] as String?;
          
          if (validationType != null) {
            switch (validationType) {
              case 'FP':
                fp++;
                break;
              case 'VP':
                vp++;
                break;
              case 'FN':
                fn++;
                break;
              case 'VN':
                vn++;
                break;
            }
          }

          if (message['tiempo_deteccion'] != null) {
            totalTime += (message['tiempo_deteccion'] as num).toDouble();
            messagesWithTime++;
          }
        });

        setState(() {
          _totalMessages = data.length;
          _falsosPositivos = fp;
          _verdaderosPositivos = vp;
          _falsosNegativos = fn;
          _verdaderosNegativos = vn;
          _averageTime = messagesWithTime > 0 ? totalTime / messagesWithTime : 0.0;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading statistics: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  double _calculateFalsosPositivosRate() {
    final total = _falsosPositivos + _verdaderosNegativos;
    return total > 0 ? (_falsosPositivos / total) * 100 : 0.0;
  }

  double _calculatePrecision() {
    final total = _verdaderosPositivos + _falsosPositivos;
    return total > 0 ? (_verdaderosPositivos / total) * 100 : 0.0;
  }

  double _calculateFalsosNegativosRate() {
    final total = _falsosNegativos + _verdaderosPositivos;
    return total > 0 ? (_falsosNegativos / total) * 100 : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0D1A2A),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reportes Generales',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        _buildStatCard(
                          'Porcentaje de Falsos Positivos',
                          '${_calculateFalsosPositivosRate().toStringAsFixed(1)}%',
                          Icons.error_outline,
                          Colors.red,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const FalsosPositivosScreen(),
                              ),
                            );
                          },
                        ),
                        _buildStatCard(
                          'Porcentaje de Precisión',
                          '${_calculatePrecision().toStringAsFixed(1)}%',
                          Icons.check_circle_outline,
                          Colors.green,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PrecisionScreen(),
                              ),
                            );
                          },
                        ),
                        _buildStatCard(
                          'Tiempo Promedio de Respuesta',
                          '${_averageTime.toStringAsFixed(1)}s',
                          Icons.timer,
                          Colors.blue,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TiempoPromedioScreen(),
                              ),
                            );
                          },
                        ),
                        _buildStatCard(
                          'Tasa de Falsos Negativos',
                          '${_calculateFalsosNegativosRate().toStringAsFixed(1)}%',
                          Icons.cancel_outlined,
                          Colors.orange,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const FalsosNegativosScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              '$_totalMessages',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const Text('Total Mensajes'),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              '$_verdaderosPositivos',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const Text('VP'),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              '$_falsosPositivos',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            const Text('FP'),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              '$_falsosNegativos',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                            const Text('FN'),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              '$_verdaderosNegativos',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const Text('VN'),
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

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: color,
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
