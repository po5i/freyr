// include the library code:
#include <LiquidCrystal.h>

// initialize the library with the numbers of the interface pins
LiquidCrystal lcd(12, 11, 5, 4, 3, 2);

const int VAL_PROBE = 0; // Analog pin 0
const int led_feedback = 7;
float MOISTURE_LEVEL = 50; // the value after the LED goes ON
float threshold = 1;
float MOISTURE = 0;
int CHANGER = 0;
float maxima = 90;
float minima = 10;

 
void setup() {
    Serial.begin(9600);
    pinMode(led_feedback, OUTPUT);
}
 
void LedState(int state) {
    digitalWrite(led_feedback, state);
}
 
void loop() {
    MOISTURE_LEVEL = analogRead(A5);  //potenciometro
    MOISTURE = analogRead(VAL_PROBE);  //sensor
    CHANGER = digitalRead(8);  //switch
    
    float lectura = (MOISTURE_LEVEL/1023)*100;
    
    if(CHANGER == 1){
      if(lectura > (minima + threshold) && lectura < 100)
        maxima = lectura;
      
    }
    else{
      if(lectura < (maxima - threshold) && lectura > 0)
        minima = lectura;
    }
    
 
    //Serial.println(moisture);  //para processing
    
    float actual = (MOISTURE/1023)*100;
    
    lcd.clear();
    
    lcd.begin(16, 2);
    lcd.print("MIN:");
    lcd.print((int)minima);
    lcd.print("%");
    
    lcd.print(" MAX:");
    lcd.print((int)maxima);
    lcd.print("%");
    
    
    lcd.setCursor(0, 1);
    lcd.print("ACTUAL:  ");
    lcd.print((int)actual); 
    lcd.print("%");
    
    
     //TODO: debe retornar el estado de la bomba y el valor de la humedad concatenados.
    if(actual > maxima) {
        LedState(LOW);
        Serial.println(0);  //para processing
        
        
    } else if(actual < minima)   {
        LedState(HIGH);
        Serial.println(1);  //para processing
        
        //TODO : activar la bomba intermitentemete y con delay 
        //para evitar inundación
    }
    delay(500);
}
