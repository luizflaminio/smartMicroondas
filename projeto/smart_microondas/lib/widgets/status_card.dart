// lib/widgets/status_card.dart
import 'package:flutter/material.dart';
import '../models/microwave_state.dart';
import '../utils/formatters.dart';

class StatusCard extends StatelessWidget {
  final MicrowaveState state;
  final VoidCallback? onDisconnect;
  final VoidCallback? onStop;

  const StatusCard({
    Key? key,
    required this.state,
    this.onDisconnect,
    this.onStop,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConnectionStatus(context),

            if (state.isConnected) ...[
              Divider(height: 32),
              _buildStatusInfo(context),
            ],

            if (state.isRunning && state.currentRecipe != null) ...[
              Divider(height: 32),
              _buildCurrentRecipe(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatus(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: state.isConnected ? Colors.green : Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 8),
            Text(
              state.statusText,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: state.isConnected ? Colors.green[700] : Colors.grey[600],
              ),
            ),
          ],
        ),
        if (state.isConnected && onDisconnect != null)
          TextButton(
            onPressed: onDisconnect,
            child: Text('Desconectar'),
          ),
      ],
    );
  }

  Widget _buildStatusInfo(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatusItem(
          icon: Icons.thermostat,
          iconColor: Colors.orange,
          value: TemperatureFormatter.format(state.currentTemperature.toInt()),
          label: 'Temperatura',
        ),
        _buildStatusItem(
          icon: state.isDoorOpen ? Icons.door_front_door : Icons.door_front_door_outlined,
          iconColor: state.isDoorOpen ? Colors.red : Colors.green,
          value: state.isDoorOpen ? 'ABERTA' : 'FECHADA',
          label: 'Porta',
        ),
        _buildStatusItem(
          icon: Icons.timer,
          iconColor: Colors.blue,
          value: TimeFormatter.formatTime(state.remainingTime.toInt()),
          label: 'Tempo Restante',
        ),
      ],
    );
  }

  Widget _buildStatusItem({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentRecipe(BuildContext context) {
    final recipe = state.currentRecipe!;

    return Column(
      children: [
        Text(
          'Receita Atual: ${recipe.name}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Potência: ${PowerFormatter.format(recipe.power)}',
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
        if (onStop != null) ...[
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onStop,
            icon: Icon(Icons.stop),
            label: Text('Parar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 48),
            ),
          ),
        ],
      ],
    );
  }
}
