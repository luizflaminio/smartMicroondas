// lib/services/microwave_service.dart
import 'dart:async';
import '../models/recipe.dart';
import '../models/microwave_state.dart';
import 'bluetooth_service.dart';

class MicrowaveService {
  static final MicrowaveService _instance = MicrowaveService._internal();
  factory MicrowaveService() => _instance;
  MicrowaveService._internal() {
    _initializeListeners();
  }

  final BluetoothService _bluetooth = BluetoothService();

  // State stream
  final StreamController<MicrowaveState> _stateController =
      StreamController<MicrowaveState>.broadcast();

  Stream<MicrowaveState> get stateStream => _stateController.stream;

  MicrowaveState _currentState = MicrowaveState.initial();
  MicrowaveState get currentState => _currentState;

  void _initializeListeners() {
    // Listen to connection changes
    _bluetooth.connectionStream.listen((isConnected) {
      if (isConnected) {
        _updateState(_currentState.copyWith(
          status: MicrowaveStatus.connected,
          isConnected: true,
        ));
      } else {
        _updateState(MicrowaveState.initial());
      }
    });

    // Listen to running status
    _bluetooth.runningStream.listen((isRunning) {
      _updateState(_currentState.copyWith(
        isRunning: isRunning,
        status: isRunning ? MicrowaveStatus.running : MicrowaveStatus.connected,
      ));
    });

    // Listen to door state changes
    _bluetooth.doorStream.listen((isDoorOpen) {
      _updateState(_currentState.copyWith(
        isDoorOpen: isDoorOpen,
      ));
    });

    // Listen to temperature changes
    _bluetooth.temperatureStream.listen((temperature) {
      _updateState(_currentState.copyWith(
        currentTemperature: temperature,
      ));
    });

    // Listen to calculated power changes
    _bluetooth.powerStream.listen((power) {
      _updateState(_currentState.copyWith(
        calculatedPower: power,
      ));
    });

    // Listen to time changes
    _bluetooth.timeStream.listen((time) {
      _updateState(_currentState.copyWith(
        remainingTime: time,
      ));

      // Check if finished
      if (_currentState.isRunning && time == 0) {
        _updateState(_currentState.copyWith(
          status: MicrowaveStatus.finished,
          isRunning: false,
        ));
      }
    });

    // Listen to messages
    _bluetooth.messageStream.listen((message) {
      print('Service message: $message');
    });
  }

  void _updateState(MicrowaveState newState) {
    _currentState = newState;
    _stateController.add(_currentState);
  }

  // Public methods
  Future<bool> requestPermissions() async {
    return await _bluetooth.requestPermissions();
  }

  Future<bool> isBluetoothEnabled() async {
    return await _bluetooth.isBluetoothEnabled();
  }

  Future<List<dynamic>> scanDevices() async {
    _updateState(_currentState.copyWith(
      status: MicrowaveStatus.connecting,
    ));

    return await _bluetooth.scanDevices();
  }

  Future<bool> connectToMicrowave() async {
    _updateState(_currentState.copyWith(
      status: MicrowaveStatus.connecting,
    ));

    bool success = await _bluetooth.connectToMicrowave();

    if (!success) {
      _updateState(MicrowaveState.error('Failed to connect'));
    }

    return success;
  }

  Future<bool> connectToDevice(dynamic device) async {
    _updateState(_currentState.copyWith(
      status: MicrowaveStatus.connecting,
    ));

    bool success = await _bluetooth.connectToDevice(device);

    if (!success) {
      _updateState(MicrowaveState.error('Failed to connect'));
    }

    return success;
  }

  Future<void> disconnect() async {
    await _bluetooth.disconnect();
    _updateState(MicrowaveState.initial());
  }

  Future<void> startRecipe(Recipe recipe) async {
    if (!_currentState.canStart) {
      print('Cannot start - not connected or already running');
      return;
    }

    _updateState(_currentState.copyWith(
      status: MicrowaveStatus.running,
      isRunning: true,
      currentRecipe: recipe,
      remainingTime: recipe.timeInSeconds,
    ));

    await _bluetooth.startRecipe(recipe);
  }

  Future<void> stopMicrowave() async {
    if (!_currentState.canStop) {
      print('Cannot stop - not running');
      return;
    }

    await _bluetooth.stopMicrowave();

    _updateState(_currentState.copyWith(
      status: MicrowaveStatus.connected,
      isRunning: false,
      remainingTime: 0,
    ));
  }

  Future<void> requestStatus() async {
    await _bluetooth.requestStatus();
  }

  // Getters delegating to bluetooth service
  bool get isConnected => _bluetooth.isConnected;
  bool get isRunning => _bluetooth.isRunning;
  bool get isDoorOpen => _bluetooth.isDoorOpen;
  double get currentTemperature => _bluetooth.currentTemperature;
  int get calculatedPower => _bluetooth.calculatedPower;
  Recipe? get currentRecipe => _bluetooth.currentRecipe;
  int get remainingTime => _bluetooth.remainingTime;
  dynamic get connectedDevice => _bluetooth.connectedDevice;

  void dispose() {
    _bluetooth.dispose();
    _stateController.close();
  }
}
