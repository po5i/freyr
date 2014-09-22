// include the library code:
#include <LiquidCrystal.h>

// initialize the library with the numbers of the interface pins
LiquidCrystal lcd(12, 11, 5, 4, 3, 2);

const int VAL_PROBE = 0; // Analog pin 0
const int led_feedback = 7;
float MOISTURE_LEVEL = 50; // the value after the LED goes ON
 
void setup() {
    Serial.begin(9600);
    pinMode(led_feedback, OUTPUT);
}
 
void LedState(int state) {
    digitalWrite(led_feedback, state);
}
 
void loop() {
    MOISTURE_LEVEL = analogRead(A5);
    float moisture = analogRead(VAL_PROBE);
 
    //Serial.println(moisture);  //para processing
    
    float deseada = (MOISTURE_LEVEL/1023)*100;
    float actual = (moisture/1023)*100;
    
    lcd.clear();
    
    lcd.begin(16, 2);
    lcd.print("Deseada: ");
    lcd.print(deseada);
    lcd.print("%");
    
    lcd.setCursor(0, 1);
    lcd.print("Actual:  ");
    lcd.print(actual); 
    lcd.print("%");
    
    
 
    if(moisture > MOISTURE_LEVEL) {
        LedState(LOW);
        Serial.println(0);  //para processing
        //lcd.clear();
        //lcd.begin(16, 2);
        //lcd.print("DESACTIVADO!");
        
    } else   {
        LedState(HIGH);
        Serial.println(1);  //para processing
        //lcd.clear();
        //lcd.begin(16, 2);
        //lcd.print("ACTIVADO!");
    }
    delay(500);
}
