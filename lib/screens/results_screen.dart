import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

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

  Widget _buildMessageCard(Map<String, dynamic> message) {
    final DateTime timestamp = DateTime.fromMillisecondsSinceEpoch(message['timestamp']);
    final bool isAnalyzed = message['isAnalyzed'] ?? false;
    final bool isMalicious = message['isMalicious'] ?? false;

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
                  isAnalyzed 
                    ? (isMalicious ? Icons.warning : Icons.check_circle)
                    : Icons.hourglass_empty,
                  color: isAnalyzed 
                    ? (isMalicious ? Colors.red : Colors.green)
                    : Colors.orange,
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isAnalyzed 
                      ? (isMalicious ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1))
                      : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isAnalyzed 
                        ? (isMalicious ? Colors.red : Colors.green)
                        : Colors.orange,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    isAnalyzed 
                      ? (isMalicious ? 'SMISHING' : 'SEGURO')
                      : 'ANALIZANDO...',
                    style: TextStyle(
                      color: isAnalyzed 
                        ? (isMalicious ? Colors.red : Colors.green)
                        : Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            // Mostrar información de error si existe
            if (message['error'] != null && message['error'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Error API: ${message['error']}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
