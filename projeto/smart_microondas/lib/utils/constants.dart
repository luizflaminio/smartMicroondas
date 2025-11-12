// lib/utils/constants.dart
class BLEConstants {
  // UUIDs matching ESP32
  static const String serviceUUID = '000000ff-0000-1000-8000-00805f9b34fb';
  static const String rxCharUUID = '0000ff01-0000-1000-8000-00805f9b34fb'; // Write
  static const String txCharUUID = '0000ff02-0000-1000-8000-00805f9b34fb'; // Notify
  
  // Device name
  static const String deviceName = 'Smart_Microondas_ESP32';
  
  // Timeouts
  static const Duration scanTimeout = Duration(seconds: 5);
  static const Duration connectionTimeout = Duration(seconds: 30);
}

class AppConstants {
  // App info
  static const String appName = 'Smart Microondas';
  static const String appVersion = '1.0.0';
  
  // Limits
  static const int maxTemperature = 100;
  static const int minTemperature = 0;
  static const int maxTime = 3600; // 1 hour
  static const int minTime = 10; // 10 seconds
}

class Commands {
  static const String ping = 'PING';
  static const String stop = 'STOP';
  static const String status = 'STATUS';
  
  static String start(String recipeName, int timeSeconds, int power) {
    return 'START:$recipeName:$timeSeconds:$power';
  }
}