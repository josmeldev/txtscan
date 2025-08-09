import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/validation_service.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snapshot = await _database
            .child('users')
            .child(user.uid)
            .child('detected_messages')
            .get();

        if (snapshot.exists) {
          final data = Map<String, dynamic>.from(snapshot.value as Map);
          final messages = <Map<String, dynamic>>[];
          
          data.forEach((key, value) {
            final message = Map<String, dynamic>.from(value as Map);
            message['id'] = key;
            messages.add(message);
          });

          // Ordenar por timestamp (más recientes primero)
          messages.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

          if (mounted) {
            setState(() {
              _messages = messages;
              _isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      print('Error al cargar mensajes: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshMessages() async {
    setState(() {
      _isLoading = true;
    });
    await _loadMessages();
  }

  Future<void> _deleteMessage(String messageId) async {
    try {
      // Mostrar diálogo de confirmación
      final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Confirmar eliminación'),
            content: const Text('¿Estás seguro de que quieres eliminar este mensaje?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Eliminar'),
              ),
            ],
          );
        },
      );

      if (shouldDelete == true) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Eliminar de Firebase
          await _database
              .child('users')
              .child(user.uid)
              .child('detected_messages')
              .child(messageId)
              .remove();

          // Actualizar la lista localmente
          setState(() {
            _messages.removeWhere((message) => message['id'] == messageId);
          });

          // Mostrar mensaje de confirmación
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Mensaje eliminado correctamente'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error al eliminar mensaje: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al eliminar el mensaje'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildMessageCard(Map<String, dynamic> message) {
    final DateTime timestamp = DateTime.fromMillisecondsSinceEpoch(message['timestamp']);
    final bool isMalicious = message['es_smishing'] ?? false;
    final String? validationType = message['validation_type'];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isMalicious ? Icons.warning : Icons.check_circle,
                  color: isMalicious ? Colors.red : Colors.green,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message['title'] ?? 'Sin título',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Menú de 3 puntos
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: Colors.grey,
                    size: 20,
                  ),
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deleteMessage(message['id']);
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 18),
                          SizedBox(width: 8),
                          Text('Eliminar'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              message['body'] ?? 'Sin contenido',
              style: const TextStyle(fontSize: 14),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Estado de detección
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isMalicious ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isMalicious ? Colors.red : Colors.green,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    isMalicious ? 'SMISHING' : 'SEGURO',
                    style: TextStyle(
                      color: isMalicious ? Colors.red : Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Espaciado entre los dos badges
                if (validationType != null) const SizedBox(width: 8),
                // Estado de validación al lado del estado de detección
                if (validationType != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: ValidationService.getValidationColor(validationType).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ValidationService.getValidationColor(validationType),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      ValidationService.getValidationDescription(validationType),
                      style: TextStyle(
                        color: ValidationService.getValidationColor(validationType),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Fecha y hora alineada a la derecha
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0D1A2A),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshMessages,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.message_outlined,
                        size: 100,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'No hay mensajes detectados',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Inicia la detección para ver los resultados aquí',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refreshMessages,
                  child: ListView.builder(
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageCard(_messages[index]);
                    },
                  ),
                ),
    );
  }
}
