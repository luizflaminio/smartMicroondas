// lib/models/microwave_state.dart
import 'recipe.dart';

enum MicrowaveStatus {
  disconnected,
  connecting,
  connected,
  running,
  paused,
  finished,
}

class MicrowaveState {
  final MicrowaveStatus status;
  final bool isConnected;
  final bool isRunning;
  final int currentTemperature;
  final int remainingTime;
  final Recipe? currentRecipe;
  final String? errorMessage;
  final DateTime? lastUpdate;

  MicrowaveState({
    this.status = MicrowaveStatus.disconnected,
    this.isConnected = false,
    this.isRunning = false,
    this.currentTemperature = 25,
    this.remainingTime = 0,
    this.currentRecipe,
    this.errorMessage,
    this.lastUpdate,
  });

  factory MicrowaveState.initial() {
    return MicrowaveState(
      status: MicrowaveStatus.disconnected,
      lastUpdate: DateTime.now(),
    );
  }

  factory MicrowaveState.connected() {
    return MicrowaveState(
      status: MicrowaveStatus.connected,
      isConnected: true,
      lastUpdate: DateTime.now(),
    );
  }

  factory MicrowaveState.running({
    required Recipe recipe,
    required int remainingTime,
    required int temperature,
  }) {
    return MicrowaveState(
      status: MicrowaveStatus.running,
      isConnected: true,
      isRunning: true,
      currentRecipe: recipe,
      remainingTime: remainingTime,
      currentTemperature: temperature,
      lastUpdate: DateTime.now(),
    );
  }

  factory MicrowaveState.error(String message) {
    return MicrowaveState(
      status: MicrowaveStatus.disconnected,
      errorMessage: message,
      lastUpdate: DateTime.now(),
    );
  }

  MicrowaveState copyWith({
    MicrowaveStatus? status,
    bool? isConnected,
    bool? isRunning,
    int? currentTemperature,
    int? remainingTime,
    Recipe? currentRecipe,
    String? errorMessage,
    DateTime? lastUpdate,
  }) {
    return MicrowaveState(
      status: status ?? this.status,
      isConnected: isConnected ?? this.isConnected,
      isRunning: isRunning ?? this.isRunning,
      currentTemperature: currentTemperature ?? this.currentTemperature,
      remainingTime: remainingTime ?? this.remainingTime,
      currentRecipe: currentRecipe ?? this.currentRecipe,
      errorMessage: errorMessage ?? this.errorMessage,
      lastUpdate: lastUpdate ?? DateTime.now(),
    );
  }

  bool get canStart => isConnected && !isRunning;
  bool get canStop => isConnected && isRunning;
  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
  
  String get statusText {
    switch (status) {
      case MicrowaveStatus.disconnected:
        return 'Desconectado';
      case MicrowaveStatus.connecting:
        return 'Conectando...';
      case MicrowaveStatus.connected:
        return 'Conectado';
      case MicrowaveStatus.running:
        return 'Em funcionamento';
      case MicrowaveStatus.paused:
        return 'Pausado';
      case MicrowaveStatus.finished:
        return 'Finalizado';
    }
  }

  @override
  String toString() {
    return 'MicrowaveState(status: $status, connected: $isConnected, running: $isRunning, temp: $currentTemperature°C, time: $remainingTime)';
  }
}