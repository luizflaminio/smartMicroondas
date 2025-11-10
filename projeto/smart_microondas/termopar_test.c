#include <max6675.h>

// Definir os pinos de conexão
int thermoDO = 19;  // SO do MAX6675
int thermoCS = 5;   // CS do MAX6675
int thermoCLK = 18; // SCK do MAX6675

// Criar objeto MAX6675
MAX6675 thermocouple(thermoCLK, thermoCS, thermoDO);

void setup() {
  Serial.begin(115200);
  
  Serial.println("Sistema de medicao de temperatura");
  Serial.println("Termopar tipo K + MAX6675");
  
  // Pequeno delay para estabilizar o MAX6675
  delay(500);
}

void loop() {
  // Ler temperatura em Celsius
  float temperatureC = thermocouple.readCelsius();
  
  // Verificar se a leitura é válida
  if (isnan(temperatureC)) {
    Serial.println("Erro ao ler temperatura!");
  } else {
    Serial.print("Temperatura: ");
    Serial.print(temperatureC);
    Serial.println(" °C");
  }
  
  // Aguardar 1 segundo entre leituras
  delay(1000);
}