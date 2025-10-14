// lib/widgets/timer_widget.dart
import 'package:flutter/material.dart';
import '../utils/formatters.dart';

class TimerWidget extends StatelessWidget {
  final int remainingSeconds;
  final int totalSeconds;
  final bool isRunning;

  const TimerWidget({
    Key? key,
    required this.remainingSeconds,
    required this.totalSeconds,
    this.isRunning = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double progress = totalSeconds > 0 
        ? (totalSeconds - remainingSeconds) / totalSeconds 
        : 0.0;

    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCircularTimer(progress),
          SizedBox(height: 16),
          _buildTimeText(),
          if (isRunning) ...[
            SizedBox(height: 8),
            _buildProgressIndicator(),
          ],
        ],
      ),
    );
  }

  Widget _buildCircularTimer(double progress) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          SizedBox(
            width: 200,
            height: 200,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 12,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[200]!),
            ),
          ),
          // Progress circle
          SizedBox(
            width: 200,
            height: 200,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 12,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getColorForProgress(progress),
              ),
            ),
          ),
          // Center text
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                TimeFormatter.formatTime(remainingSeconds),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: _getColorForProgress(progress),
                ),
              ),
              SizedBox(height: 4),
              Text(
                isRunning ? 'Em andamento' : 'Parado',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeText() {
    return Text(
      'Restam ${TimeFormatter.formatTimeReadable(remainingSeconds)}',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: Colors.grey[700],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
          SizedBox(width: 8),
          Text(
            'Cozinhando...',
            style: TextStyle(
              color: Colors.blue[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForProgress(double progress) {
    if (progress < 0.33) return Colors.green;
    if (progress < 0.66) return Colors.orange;
    return Colors.red;
  }
}

// Widget de timer compacto para lista
class TimerWidgetCompact extends StatelessWidget {
  final int remainingSeconds;
  final int totalSeconds;

  const TimerWidgetCompact({
    Key? key,
    required this.remainingSeconds,
    required this.totalSeconds,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double progress = totalSeconds > 0 
        ? (totalSeconds - remainingSeconds) / totalSeconds 
        : 0.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tempo Restante',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                TimeFormatter.formatTime(remainingSeconds),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getColorForProgress(progress),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForProgress(double progress) {
    if (progress < 0.33) return Colors.green;
    if (progress < 0.66) return Colors.orange;
    return Colors.red;
  }
}