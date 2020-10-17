#include <Servo.h>
#include <NewPing.h>

// Defines necessary constants for setup
const int servoPin = 9;
const int trigPin = 12;
const int echoPin = 11;
const int maxDist = 30;

// Variable to store distance from Sonar
int distance;

// Creates objects for Servo and Sonar
Servo s;
NewPing sonar(trigPin, echoPin, maxDist);

void setup() {
  // Initializes serial communication to send data
  Serial.begin(115200);
  // Initializes Servo object and starts it at 0
  s.attach(9);
  s.write(0);
}

// Function that will send data over serial
void sendPacket(int angle, int distance) {   
  Serial.print(angle);
  Serial.print(",");
  Serial.println(distance);
} 

void loop()
{
  // For loop to sweep
  for(int i = 0; i <= 180; i++){
    s.write(i);
    delay(15);
    // Gets distance of object
    distance = sonar.ping_cm();
    // Calls function to send data
    sendPacket(i, distance);
  }
  // For loop to sweep
  for(int i = 179; i > 1; i--){  
    s.write(i);
    delay(15);
    // Gets distance of object
    distance = sonar.ping_cm();
    // Calls function to send data
    sendPacket(i, distance);
  }
}
