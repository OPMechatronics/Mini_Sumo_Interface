int angle = 1; //0-360
int attackZone = 2; //0-12
int posX = 3; //0-350
int posY = 4; //0-350
int value5 = 5;
int value6 = 6;
int value7 = 7;
int value8 = 8;

void setup() {
  // put your setup code here, to run once:
  Serial.begin(115200);
}

void loop() {
  // put your main code here, to run repeatedly:
  updateSerial();
}

// Sends data from the robot over Bluetooth.
//If you update what data to send make sure that the interface software is updated aswell.
void updateSerial() {
  Serial.print(angle);
  Serial.print(","); //Seperation mark
  Serial.print(attackZone);
  Serial.print(",");  //Seperation mark
  Serial.print(posX);
  Serial.print(",");  //Seperation mark
  Serial.print(posY);
  Serial.print(",");  //Seperation mark   
  Serial.print(value5);
  Serial.print(",");  //Seperation mark
  Serial.print(value6);
  Serial.print(",");  //Seperation mark
  Serial.print(value7); 
  Serial.print(",");  //Seperation mark
  Serial.print(value8);
  Serial.print(",");  //Seperation mark
  Serial.print('>'); //END Mark
}
