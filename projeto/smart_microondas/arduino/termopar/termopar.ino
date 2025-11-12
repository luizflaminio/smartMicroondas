int pinCLK = 18;
int pinCS  = 5;
int pinDO  = 19;

void setup() {
  Serial.begin(115200);
  pinMode(pinCLK, OUTPUT);
  pinMode(pinCS, OUTPUT);
  pinMode(pinDO, INPUT);
  digitalWrite(pinCS, HIGH);
  digitalWrite(pinCLK, LOW);
  delay(200);
  Serial.println("=== Teste MAX6675 ===");
}

uint16_t readRaw16() {
  uint16_t value = 0;
  digitalWrite(pinCS, LOW);
  delayMicroseconds(2);

  for (int i = 15; i >= 0; i--) {
    digitalWrite(pinCLK, HIGH);
    delayMicroseconds(5);
    value |= ((uint16_t)digitalRead(pinDO) << i);
    digitalWrite(pinCLK, LOW);
    delayMicroseconds(5);
  }

  digitalWrite(pinCS, HIGH);
  return value;
}

void loop() {
  uint16_t raw = readRaw16();

  if (raw & 0x4) {
    Serial.println("⚠️  FAULT detectado — termopar desconectado ou mal contato!");
  } else {
    float tempC = (raw >> 3) * 0.25;
    Serial.print("Temperatura: ");
    Serial.print(tempC, 2);
    Serial.println(" °C");
  }

  Serial.println("------------------------");
  delay(1000);
}
