// lib/screens/debug_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DebugLogger {
  static final DebugLogger _instance = DebugLogger._internal();
  factory DebugLogger() => _instance;
  DebugLogger._internal();

  final List<String> _logs = [];
  final int _maxLogs = 100;

  void log(String message) {
    String timestamp = DateTime.now().toString().substring(11, 19);
    String logMessage = '[$timestamp] $message';
    print(logMessage); // Ainda imprime no console
    
    _logs.insert(0, logMessage);
    if (_logs.length > _maxLogs) {
      _logs.removeLast();
    }
  }

  List<String> getLogs() => List.from(_logs);
  
  void clear() => _logs.clear();
}

class DebugScreen extends StatefulWidget {
  @override
  _DebugScreenState createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final DebugLogger _logger = DebugLogger();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Debug Logs'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              setState(() {
                _logger.clear();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Logs limpos')),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
            },
          ),
        ],
      ),
      body: _logger.getLogs().isEmpty
          ? Center(
              child: Text(
                'Nenhum log ainda\nFaca alguma acao no app',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(8),
              itemCount: _logger.getLogs().length,
              itemBuilder: (context, index) {
                String log = _logger.getLogs()[index];
                Color backgroundColor = Colors.grey[100]!;
                
                if (log.contains('Erro') || log.contains('Falha')) {
                  backgroundColor = Colors.red[50]!;
                } else if (log.contains('Sucesso') || log.contains('Conectado')) {
                  backgroundColor = Colors.green[50]!;
                } else if (log.contains('Procurando') || log.contains('Tentando')) {
                  backgroundColor = Colors.blue[50]!;
                }
                
                return Container(
                  margin: EdgeInsets.only(bottom: 4),
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: GestureDetector(
                    onLongPress: () {
                      Clipboard.setData(ClipboardData(text: log));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Log copiado')),
                      );
                    },
                    child: Text(
                      log,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {});
        },
        child: Icon(Icons.refresh),
        tooltip: 'Atualizar logs',
      ),
    );
  }
}