// lib/widgets/power_display_widget.dart
import 'package:flutter/material.dart';
import '../models/microwave_state.dart';

class PowerDisplayWidget extends StatelessWidget {
  final MicrowaveState state;

  const PowerDisplayWidget({
    Key? key,
    required this.state,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12), // Reduzido de 20 para 12
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade50,
            Colors.blue.shade100,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: state.isPowerInRange ? Colors.green : Colors.orange,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Ícone
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.bolt,
              color: Colors.white,
              size: 24,
            ),
          ),
          
          SizedBox(width: 12),
          
          // Conteúdo principal
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título e potência atual
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'Potência: ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${state.calculatedPower}',
                      style: TextStyle(
                        fontSize: 32, // Grande mas não gigante
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                        height: 1.0,
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'W',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 4),
                
                // Informações compactas
                Row(
                  children: [
                    // Alvo
                    Text(
                      'Alvo: ${state.targetPower}W',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(width: 12),
                    // Temperatura
                    Icon(
                      Icons.thermostat,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    SizedBox(width: 2),
                    Text(
                      '${state.currentTemperature.toStringAsFixed(1)}°C',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Indicador de status
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: state.isPowerInRange 
                  ? Colors.green.shade100 
                  : Colors.orange.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: state.isPowerInRange 
                        ? Colors.green 
                        : Colors.orange,
                  ),
                ),
                SizedBox(width: 6),
                Text(
                  state.isPowerInRange ? 'OK' : '${_getPercentage(state).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: state.isPowerInRange 
                        ? Colors.green.shade800 
                        : Colors.orange.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _getPercentage(MicrowaveState state) {
    if (state.targetPower == 0) return 0;
    return (state.calculatedPower / state.targetPower * 100).clamp(0, 100);
  }
}