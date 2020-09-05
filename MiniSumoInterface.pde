/** //<>// //<>//
 *Mini Sumo Interface
 Rev000
 
 Created by:
 Oskar Persson
 */

import processing.serial.*;

//#######################################
//                Variables
//#######################################
//Dohyo
int dohyoX = 1200;
int dohyoY = 400;
int dohyoSize = 770;

//Mini Sumo
color sumoColor = color(130);
color sumoSensorColor = color(30);
color dirColor = color(255, 0, 0);
color enemyColor = color(255, 0, 0);
int sumoSize = 100;
int dirSize = 40;
int sumoSensorSize = 300;
int sensorLength = 200;
int sensorWidth = 30;

//Text
PFont f;
int colA = 100;
int colB = 500;
int rowA = 100;
int rowB = 150;
int rowC = 200;

//Data/Input
int angle = 0;
int speed = 0;
int posX = 185;
int posY = 0;
int attackZone = 0;
int edgeDetect = 0;
int totalDistX = 0;
int edgeTurnAngle = 0;

int dataDelay = 100;
int dataLastTime = 0;

//Bluetooth
Serial myPort;  // The serial port
String btData;
String[] btDataParse = new String[7]; //Expecting 7 input data

void setup() {
  size(1600, 800);

  // Open the port you are using at the rate you want:
  myPort = new Serial(this, "COM4", 115200); //COM4 is the Bluetooth serial port on my PC
  myPort.bufferUntil(62); // Fills the buffer until it detects >, ASCII 62
  myPort.clear();

  // Create the font
  //printArray(PFont.list()); //prints a list of all available fonts
  f = createFont("Times New Roman", 32);
  textFont(f);
}

void draw() {
  background(123);
  line(800, 0, 800, height);
  dohyo();
  enemy(posX, posY, angle, attackZone);
  miniSumo(posX, posY, angle);

  showData();
  sumoSensors(attackZone);
  showParsedData();
}

void serialEvent(Serial p) { 
  btData = p.readString();
  btDataParse = splitTokens(btData, ",");
  convertBtData(btDataParse);
} 

//Draws the Dohyo
void dohyo() {
  stroke(0);
  strokeWeight(4);
  fill(255);
  ellipse(dohyoX, dohyoY, dohyoSize, dohyoSize);
  fill(0);
  ellipse(dohyoX, dohyoY, dohyoSize - 50, dohyoSize - 50);
}

//Prints the input in the top left
void showData() {
  textAlign(LEFT);
  fill(0);
  // text("Angle: " + angle, colA, rowA); Orginal
  text("Angle: " + angle, colA, rowA);
  fill(0);
  text("Speed: " + speed, colA, rowB);
  fill(0);
  text("PosX: " + posX, colB, rowA);
  fill(0);
  text("PosY: " + posY, colB, rowB);
  //fill(0);
  //text("edgeTurnAngle: " + edgeTurnAngle, colA, rowC);
}

//Draws the mini sumo inside the dohyo att coordinates x,y
void miniSumo(int x, int y, int dir) {
  pushMatrix();
  // negative y since the dohyo coordinates are invertet the window coordinates
  translate(x + dohyoX, -y + dohyoY); 
  rotate(radians(-dir));
  rectMode(CENTER);
  fill(sumoColor);
  rect(0, 0, sumoSize, sumoSize);
  fill(dirColor);
  triangle(0, -dirSize/2, dirSize, 0, 0, dirSize/2);
  popMatrix();
}

