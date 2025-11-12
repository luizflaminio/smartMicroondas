// lib/screens/connection_screen.dart
import 'package:flutter/material.dart';
import '../services/microwave_service.dart';
import 'debug_screen.dart';

class ConnectionScreen extends StatefulWidget {
  final VoidCallback onConnected;

  const ConnectionScreen({
    Key? key,
    required this.onConnected,
  }) : super(key: key);

  @override
  _ConnectionScreenState createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  final MicrowaveService _service = MicrowaveService();
  
  bool _isScanning = false;
  bool _isConnecting = false;
  List<dynamic> _devices = [];
  String _statusMessage = 'Desconectado';

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    bool hasPermissions = await _service.requestPermissions();
    if (!hasPermissions) {
      setState(() {
        _statusMessage = 'Permissoes necessarias nao concedidas';
      });
    }
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _devices.clear();
      _statusMessage = 'Procurando dispositivos...';
    });

    try {
      List<dynamic> devices = await _service.scanDevices();
      
      setState(() {
        _devices = devices;
        _isScanning = false;
        if (_devices.isEmpty) {
          _statusMessage = 'Nenhum dispositivo encontrado';
        } else {
          _statusMessage = '${_devices.length} dispositivo(s) encontrado(s)';
        }
      });
      
      // Mostrar lista automaticamente se encontrou dispositivos
      if (_devices.isNotEmpty) {
        _showDeviceListDialog();
      }
    } catch (e) {
      setState(() {
        _isScanning = false;
        _statusMessage = 'Erro ao procurar: $e';
      });
    }
  }

  Future<void> _connectToMicrowave() async {
    setState(() {
      _isConnecting = true;
      _statusMessage = 'Conectando...';
    });

    try {
      bool success = await _service.connectToMicrowave();
      
      if (success) {
        widget.onConnected();
      } else {
        setState(() {
          _isConnecting = false;
          _statusMessage = 'Microondas nao encontrado. Tente buscar manualmente.';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Microondas nao encontrado. Busque manualmente.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _statusMessage = 'Erro: $e';
      });
    }
  }

  Future<void> _connectToDevice(dynamic device) async {
    Navigator.pop(context); // Fechar dialog
    
    setState(() {
      _isConnecting = true;
      _statusMessage = 'Conectando ao dispositivo...';
    });

    try {
      print('Tentando conectar a: ${device.platformName}');
      bool success = await _service.connectToDevice(device);
      
      if (success) {
        print('Conexao bem-sucedida!');
        widget.onConnected();
      } else {
        print('Falha na conexao');
        setState(() {
          _isConnecting = false;
          _statusMessage = 'Falha na conexao';
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Nao foi possivel conectar'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Erro ao conectar: $e');
      setState(() {
        _isConnecting = false;
        _statusMessage = 'Erro: $e';
      });
    }
  }

  void _showDeviceListDialog() {
    if (_devices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nenhum dispositivo encontrado. Faca um scan primeiro.'),
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Text('Selecionar Dispositivo'),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _devices.length,
            itemBuilder: (context, index) {
              dynamic device = _devices[index];
              String deviceName = device.platformName.isEmpty
                  ? 'Dispositivo Desconhecido'
                  : device.platformName;

              return ListTile(
                leading: Icon(Icons.bluetooth, color: Colors.blue),
                title: Text(deviceName),
                subtitle: Text(device.remoteId.toString()),
                onTap: () => _connectToDevice(device),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startScan();
            },
            child: Text('Procurar Novamente'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Conectar Microondas'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildBluetoothIcon(),
              SizedBox(height: 32),
              Text(
                'Microondas Desconectado',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              SizedBox(height: 16),
              Text(
                _statusMessage,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Procurando: Smart_Microondas_ESP32',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
              SizedBox(height: 48),
              _buildConnectButton(),
              SizedBox(height: 16),
              TextButton.icon(
                onPressed: (_isScanning || _isConnecting) ? null : _startScan,
                icon: Icon(Icons.search),
                label: Text('Procurar Dispositivos'),
              ),
              if (_devices.isNotEmpty) ...[
                SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _showDeviceListDialog,
                  icon: Icon(Icons.list),
                  label: Text('Ver ${_devices.length} Dispositivo(s)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBluetoothIcon() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        shape: BoxShape.circle,
      ),
      child: Icon(
        _isConnecting || _isScanning
            ? Icons.bluetooth_searching
            : Icons.bluetooth_disabled,
        size: 60,
        color: Colors.grey[600],
      ),
    );
  }

  Widget _buildConnectButton() {
    return ElevatedButton.icon(
      onPressed: (_isConnecting || _isScanning) ? null : _connectToMicrowave,
      icon: (_isConnecting || _isScanning)
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Icon(Icons.bluetooth_searching),
      label: Text(_isConnecting
          ? 'Conectando...'
          : _isScanning
              ? 'Procurando...'
              : 'Conectar Automatico'),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        textStyle: TextStyle(fontSize: 16),
        minimumSize: Size(200, 56),
      ),
    );
  }
}