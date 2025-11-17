// lib/utils/constants.dart

class BLEConstants {
  // Device info
  static const String deviceName = 'Smart_Microondas';
  
  // Service and Characteristic UUIDs
  static const String serviceUUID = '000000ff-0000-1000-8000-00805f9b34fb';
  static const String rxCharacteristicUUID = '0000ff01-0000-1000-8000-00805f9b34fb';
  static const String txCharacteristicUUID = '0000ff02-0000-1000-8000-00805f9b34fb';
  
  // Connection
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration scanTimeout = Duration(seconds: 5);
}

class Commands {
  static const String ping = 'PING';
  static const String stop = 'STOP';
  static const String status = 'STATUS';
  static const String getTemp = 'GET_TEMP';
  static const String relayOn = 'RELAY:ON';
  static const String relayOff = 'RELAY:OFF';
  
  static String start(String recipeName, int timeInSeconds, int power) {
    return 'START:$recipeName:$timeInSeconds:$power';
  }
}

class PowerConstants {
  // Temperatura
  static const double tempMin = 20.0; // °C
  static const double tempMax = 50.0; // °C
  
  // Potência
  static const int powerMax = 1000; // Watts
  
  // Controle
  static const double relayTolerance = 0.02; // 2%
}