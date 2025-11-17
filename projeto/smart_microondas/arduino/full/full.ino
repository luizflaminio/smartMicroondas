#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// UUIDs BLE
#define SERVICE_UUID        "000000ff-0000-1000-8000-00805f9b34fb"
#define CHAR_UUID_RX        "0000ff01-0000-1000-8000-00805f9b34fb"
#define CHAR_UUID_TX        "0000ff02-0000-1000-8000-00805f9b34fb"

// Pinos
#define LED_PIN 2
#define RELAY_PIN 23  // AJUSTE ESTE PINO CONFORME SEU HARDWARE!

// Pinos MAX6675
#define PIN_CLK 18
#define PIN_CS  5
#define PIN_DO  19

BLEServer* pServer = NULL;
BLECharacteristic* pTxCharacteristic;
bool deviceConnected = false;
bool isRunning = false;
unsigned long startTime = 0;
int targetTime = 0;
int powerLevel = 0;
String currentRecipe = "";

// Controle do rele
bool relayState = false;

// Variaveis para envio automatico de temperatura
unsigned long lastTempSend = 0;
const unsigned long TEMP_INTERVAL = 2000; // Enviar temperatura a cada 2 segundos

void processCommand(String command);
uint16_t readRaw16();
float readTemperature();
void setRelay(bool state);

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
      isRunning = false;
      digitalWrite(LED_PIN, LOW);
      setRelay(false); // Desliga rele ao desconectar
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

// ============================================================
// CONTROLE DO RELE
// ============================================================
void setRelay(bool state) {
  relayState = state;
  digitalWrite(RELAY_PIN, state ? HIGH : LOW);
  Serial.print("RELE: ");
  Serial.println(state ? "LIGADO" : "DESLIGADO");
}

// ============================================================
// MAX6675 - LEITURA DE TEMPERATURA
// ============================================================
uint16_t readRaw16() {
  uint16_t value = 0;
  digitalWrite(PIN_CS, LOW);
  delayMicroseconds(2);

  for (int i = 15; i >= 0; i--) {
    digitalWrite(PIN_CLK, HIGH);
    delayMicroseconds(5);
    value |= ((uint16_t)digitalRead(PIN_DO) << i);
    digitalWrite(PIN_CLK, LOW);
    delayMicroseconds(5);
  }

  digitalWrite(PIN_CS, HIGH);
  return value;
}

float readTemperature() {
  uint16_t raw = readRaw16();
  
  // Verificar se ha falha (bit 2 = 1 indica termopar desconectado)
  if (raw & 0x4) {
    Serial.println("ERRO - Termopar desconectado!");
    return -999.0; // Valor de erro
  }
  
  // Calcular temperatura (bits 14-3, resolucao de 0.25 graus C)
  float tempC = (raw >> 3) * 0.25;
  return tempC;
}

void sendTemperature() {
  float temp = readTemperature();
  
  if (temp == -999.0) {
    // Erro de leitura
    pTxCharacteristic->setValue("TEMP:ERROR");
    pTxCharacteristic->notify();
    Serial.println("Enviado: TEMP:ERROR");
  } else {
    // Enviar temperatura formatada
    String tempMsg = "TEMP:" + String(temp, 2);
    pTxCharacteristic->setValue(tempMsg.c_str());
    pTxCharacteristic->notify();
    Serial.print("Enviado: ");
    Serial.println(tempMsg);
  }
}

// ============================================================
// PROCESSAMENTO DE COMANDOS BLE
// ============================================================
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
  else if (command == "GET_TEMP") {
    Serial.println("-> Solicitacao de temperatura");
    sendTemperature();
  }
  // NOVO: Controle do rele via comando BLE
  else if (command == "RELAY:ON") {
    Serial.println("-> RELAY:ON recebido");
    setRelay(true);
    pTxCharacteristic->setValue("OK:RELAY:ON");
    pTxCharacteristic->notify();
  }
  else if (command == "RELAY:OFF") {
    Serial.println("-> RELAY:OFF recebido");
    setRelay(false);
    pTxCharacteristic->setValue("OK:RELAY:OFF");
    pTxCharacteristic->notify();
  }
  else if (command.startsWith("START:")) {
    Serial.println("-> START recebido");
    int firstColon = command.indexOf(':', 6);
    int secondColon = command.indexOf(':', firstColon + 1);
    
    currentRecipe = command.substring(6, firstColon);
    String timeStr = command.substring(firstColon + 1, secondColon);
    String powerStr = command.substring(secondColon + 1);
    
    targetTime = timeStr.toInt();
    powerLevel = powerStr.toInt();
    
    Serial.println("Receita: " + currentRecipe);
    Serial.println("Tempo: " + String(targetTime) + "s");
    Serial.println("Potencia: " + String(powerLevel) + "%");
    
    isRunning = true;
    startTime = millis();
    digitalWrite(LED_PIN, HIGH);
    
    float currentTemp = readTemperature();
    String response = "STATUS:1:" + String(currentTemp, 1) + ":" + timeStr + ":" + currentRecipe + ":" + powerStr;

    pTxCharacteristic->setValue(response.c_str());
    pTxCharacteristic->notify();
  }
  else if (command == "STOP") {
    Serial.println("-> STOP");
    isRunning = false;
    setRelay(false); // Desliga rele ao parar
    digitalWrite(LED_PIN, LOW);
    pTxCharacteristic->setValue("STATUS:0:25:0::0");
    pTxCharacteristic->notify();
  }
  else if (command == "STATUS") {
    Serial.println("-> STATUS");
    if (isRunning) {
      int elapsed = (millis() - startTime) / 1000;
      int remaining = targetTime - elapsed;
      if (remaining < 0) remaining = 0;

      float currentTemp = readTemperature();
      String response = "STATUS:1:" + String(currentTemp, 1) + ":" + String(remaining) + ":" + currentRecipe + ":" + String(powerLevel);
      pTxCharacteristic->setValue(response.c_str());
    } else {
      pTxCharacteristic->setValue("STATUS:0:25:0::0");
    }
    pTxCharacteristic->notify();
  }
  else {
    String response = "OK:" + command;
    pTxCharacteristic->setValue(response.c_str());
    pTxCharacteristic->notify();
  }
}