//Draws a sumo in the bottom left that indicates which sensors that are triggered
void sumoSensors (int zone) {
  rectMode(CENTER);
  fill(sumoSensorColor);
  rect(0.25 * width, 0.75 * height, sumoSensorSize, sumoSensorSize);

  //draws the sensor vision cones
  float tx1S1 = (0.25 * width) - sumoSensorSize/2;
  float ty1S1 = 0.75 * height;
  float tx2S1 = tx1S1 - sensorLength;
  float ty2S1 = ty1S1 + sensorWidth/2;
  float tx3S1 = tx2S1;
  float ty3S1 = ty2S1 - sensorWidth;

  float tx1S2 = (0.25 * width) - 0.4 * sumoSensorSize;
  float ty1S2 = 0.75 * height - sumoSensorSize/2;
  float tx2S2 = tx1S2 - sensorWidth/2;
  float ty2S2 = ty1S2 - sensorLength;
  float tx3S2 = tx2S2 + sensorWidth;
  float ty3S2 = ty2S2;

  float tx1S3 = (0.25 * width) - 0.1 * sumoSensorSize;
  float ty1S3 = 0.75 * height - sumoSensorSize/2;
  float tx2S3 = tx1S3 + 0.7071 * (sensorLength + 80);
  float ty2S3 = ty1S3 - 0.7071 * (sensorLength + 80);
  float tx3S3 = tx2S3 + sensorWidth;
  float ty3S3 = ty2S3;

  float tx1S4 = (0.25 * width) + 0.1 * sumoSensorSize;
  float ty1S4 = 0.75 * height - sumoSensorSize/2;
  float tx2S4 = tx1S4 - 0.7071 * (sensorLength + 80);
  float ty2S4 = ty1S4 - 0.7071 * (sensorLength + 80);
  float tx3S4 = tx2S4 - sensorWidth;
  float ty3S4 = ty2S4;

  float tx1S5 = (0.25 * width) + 0.4 * sumoSensorSize;
  float ty1S5 = 0.75 * height - sumoSensorSize/2;
  float tx2S5 = tx1S5 - sensorWidth/2;
  float ty2S5 = ty1S5 - sensorLength;
  float tx3S5 = tx2S5 + sensorWidth;
  float ty3S5 = ty2S5;  

  float tx1S6 = (0.25 * width) + sumoSensorSize/2;
  float ty1S6 = 0.75 * height;
  float tx2S6 = tx1S6 + sensorLength;
  float ty2S6 = ty1S6 + sensorWidth/2;
  float tx3S6 = tx2S6;
  float ty3S6 = ty2S6 - sensorWidth;  

  switch(zone) {
  case 0:
    fill(255);
    triangle(tx1S1, ty1S1, tx2S1, ty2S1, tx3S1, ty3S1);
    triangle(tx1S2, ty1S2, tx2S2, ty2S2, tx3S2, ty3S2);
    triangle(tx1S3, ty1S3, tx2S3, ty2S3, tx3S3, ty3S3);
    triangle(tx1S4, ty1S4, tx2S4, ty2S4, tx3S4, ty3S4);
    triangle(tx1S5, ty1S5, tx2S5, ty2S5, tx3S5, ty3S5);
    triangle(tx1S6, ty1S6, tx2S6, ty2S6, tx3S6, ty3S6);
    break;
  case 1:
    fill(255, 0, 0);
    triangle(tx1S1, ty1S1, tx2S1, ty2S1, tx3S1, ty3S1);
    fill(255);
    triangle(tx1S2, ty1S2, tx2S2, ty2S2, tx3S2, ty3S2);
    triangle(tx1S3, ty1S3, tx2S3, ty2S3, tx3S3, ty3S3);
    triangle(tx1S4, ty1S4, tx2S4, ty2S4, tx3S4, ty3S4);
    triangle(tx1S5, ty1S5, tx2S5, ty2S5, tx3S5, ty3S5);
    triangle(tx1S6, ty1S6, tx2S6, ty2S6, tx3S6, ty3S6);
    break;
  case 2:
    fill(255, 0, 0);
    triangle(tx1S4, ty1S4, tx2S4, ty2S4, tx3S4, ty3S4);
    fill(255);
    triangle(tx1S1, ty1S1, tx2S1, ty2S1, tx3S1, ty3S1);
    triangle(tx1S2, ty1S2, tx2S2, ty2S2, tx3S2, ty3S2);
    triangle(tx1S3, ty1S3, tx2S3, ty2S3, tx3S3, ty3S3);
    triangle(tx1S5, ty1S5, tx2S5, ty2S5, tx3S5, ty3S5);
    triangle(tx1S6, ty1S6, tx2S6, ty2S6, tx3S6, ty3S6);
    break;
  case 3:
    fill(255, 0, 0);
    triangle(tx1S2, ty1S2, tx2S2, ty2S2, tx3S2, ty3S2);
    fill(255);
    triangle(tx1S1, ty1S1, tx2S1, ty2S1, tx3S1, ty3S1);
    triangle(tx1S3, ty1S3, tx2S3, ty2S3, tx3S3, ty3S3);
    triangle(tx1S4, ty1S4, tx2S4, ty2S4, tx3S4, ty3S4);
    triangle(tx1S5, ty1S5, tx2S5, ty2S5, tx3S5, ty3S5);
    triangle(tx1S6, ty1S6, tx2S6, ty2S6, tx3S6, ty3S6);
    break;
  case 4:
    fill(255, 0, 0);
    triangle(tx1S5, ty1S5, tx2S5, ty2S5, tx3S5, ty3S5);
    fill(255);
    triangle(tx1S1, ty1S1, tx2S1, ty2S1, tx3S1, ty3S1);
    triangle(tx1S2, ty1S2, tx2S2, ty2S2, tx3S2, ty3S2);
    triangle(tx1S3, ty1S3, tx2S3, ty2S3, tx3S3, ty3S3);
    triangle(tx1S4, ty1S4, tx2S4, ty2S4, tx3S4, ty3S4);
    triangle(tx1S6, ty1S6, tx2S6, ty2S6, tx3S6, ty3S6);
    break;
  case 5:
    fill(255, 0, 0);
    triangle(tx1S3, ty1S3, tx2S3, ty2S3, tx3S3, ty3S3);
    fill(255);
    triangle(tx1S1, ty1S1, tx2S1, ty2S1, tx3S1, ty3S1);
    triangle(tx1S2, ty1S2, tx2S2, ty2S2, tx3S2, ty3S2);
    triangle(tx1S4, ty1S4, tx2S4, ty2S4, tx3S4, ty3S4);
    triangle(tx1S5, ty1S5, tx2S5, ty2S5, tx3S5, ty3S5);
    triangle(tx1S6, ty1S6, tx2S6, ty2S6, tx3S6, ty3S6);
    break;
  case 6:
    fill(255, 0, 0);
    triangle(tx1S6, ty1S6, tx2S6, ty2S6, tx3S6, ty3S6);      
    fill(255);
    triangle(tx1S1, ty1S1, tx2S1, ty2S1, tx3S1, ty3S1);
    triangle(tx1S2, ty1S2, tx2S2, ty2S2, tx3S2, ty3S2);
    triangle(tx1S3, ty1S3, tx2S3, ty2S3, tx3S3, ty3S3);
    triangle(tx1S4, ty1S4, tx2S4, ty2S4, tx3S4, ty3S4);
    triangle(tx1S5, ty1S5, tx2S5, ty2S5, tx3S5, ty3S5);
    break;
  case 7:
    fill(255, 0, 0);
    triangle(tx1S2, ty1S2, tx2S2, ty2S2, tx3S2, ty3S2);
    triangle(tx1S4, ty1S4, tx2S4, ty2S4, tx3S4, ty3S4);
    fill(255);
    triangle(tx1S1, ty1S1, tx2S1, ty2S1, tx3S1, ty3S1);
    triangle(tx1S3, ty1S3, tx2S3, ty2S3, tx3S3, ty3S3);
    triangle(tx1S5, ty1S5, tx2S5, ty2S5, tx3S5, ty3S5);
    triangle(tx1S6, ty1S6, tx2S6, ty2S6, tx3S6, ty3S6);
    break;
  case 8:
    fill(255, 0, 0);
    triangle(tx1S2, ty1S2, tx2S2, ty2S2, tx3S2, ty3S2);
    triangle(tx1S5, ty1S5, tx2S5, ty2S5, tx3S5, ty3S5);
    fill(255);
    triangle(tx1S1, ty1S1, tx2S1, ty2S1, tx3S1, ty3S1);
    triangle(tx1S3, ty1S3, tx2S3, ty2S3, tx3S3, ty3S3);
    triangle(tx1S4, ty1S4, tx2S4, ty2S4, tx3S4, ty3S4);
    triangle(tx1S6, ty1S6, tx2S6, ty2S6, tx3S6, ty3S6);
    break;
  case 9:
    fill(255, 0, 0);
    triangle(tx1S3, ty1S3, tx2S3, ty2S3, tx3S3, ty3S3);
    triangle(tx1S5, ty1S5, tx2S5, ty2S5, tx3S5, ty3S5);
    fill(255);
    triangle(tx1S1, ty1S1, tx2S1, ty2S1, tx3S1, ty3S1);
    triangle(tx1S2, ty1S2, tx2S2, ty2S2, tx3S2, ty3S2);
    triangle(tx1S4, ty1S4, tx2S4, ty2S4, tx3S4, ty3S4);
    triangle(tx1S6, ty1S6, tx2S6, ty2S6, tx3S6, ty3S6);
    break;
  case 10:
    fill(255, 0, 0);
    triangle(tx1S2, ty1S2, tx2S2, ty2S2, tx3S2, ty3S2);
    triangle(tx1S3, ty1S3, tx2S3, ty2S3, tx3S3, ty3S3);
    triangle(tx1S4, ty1S4, tx2S4, ty2S4, tx3S4, ty3S4);
    fill(255);
    triangle(tx1S1, ty1S1, tx2S1, ty2S1, tx3S1, ty3S1);
    triangle(tx1S5, ty1S5, tx2S5, ty2S5, tx3S5, ty3S5);
    triangle(tx1S6, ty1S6, tx2S6, ty2S6, tx3S6, ty3S6);
    break;
  case 11:
    fill(255, 0, 0);
    triangle(tx1S5, ty1S5, tx2S5, ty2S5, tx3S5, ty3S5);
    triangle(tx1S3, ty1S3, tx2S3, ty2S3, tx3S3, ty3S3);
    triangle(tx1S4, ty1S4, tx2S4, ty2S4, tx3S4, ty3S4);
    fill(255);
    triangle(tx1S2, ty1S2, tx2S2, ty2S2, tx3S2, ty3S2);
    triangle(tx1S1, ty1S1, tx2S1, ty2S1, tx3S1, ty3S1);
    triangle(tx1S6, ty1S6, tx2S6, ty2S6, tx3S6, ty3S6);
    break;
  case 12:
    fill(255, 0, 0);
    triangle(tx1S2, ty1S2, tx2S2, ty2S2, tx3S2, ty3S2);
    triangle(tx1S3, ty1S3, tx2S3, ty2S3, tx3S3, ty3S3);
    triangle(tx1S4, ty1S4, tx2S4, ty2S4, tx3S4, ty3S4);
    triangle(tx1S5, ty1S5, tx2S5, ty2S5, tx3S5, ty3S5);
    fill(255);
    triangle(tx1S1, ty1S1, tx2S1, ty2S1, tx3S1, ty3S1);
    triangle(tx1S6, ty1S6, tx2S6, ty2S6, tx3S6, ty3S6);
    break;
  }
}

