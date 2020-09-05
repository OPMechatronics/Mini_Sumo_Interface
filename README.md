# Mini_Sumo_Interface

A graphical interface for Mini Sumo robots, created with Processing.

I'm using HC-05 Bluetooth module to send data from my Mini Sumo robot.
In the Arduino sketch for the robot it initialises the Bluetooth serial communication
then it uses the function below to send data to the computer.
Note that not all variables that are sent are used in the code. But sometimes the are used for testing purposes. 

// Sends data from the robot over Bluetooth.
//If you update what data to send make sure that the software that recives the data is updated aswell.
void updateBT() {
  BT.print(angleZdeg); //float
  BT.print(","); //Seperation mark
  BT.print(attackZone); //int
  BT.print(",");  //Seperation mark
  BT.print(sumoPosX); //float
  BT.print(",");  //Seperation mark
  BT.print(sumoPosY); //float
  BT.print(",");  //Seperation mark   
  BT.print(setAttackSpeed); //int
  BT.print(",");  //Seperation mark
  BT.print(totalDistX); //float
  BT.print(",");  //Seperation mark
  BT.print(edgeTurnAngle); // int
  BT.print(",");  //Seperation mark
  BT.print(">"); //END Mark
}