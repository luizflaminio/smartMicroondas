// lib/utils/formatters.dart
class TimeFormatter {
  /// Formata segundos para MM:SS
  static String formatTime(int seconds) {
    if (seconds < 0) seconds = 0;
    
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
  
  /// Formata segundos para formato legível (ex: "3min 20s")
  static String formatTimeReadable(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    }
    
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    
    if (secs == 0) {
      return '${minutes}min';
    }
    
    return '${minutes}min ${secs}s';
  }
  
  /// Converte MM:SS para segundos
  static int parseTime(String timeString) {
    List<String> parts = timeString.split(':');
    if (parts.length != 2) return 0;
    
    int minutes = int.tryParse(parts[0]) ?? 0;
    int seconds = int.tryParse(parts[1]) ?? 0;
    
    return (minutes * 60) + seconds;
  }
}

class TemperatureFormatter {
  /// Formata temperatura com símbolo
  static String format(int temperature) {
    return '${temperature}°C';
  }
  
  /// Retorna cor baseada na temperatura
  static int getTemperatureColor(int temperature) {
    if (temperature < 30) return 0xFF2196F3; // Azul
    if (temperature < 50) return 0xFF4CAF50; // Verde
    if (temperature < 70) return 0xFFFF9800; // Laranja
    return 0xFFF44336; // Vermelho
  }
}

class PowerFormatter {
  /// Formata potência com símbolo
  static String format(int power) {
    return '$power%';
  }
  
  /// Valida potência (0-100)
  static int validate(int power) {
    if (power < 0) return 0;
    if (power > 100) return 100;
    return power;
  }
}