void enemy(int x, int y, int dir, int attack) {

  switch(attack) {
  case 0:
    dohyo();
    break;
  case 1:
    pushMatrix();
    // negative y since the dohyo coordinates are invertet the window coordinates
    translate(x + dohyoX, -y + dohyoY); 
    rotate(radians(-dir));
    fill(enemyColor);
    ellipse(0, -200, sumoSize, sumoSize);
    popMatrix();
    break;
  case 2:
    pushMatrix();
    // negative y since the dohyo coordinates are invertet the window coordinates
    translate(x + dohyoX, -y + dohyoY); 
    rotate(radians(-dir));
    fill(enemyColor);
    ellipse(200, -200, sumoSize, sumoSize);
    popMatrix();
    break;
  case 3:
    pushMatrix();
    // negative y since the dohyo coordinates are invertet the window coordinates
    translate(x + dohyoX, -y + dohyoY); 
    rotate(radians(-dir));
    fill(enemyColor);
    ellipse(200, -100, sumoSize, sumoSize);
    popMatrix();
    break;
  case 4:
    pushMatrix();
    // negative y since the dohyo coordinates are invertet the window coordinates
    translate(x + dohyoX, -y + dohyoY); 
    rotate(radians(-dir));
    fill(enemyColor);
    ellipse(200, 100, sumoSize, sumoSize);
    popMatrix();
    break;
  case 5:
    pushMatrix();
    // negative y since the dohyo coordinates are invertet the window coordinates
    translate(x + dohyoX, -y + dohyoY); 
    rotate(radians(-dir));
    fill(enemyColor);
    ellipse(200, 200, sumoSize, sumoSize);
    popMatrix();
    break;
  case 6:
    pushMatrix();
    // negative y since the dohyo coordinates are invertet the window coordinates
    translate(x + dohyoX, -y + dohyoY); 
    rotate(radians(-dir));
    fill(enemyColor);
    ellipse(0, 200, sumoSize, sumoSize);
    popMatrix();
    break;
  case 7:
    pushMatrix();
    // negative y since the dohyo coordinates are invertet the window coordinates
    translate(x + dohyoX, -y + dohyoY); 
    rotate(radians(-dir));
    fill(enemyColor);
    ellipse(150, -150, sumoSize, sumoSize);
    popMatrix();
    break;
  case 8:
    pushMatrix();
    // negative y since the dohyo coordinates are invertet the window coordinates
    translate(x + dohyoX, -y + dohyoY); 
    rotate(radians(-dir));
    fill(enemyColor);
    ellipse(150, 0, sumoSize, sumoSize);
    popMatrix();
    break;
  case 9:
    pushMatrix();
    // negative y since the dohyo coordinates are invertet the window coordinates
    translate(x + dohyoX, -y + dohyoY); 
    rotate(radians(-dir));
    fill(enemyColor);
    ellipse(150, 150, sumoSize, sumoSize);
    popMatrix();
    break;
  case 10:
    pushMatrix();
    // negative y since the dohyo coordinates are invertet the window coordinates
    translate(x + dohyoX, -y + dohyoY); 
    rotate(radians(-dir));
    fill(enemyColor);
    ellipse(100, -50, sumoSize, sumoSize);
    popMatrix();
    break;
  case 11:
    pushMatrix();
    // negative y since the dohyo coordinates are invertet the window coordinates
    translate(x + dohyoX, -y + dohyoY); 
    rotate(radians(-dir));
    fill(enemyColor);
    ellipse(100, 50, sumoSize, sumoSize);
    popMatrix();
    break;
  case 12:
    pushMatrix();
    // negative y since the dohyo coordinates are invertet the window coordinates
    translate(x + dohyoX, -y + dohyoY); 
    rotate(radians(-dir));
    fill(enemyColor);
    ellipse(75, 0, sumoSize, sumoSize);
    popMatrix();
    break;
  }
}
