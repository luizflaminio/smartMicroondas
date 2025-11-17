// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import '../models/microwave_state.dart';
import '../models/recipe.dart';
import '../services/microwave_service.dart';
import '../widgets/status_card.dart';
import '../widgets/timer_widget.dart';
import '../widgets/power_display_widget.dart';
import 'recipe_list_screen.dart';
import 'connection_screen.dart';
import 'debug_screen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final MicrowaveService _service = MicrowaveService();
  MicrowaveState _currentState = MicrowaveState.initial();

  @override
  void initState() {
    super.initState();
    _listenToStateChanges();
  }

  void _listenToStateChanges() {
    _service.stateStream.listen((state) {
      setState(() {
        _currentState = state;
      });
    });
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _handleRecipeSelected(Recipe recipe) async {
    await _service.startRecipe(recipe);
  }

  Future<void> _handleStop() async {
    await _service.stopMicrowave();
  }

  Future<void> _handleDisconnect() async {
    bool confirm = await _showDisconnectDialog();
    if (confirm) {
      await _service.disconnect();
    }
  }

  Future<bool> _showDisconnectDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Desconectar'),
            content: Text('Tem certeza que deseja desconectar do microondas?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text('Desconectar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Smart Microondas'),
        centerTitle: true,
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          if (_currentState.isConnected)
            IconButton(
              icon: Icon(Icons.bluetooth_connected),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Dispositivo Conectado'),
                    content: Text(
                      _service.connectedDevice?.platformName ?? 'ESP32',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: _currentState.isConnected
          ? _buildConnectedView()
          : ConnectionScreen(
              onConnected: () {
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Conectado com sucesso!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
    );
  }

  Widget _buildConnectedView() {
    return Column(
      children: [
        // Status Card - Padding reduzido
        Padding(
          padding: EdgeInsets.fromLTRB(12, 8, 12, 4), // Margens reduzidas
          child: StatusCard(
            state: _currentState,
            onDisconnect: _handleDisconnect,
            onStop: _currentState.isRunning ? _handleStop : null,
          ),
        ),

        // Power Display Widget - Padding reduzido
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4), // Margens reduzidas
          child: PowerDisplayWidget(state: _currentState),
        ),

        // Timer (se estiver rodando) - Padding reduzido
        if (_currentState.isRunning && _currentState.currentRecipe != null)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8), // Reduzido de 16 para 8
            child: TimerWidget(
              remainingSeconds: _currentState.remainingTime,
              totalSeconds: _currentState.currentRecipe!.timeInSeconds,
              isRunning: _currentState.isRunning,
            ),
          ),

        // Recipe List
        Expanded(
          child: RecipeListScreen(
            onRecipeSelected: _handleRecipeSelected,
            isEnabled: !_currentState.isRunning,
          ),
        ),
      ],
    );
  }
}