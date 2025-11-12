#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

#define SERVICE_UUID        "000000ff-0000-1000-8000-00805f9b34fb"
#define CHAR_UUID_RX        "0000ff01-0000-1000-8000-00805f9b34fb"
#define CHAR_UUID_TX        "0000ff02-0000-1000-8000-00805f9b34fb"
#define LED_PIN 2

BLEServer* pServer = NULL;
BLECharacteristic* pTxCharacteristic;
bool deviceConnected = false;

void processCommand(String command);

class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      Serial.println("=== CLIENTE CONECTADO ===");
      
      for(int i = 0; i < 3; i++) {
        digitalWrite(LED_PIN, HIGH);
        delay(100);
        digitalWrite(LED_PIN, LOW);
        delay(100);
      }
      
      delay(500);
      pTxCharacteristic->setValue("CONNECTED");
      pTxCharacteristic->notify();
      Serial.println("Mensagem CONNECTED enviada");
    };

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
      Serial.println("=== CLIENTE DESCONECTADO ===");
      BLEDevice::startAdvertising();
    }
};

class MyCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      String rxValue = pCharacteristic->getValue().c_str();
      if (rxValue.length() > 0) {
        Serial.print("Recebido: ");
        Serial.println(rxValue);
        processCommand(rxValue);
      }
    }
};

void processCommand(String command) {
  command.trim();
  Serial.print("Processando: [");
  Serial.print(command);
  Serial.println("]");
  
  if (command == "PING") {
    Serial.println("-> PONG");
    pTxCharacteristic->setValue("PONG");
    pTxCharacteristic->notify();
    digitalWrite(LED_PIN, HIGH);
    delay(100);
    digitalWrite(LED_PIN, LOW);
  }
  else if (command.startsWith("START:")) {
    Serial.println("-> START recebido");
    int firstColon = command.indexOf(':', 6);
    int secondColon = command.indexOf(':', firstColon + 1);
    
    String recipeName = command.substring(6, firstColon);
    String timeStr = command.substring(firstColon + 1, secondColon);
    String powerStr = command.substring(secondColon + 1);
    
    Serial.println("Receita: " + recipeName);
    Serial.println("Tempo: " + timeStr + "s");
    Serial.println("Potencia: " + powerStr + "%");
    
    String response = "STATUS:1:30:" + timeStr + ":" + recipeName + ":" + powerStr;
    pTxCharacteristic->setValue(response.c_str());
    pTxCharacteristic->notify();
    digitalWrite(LED_PIN, HIGH);
  }
  else if (command == "STOP") {
    Serial.println("-> STOP");
    digitalWrite(LED_PIN, LOW);
    pTxCharacteristic->setValue("STATUS:0:25:0::0");
    pTxCharacteristic->notify();
  }
  else if (command == "STATUS") {
    Serial.println("-> STATUS");
    pTxCharacteristic->setValue("STATUS:0:25:0::0");
    pTxCharacteristic->notify();
  }
  else {
    String response = "OK:" + command;
    pTxCharacteristic->setValue(response.c_str());
    pTxCharacteristic->notify();
  }
}

void setup() {
  Serial.begin(115200);
  
  // Aguardar serial estabilizar
  while(!Serial) {
    delay(10);
  }
  delay(1000);
  
  Serial.println("");
  Serial.println("========================================");
  Serial.println("SMART MICROONDAS ESP32 v1.0");
  Serial.println("========================================");

  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);
  Serial.println("[OK] LED configurado");

  Serial.println("[...] Iniciando BLE...");
  BLEDevice::init("Smart_Microondas_ESP32");
  Serial.println("[OK] BLE Device criado");

  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());
  Serial.println("[OK] BLE Server criado");

  BLEService *pService = pServer->createService(SERVICE_UUID);
  Serial.println("[OK] Service criado");

  pTxCharacteristic = pService->createCharacteristic(
                        CHAR_UUID_TX,
                        BLECharacteristic::PROPERTY_NOTIFY
                      );
  pTxCharacteristic->addDescriptor(new BLE2902());
  Serial.println("[OK] TX Characteristic");

  BLECharacteristic * pRxCharacteristic = pService->createCharacteristic(
                        CHAR_UUID_RX,
                        BLECharacteristic::PROPERTY_WRITE
                      );
  pRxCharacteristic->setCallbacks(new MyCallbacks());
  Serial.println("[OK] RX Characteristic");

  pService->start();
  Serial.println("[OK] Service iniciado");

  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(false);
  pAdvertising->setMinPreferred(0x0);
  BLEDevice::startAdvertising();
  
  Serial.println("========================================");
  Serial.println("BLE PRONTO!");
  Serial.println("Nome: Smart_Microondas_ESP32");
  Serial.println("Aguardando conexao...");
  Serial.println("========================================");
}

void loop() {
  static unsigned long lastPrint = 0;
  if (millis() - lastPrint > 5000) {
    lastPrint = millis();
    if (deviceConnected) {
      Serial.println("[STATUS] Conectado - OK");
    } else {
      Serial.println("[STATUS] Aguardando conexao...");
    }
  }
  delay(100);
}