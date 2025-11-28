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
  final bool isDoorOpen; // Nova propriedade - estado da porta
  final double currentTemperature; // Mudado para double
  final int calculatedPower; // Nova propriedade - potência calculada em Watts
  final int remainingTime;
  final Recipe? currentRecipe;
  final String? errorMessage;
  final DateTime? lastUpdate;

  MicrowaveState({
    this.status = MicrowaveStatus.disconnected,
    this.isConnected = false,
    this.isRunning = false,
    this.isDoorOpen = false, // Porta fechada por padrão
    this.currentTemperature = 20.0, // Temperatura ambiente padrão
    this.calculatedPower = 0, // Potência inicial zero
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
    required double temperature,
    required int calculatedPower,
    bool isDoorOpen = false,
  }) {
    return MicrowaveState(
      status: MicrowaveStatus.running,
      isConnected: true,
      isRunning: true,
      isDoorOpen: isDoorOpen,
      currentRecipe: recipe,
      remainingTime: remainingTime,
      currentTemperature: temperature,
      calculatedPower: calculatedPower,
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
    bool? isDoorOpen,
    double? currentTemperature,
    int? calculatedPower,
    int? remainingTime,
    Recipe? currentRecipe,
    String? errorMessage,
    DateTime? lastUpdate,
  }) {
    return MicrowaveState(
      status: status ?? this.status,
      isConnected: isConnected ?? this.isConnected,
      isRunning: isRunning ?? this.isRunning,
      isDoorOpen: isDoorOpen ?? this.isDoorOpen,
      currentTemperature: currentTemperature ?? this.currentTemperature,
      calculatedPower: calculatedPower ?? this.calculatedPower,
      remainingTime: remainingTime ?? this.remainingTime,
      currentRecipe: currentRecipe ?? this.currentRecipe,
      errorMessage: errorMessage ?? this.errorMessage,
      lastUpdate: lastUpdate ?? DateTime.now(),
    );
  }

  bool get canStart => isConnected && !isRunning && !isDoorOpen;
  bool get canStop => isConnected && isRunning;
  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;

  // Verifica se a potência está dentro da faixa alvo ±2%
  bool get isPowerInRange {
    if (currentRecipe == null) return true;
    int targetPower = _convertPercentToPower(currentRecipe!.power);
    if (targetPower == 0) return true;

    double tolerance = 0.02; // 2%
    double lowerLimit = targetPower * (1 - tolerance);
    double upperLimit = targetPower * (1 + tolerance);

    return calculatedPower >= lowerLimit && calculatedPower <= upperLimit;
  }

  // Converte porcentagem (0-100) para Watts (0-1000)
  int _convertPercentToPower(int percent) {
    return (percent * 10).clamp(0, 1000);
  }

  // Potência alvo em Watts
  int get targetPower {
    if (currentRecipe == null) return 0;
    return _convertPercentToPower(currentRecipe!.power);
  }

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
    return 'MicrowaveState(status: $status, connected: $isConnected, running: $isRunning, doorOpen: $isDoorOpen, temp: ${currentTemperature.toStringAsFixed(1)}°C, power: ${calculatedPower}W, time: $remainingTime)';
  }
}