// ============================================================
// SETUP
// ============================================================
void setup() {
  Serial.begin(115200);
  
  // Aguardar serial estabilizar
  while(!Serial) {
    delay(10);
  }
  delay(1000);
  
  Serial.println("");
  Serial.println("========================================");
  Serial.println("SMART MICROONDAS ESP32 + MAX6675 v2.0");
  Serial.println("Com controle de rele via temperatura");
  Serial.println("========================================");

  // Configurar Rele
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, LOW);
  Serial.print("[OK] Rele configurado (Pino ");
  Serial.print(RELAY_PIN);
  Serial.println(")");

  // Configurar LED
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);
  Serial.println("[OK] LED configurado");

  // Configurar MAX6675
  pinMode(PIN_CLK, OUTPUT);
  pinMode(PIN_CS, OUTPUT);
  pinMode(PIN_DO, INPUT);
  digitalWrite(PIN_CS, HIGH);
  digitalWrite(PIN_CLK, LOW);
  delay(200);
  Serial.println("[OK] MAX6675 configurado");

  // Teste inicial de temperatura
  float testTemp = readTemperature();
  if (testTemp != -999.0) {
    Serial.print("[OK] Temperatura inicial: ");
    Serial.print(testTemp, 2);
    Serial.println(" graus C");
  } else {
    Serial.println("[AVISO] Erro ao ler temperatura inicial");
  }

  // Iniciar BLE
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
  Serial.println("BLE + MAX6675 + RELE PRONTO!");
  Serial.println("Nome: Smart_Microondas_ESP32");
  Serial.println("Aguardando conexao...");
  Serial.println("========================================");
}

// ============================================================
// LOOP
// ============================================================
void loop() {
  static unsigned long lastPrint = 0;
  static unsigned long lastStatusSend = 0;
  
  // Status geral a cada 5 segundos
  if (millis() - lastPrint > 5000) {
    lastPrint = millis();
    if (deviceConnected) {
      float temp = readTemperature();
      if (temp != -999.0) {
        Serial.print("[TEMP] ");
        Serial.print(temp, 2);
        Serial.println(" graus C");
      }
    } else {
      Serial.println("[STATUS] Aguardando conexao...");
    }
  }

  // Enviar temperatura automaticamente quando conectado e rodando
  if (deviceConnected && isRunning) {
    if (millis() - lastTempSend > TEMP_INTERVAL) {
      lastTempSend = millis();
      sendTemperature();
    }
    if (millis() - lastStatusSend > 1000) {
      lastStatusSend = millis();
      
      int elapsed = (millis() - startTime) / 1000;
      int remaining = targetTime - elapsed;
      if (remaining < 0) remaining = 0;
      
      float currentTemp = readTemperature();
      String response = "STATUS:1:" + String(currentTemp, 1) + ":" + String(remaining) + ":" + currentRecipe + ":" + String(powerLevel);
      pTxCharacteristic->setValue(response.c_str());
      pTxCharacteristic->notify();
    }
    // Verificar se o tempo acabou
    int elapsed = (millis() - startTime) / 1000;
    if (elapsed >= targetTime) {
      isRunning = false;
      setRelay(false); // Desliga rele quando terminar
      digitalWrite(LED_PIN, LOW);
      Serial.println("-> Tempo finalizado!");
      pTxCharacteristic->setValue("FINISHED");
      pTxCharacteristic->notify();
    }
  }
  
  delay(100);
}
