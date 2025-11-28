// lib/services/bluetooth_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/recipe.dart';
import '../utils/constants.dart';

class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal();

  // Constantes para cálculo de potência
  static const int MAX_POWER = 1000; // Watts máximo
  static const double TEMP_MIN = 20.0; // °C temperatura mínima
  static const double TEMP_MAX = 50.0; // °C temperatura máxima
  static const double RELAY_TOLERANCE = 0.02; // 2% de tolerância

  // BLE
  BluetoothDevice? _device;
  BluetoothCharacteristic? _rxCharacteristic;
  BluetoothCharacteristic? _txCharacteristic;

  // State
  bool _isConnected = false;
  bool _isRunning = false;
  bool _isDoorOpen = false;
  double _currentTemperature = 20.0;
  int _calculatedPower = 0;
  Recipe? _currentRecipe;
  int _remainingTime = 0;
  bool _relayState = false;

  // Stream controllers
  final StreamController<bool> _connectionController = StreamController.broadcast();
  final StreamController<bool> _runningController = StreamController.broadcast();
  final StreamController<bool> _doorController = StreamController.broadcast();
  final StreamController<double> _temperatureController = StreamController.broadcast();
  final StreamController<int> _powerController = StreamController.broadcast();
  final StreamController<int> _timeController = StreamController.broadcast();
  final StreamController<String> _messageController = StreamController.broadcast();

  // Getters for streams
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<bool> get runningStream => _runningController.stream;
  Stream<bool> get doorStream => _doorController.stream;
  Stream<double> get temperatureStream => _temperatureController.stream;
  Stream<int> get powerStream => _powerController.stream;
  Stream<int> get timeStream => _timeController.stream;
  Stream<String> get messageStream => _messageController.stream;

  // Getters for current state
  bool get isConnected => _isConnected;
  bool get isRunning => _isRunning;
  bool get isDoorOpen => _isDoorOpen;
  double get currentTemperature => _currentTemperature;
  int get calculatedPower => _calculatedPower;
  Recipe? get currentRecipe => _currentRecipe;
  int get remainingTime => _remainingTime;
  BluetoothDevice? get connectedDevice => _device;

  // ============================================================
  // CÁLCULO DE POTÊNCIA BASEADO NA TEMPERATURA
  // ============================================================

  /// Calcula potência em Watts baseado na temperatura atual
  /// Usa uma curva quadrática para simular comportamento de microondas real
  int _calculatePowerFromTemperature(double temperature) {
    // Garante que temperatura está dentro dos limites
    if (temperature <= TEMP_MIN) return 0;
    if (temperature >= TEMP_MAX) return MAX_POWER;

    // Normaliza temperatura para 0-1
    double normalizedTemp = (temperature - TEMP_MIN) / (TEMP_MAX - TEMP_MIN);

    // Aplica curva quadrática (simula aquecimento não-linear do microondas)
    double powerFactor = normalizedTemp * normalizedTemp;

    return (powerFactor * MAX_POWER).round();
  }

  /// Determina se o relé deve estar ligado baseado na potência calculada vs alvo
  bool _shouldRelayBeOn(int calculatedPower, int targetPower) {
    if (targetPower == 0) return false;

    double lowerLimit = targetPower * (1 - RELAY_TOLERANCE); // -2%
    double upperLimit = targetPower * (1 + RELAY_TOLERANCE); // +2%

    // Relé LIGA se potência está ABAIXO do alvo (precisa aquecer mais)
    // Relé DESLIGA se potência está DENTRO ou ACIMA do alvo
    return calculatedPower < lowerLimit;
  }

  /// Converte porcentagem (0-100) da receita para Watts (0-1000)
  int _convertPercentToPower(int percent) {
    return (percent * 10).clamp(0, 1000);
  }

  /// Processa temperatura recebida e controla o relé
  Future<void> _processTemperature(double temperature) async {
    // Atualiza temperatura
    if (_currentTemperature != temperature) {
      _currentTemperature = temperature;
      _temperatureController.add(_currentTemperature);
    }

    // Calcula potência baseada na temperatura
    int newCalculatedPower = _calculatePowerFromTemperature(temperature);

    if (_calculatedPower != newCalculatedPower) {
      _calculatedPower = newCalculatedPower;
      _powerController.add(_calculatedPower);
    }

    // Se está rodando, controla o relé
    if (_isRunning && _currentRecipe != null) {
      int targetPower = _convertPercentToPower(_currentRecipe!.power);
      bool shouldBeOn = _shouldRelayBeOn(_calculatedPower, targetPower);

      // Só envia comando se o estado mudou
      if (shouldBeOn != _relayState) {
        _relayState = shouldBeOn;
        await _sendCommand(shouldBeOn ? 'RELAY:ON' : 'RELAY:OFF');

        print('🌡️  Temp: ${temperature.toStringAsFixed(1)}°C | '
              '⚡ Potência: $_calculatedPower W | '
              '🎯 Alvo: $targetPower W | '
              '🔌 Relé: ${shouldBeOn ? "LIGADO" : "DESLIGADO"}');
      }
    }
  }

  // ============================================================
  // BLUETOOTH PERMISSIONS & SETUP
  // ============================================================

  // Request permissions
  Future<bool> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  // Check if Bluetooth is enabled
  Future<bool> isBluetoothEnabled() async {
    return await FlutterBluePlus.isOn;
  }

  // Scan for devices
  Future<List<BluetoothDevice>> scanDevices({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    List<BluetoothDevice> devices = [];

    // Garantir que o Bluetooth está ligado antes do scan
    if (!(await FlutterBluePlus.isOn)) {
      print('⚠️ Bluetooth está desligado');
      return devices;
    }

    // Escuta os resultados do scan antes de iniciar
    final subscription = FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (!devices.any((d) => d.id == r.device.id)) {
          devices.add(r.device);
        }
      }
    });

    print('🔍 Iniciando busca BLE por ${timeout.inSeconds}s...');
    await FlutterBluePlus.startScan(timeout: timeout);

    // Espera o tempo de scan
    await Future.delayed(timeout);

    await FlutterBluePlus.stopScan();
    await subscription.cancel();

    print('📡 Scan finalizado, ${devices.length} dispositivo(s) encontrado(s).');
    return devices;
  }

  // Connect to specific device
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      print('🔗 Connecting to ${device.platformName}...');

      await device.connect(timeout: BLEConstants.connectionTimeout);
      _device = device;

      // Discover services
      List<dynamic> services = await device.discoverServices();

      for (var service in services) {
        String serviceUuid = service.uuid.toString().toLowerCase();

        if (serviceUuid.contains('00ff')) {
          print('✅ Found Microwave Service');

          for (var char in service.characteristics) {
            String charUuid = char.uuid.toString().toLowerCase();

            if (charUuid.contains('ff01')) {
              _rxCharacteristic = char;
              print('✅ RX Characteristic found');
            } else if (charUuid.contains('ff02')) {
              _txCharacteristic = char;

              await char.setNotifyValue(true);

              char.lastValueStream.listen((value) {
                if (value.isNotEmpty) {
                  String message = utf8.decode(value);
                  _handleReceivedMessage(message);
                }
              });

              print('✅ TX Characteristic found and subscribed');
            }
          }
        }
      }

      if (_rxCharacteristic == null || _txCharacteristic == null) {
        throw Exception('Characteristics not found');
      }

      _isConnected = true;
      _connectionController.add(_isConnected);

      print('✅ Connected successfully!');

      await Future.delayed(Duration(milliseconds: 500));
      _sendCommand(Commands.ping);

      return true;
    } catch (e) {
      print('❌ Connection error: $e');
      _isConnected = false;
      _connectionController.add(_isConnected);
      return false;
    }
  }

  // Auto-connect to microwave
  Future<bool> connectToMicrowave() async {
    bool hasPermissions = await requestPermissions();
    if (!hasPermissions) {
      _messageController.add('Permissions denied');
      return false;
    }

    bool isEnabled = await isBluetoothEnabled();
    if (!isEnabled) {
      _messageController.add('Bluetooth is disabled');
      return false;
    }

    print('🔍 Scanning for microwave...');
    List<BluetoothDevice> devices = await scanDevices();

    BluetoothDevice? microwave;
    for (var device in devices) {
      if (device.platformName.contains('Smart_Microondas') ||
          device.platformName.contains(BLEConstants.deviceName)) {
        microwave = device;
        break;
      }
    }

    if (microwave == null) {
      _messageController.add('Microwave not found');
      return false;
    }

    return await connectToDevice(microwave);
  }

  // Disconnect
  Future<void> disconnect() async {
    if (_device != null) {
      await _device!.disconnect();
    }

    _device = null;
    _rxCharacteristic = null;
    _txCharacteristic = null;
    _isConnected = false;
    _relayState = false;
    _connectionController.add(_isConnected);

    if (_isRunning) {
      _isRunning = false;
      _runningController.add(_isRunning);
    }

    print('🔌 Disconnected');
  }

  // Send command
  Future<void> _sendCommand(String command) async {
    if (_rxCharacteristic == null) {
      print('❌ Not connected');
      return;
    }

    try {
      await _rxCharacteristic!.write(utf8.encode(command));
      print('📤 Sent: $command');
    } catch (e) {
      print('❌ Error sending command: $e');
    }
  }

  // Handle received messages
  void _handleReceivedMessage(String message) {
    print('📥 Received: $message');

    if (message == 'PONG') {
      _messageController.add('Connection OK');
    }
    else if (message == 'CONNECTED') {
      _messageController.add('Connected to microwave');
    }
    else if (message.startsWith('TEMP:')) {
      // Processa temperatura recebida
      String tempStr = message.substring(5).trim();
      if (tempStr != 'ERROR') {
        try {
          double temp = double.parse(tempStr);
          _processTemperature(temp);
        } catch (e) {
          print('❌ Error parsing temperature: $e');
        }
      } else {
        print('⚠️  Sensor error');
      }
    }
    else if (message.startsWith('STATUS:')) {
      _parseStatus(message);
    }
    else if (message.startsWith('OK:')) {
      _messageController.add('Command acknowledged');
    }
    else if (message == 'FINISHED') {
      _isRunning = false;
      _relayState = false;
      _runningController.add(_isRunning);
      _messageController.add('Cooking finished');
    }
  }

  // Parse status
  void _parseStatus(String status) {
    List<String> parts = status.split(':');

    // STATUS format: STATUS:isRunning:temp:time:recipe:power:doorOpen
    if (parts.length >= 6) {
      bool running = parts[1] == '1';
      int time = int.tryParse(parts[3]) ?? 0;

      // Parse door state if available (parts[6])
      bool doorOpen = false;
      if (parts.length >= 7) {
        doorOpen = parts[6] == '1';
      }

      if (_isRunning != running) {
        _isRunning = running;
        _runningController.add(_isRunning);

        // Se parou de rodar, desliga relé
        if (!running && _relayState) {
          _relayState = false;
          _sendCommand('RELAY:OFF');
        }
      }

      if (_remainingTime != time) {
        _remainingTime = time;
        _timeController.add(_remainingTime);
      }

      if (_isDoorOpen != doorOpen) {
        _isDoorOpen = doorOpen;
        _doorController.add(_isDoorOpen);
        print('🚪 Door ${doorOpen ? "OPEN" : "CLOSED"}');
      }
    }
  }

  // Start recipe
  Future<void> startRecipe(Recipe recipe) async {
    if (!_isConnected || _isRunning) return;

    _currentRecipe = recipe;
    _remainingTime = recipe.timeInSeconds;

    String command = Commands.start(recipe.name, recipe.timeInSeconds, recipe.power);
    await _sendCommand(command);

    print('🍽️ Starting recipe: ${recipe.name}');
  }

  // Stop microwave
  Future<void> stopMicrowave() async {
    if (!_isConnected) return;

    // Desliga o relé antes de parar
    if (_relayState) {
      await _sendCommand('RELAY:OFF');
      _relayState = false;
    }

    await _sendCommand(Commands.stop);
    print('⏹️ Stopping microwave');
  }

  // Request status
  Future<void> requestStatus() async {
    if (!_isConnected) return;
    await _sendCommand(Commands.status);
  }

  // Dispose
  void dispose() {
    _device?.disconnect();
    _connectionController.close();
    _runningController.close();
    _doorController.close();
    _temperatureController.close();
    _powerController.close();
    _timeController.close();
    _messageController.close();
  }
}
