/** //<>// //<>//
 *Mini Sumo Interface
 Rev001
 
 Created by:
 Oskar Persson

For the line graph, RealtimePlotter by Sebastian Nilsson was used.
https://github.com/sebnil/RealtimePlotter

 */

// import libraries
import java.awt.Frame;
import java.awt.BorderLayout;
import controlP5.*; // http://www.sojamo.de/libraries/controlP5/
import processing.serial.*;

//Dohyo
int dohyoX = 1440;
int dohyoY = 540;
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

//Text position
int colA = 1200;
int colB = 1500;
int rowA = 60;
int rowB = 110;
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

// interface stuff
ControlP5 cp5;

// Settings for the plotter are saved in this file
JSONObject plotterConfigJSON;

// plots
int LineGraphX1 = 250;
int LineGraphY1 = 600;
Graph LineGraph = new Graph(LineGraphX1, LineGraphY1, 660, 300, color (20, 20, 200));
float[][] lineGraphValues = new float[6][100];
float[] lineGraphSampleNumbers = new float[100];
color[] graphColors = new color[6];

// helper for saving the executing path
String topSketchPath = "";

//Bluetooth
Serial serialPort;  // The serial port
String btData;
String[] nums = new String[7]; //Expecting 7 input data

// If you want to debug the plotter without using a real serial port set this to true
boolean mockupSerial = false;

// ================================================================
// ===                ---- INITIAL SETUP ----                   ===
// ================================================================

void setup() {
  frame.setTitle("Mini Sumo Interface");
  size(1920, 1080);

  // set line graph colors
  graphColors[0] = color(131, 255, 20);
  graphColors[1] = color(232, 158, 12);
  graphColors[2] = color(255, 0, 0);
  graphColors[3] = color(62, 12, 232);
  graphColors[4] = color(13, 255, 243);
  graphColors[5] = color(200, 46, 232);

  // settings save file
  topSketchPath = sketchPath();
  plotterConfigJSON = loadJSONObject(topSketchPath+"/plotter_config.json");

  // gui
  cp5 = new ControlP5(this);
  
  // init charts
  setChartSettings();
  
  // build x1 axis values for the line graph
  for (int i=0; i<lineGraphValues.length; i++) {
    for (int k=0; k<lineGraphValues[0].length; k++) {
      lineGraphValues[i][k] = 0;
      if (i==0)
        lineGraphSampleNumbers[k] = k;
    }
  }
  // start serial communication
  String serialPortName = "COM4"; //COM4 is the Bluetooth serial port on my PC, yours may be different
  
  if (!mockupSerial) {
    //String serialPortName = Serial.list()[3];
    //Open the port you are using at the rate you want:
    serialPort = new Serial(this, serialPortName, 115200);
    serialPort.bufferUntil(62); // Fills the buffer until it detects >, ASCII 62
    serialPort.clear();
  }
  else
  serialPort = null;

  // Create the font
  //printArray(PFont.list()); //prints a list of all available fonts
  PFont f = createFont("arial bold", 32);
  PFont font = createFont("arial bold",15);
  textFont(f);
  cp5.setFont(font);

  // build the gui for bottom Line Graph
  int x1 = LineGraphX1 - 240;
  int y1 = LineGraphY1 - 40;
  cp5.addTextfield("lgMaxY").setPosition(x1+160, y1-10).setText(getPlotterConfigString("lgMaxY")).setColorCaptionLabel(0).setWidth(40).setAutoClear(false).setCaptionLabel("Max");
  cp5.addTextfield("lgMinY").setPosition(x1+160, y1+350).setText(getPlotterConfigString("lgMinY")).setColorCaptionLabel(0).setWidth(40).setAutoClear(false).setCaptionLabel("Min");

  cp5.addTextlabel("label").setText("On/Off").setPosition(x1=x1-5, y1).setColor(0);
  cp5.addTextlabel("multipliers").setText("Scale").setPosition(x1=x1+53, y1).setColor(0);
  cp5.addTextfield("lgMultiplier1").setPosition(x1=x1+2, y1=y1+40).setText(getPlotterConfigString("lgMultiplier1")).setWidth(40).setAutoClear(false).setCaptionLabel("");
  cp5.addTextfield("lgMultiplier2").setPosition(x1, y1=y1+60).setText(getPlotterConfigString("lgMultiplier2")).setWidth(40).setAutoClear(false).setCaptionLabel("");
  cp5.addTextfield("lgMultiplier3").setPosition(x1, y1=y1+60).setText(getPlotterConfigString("lgMultiplier3")).setWidth(40).setAutoClear(false).setCaptionLabel("");
  cp5.addTextfield("lgMultiplier4").setPosition(x1, y1=y1+60).setText(getPlotterConfigString("lgMultiplier4")).setWidth(40).setAutoClear(false).setCaptionLabel("");
  cp5.addTextfield("lgMultiplier5").setPosition(x1, y1=y1+60).setText(getPlotterConfigString("lgMultiplier5")).setWidth(40).setAutoClear(false).setCaptionLabel("");
  cp5.addTextfield("lgMultiplier6").setPosition(x1, y1=y1+60).setText(getPlotterConfigString("lgMultiplier6")).setWidth(40).setAutoClear(false).setCaptionLabel("");
  cp5.addToggle("lgVisible1").setPosition(x1=x1-50, y1=y1-300).setValue(int(getPlotterConfigString("lgVisible1"))).setColorCaptionLabel(0).
  setMode(ControlP5.SWITCH).setColorActive(graphColors[0]).setCaptionLabel("ANGLE");
  cp5.addToggle("lgVisible2").setPosition(x1, y1=y1+60).setValue(int(getPlotterConfigString("lgVisible2"))).setColorCaptionLabel(0).
  setMode(ControlP5.SWITCH).setColorActive(graphColors[1]).setCaptionLabel("ATTACK ZONE");
  cp5.addToggle("lgVisible3").setPosition(x1, y1=y1+60).setValue(int(getPlotterConfigString("lgVisible3"))).setColorCaptionLabel(0).
  setMode(ControlP5.SWITCH).setColorActive(graphColors[2]).setCaptionLabel("POS X");
  cp5.addToggle("lgVisible4").setPosition(x1, y1=y1+60).setValue(int(getPlotterConfigString("lgVisible4"))).setColorCaptionLabel(0).
  setMode(ControlP5.SWITCH).setColorActive(graphColors[3]).setCaptionLabel("POS Y");
  cp5.addToggle("lgVisible5").setPosition(x1, y1=y1+60).setValue(int(getPlotterConfigString("lgVisible5"))).setColorCaptionLabel(0).
  setMode(ControlP5.SWITCH).setColorActive(graphColors[4]).setCaptionLabel("SPEED LEFT");
  cp5.addToggle("lgVisible6").setPosition(x1, y1=y1+60).setValue(int(getPlotterConfigString("lgVisible6"))).setColorCaptionLabel(0).
  setMode(ControlP5.SWITCH).setColorActive(graphColors[5]).setCaptionLabel("SPEED RIGHT");
}

// ================================================================
// ===                    ---- MAIN ----                        ===
// ================================================================

byte[] inBuffer = new byte[100]; // holds serial message
int i = 0; // loop variable
void draw() {
  background(123);
  line(960, 0, 960, height);
  dohyo();

  //Gives the the line graph fake values
  if (mockupSerial){
    btData = mockupSerialFunction();
    nums = split(btData, ",");
  }
  // count number of line graphs to hide
  int numberOfInvisibleLineGraphs = 0;
  for (i=0; i<6; i++) {
    if (int(getPlotterConfigString("lgVisible"+(i+1))) == 0) {
      numberOfInvisibleLineGraphs++;
    }
  }

  // build the arrays for line graphs
  int barchartIndex = 0;
  for (i=0; i<nums.length; i++) {

    // update line graph
    try {
      if (i<lineGraphValues.length) {
        for (int k=0; k<lineGraphValues[i].length-1; k++) {
          lineGraphValues[i][k] = lineGraphValues[i][k+1];
        }

        lineGraphValues[i][lineGraphValues[i].length-1] = float(nums[i])*float(getPlotterConfigString("lgMultiplier"+(i+1)));
      }
    }
    catch (Exception e) {
    }
  }

  // draw the line graphs
  LineGraph.DrawAxis();
  for (int i=0;i<lineGraphValues.length; i++) {
    LineGraph.GraphColor = graphColors[i];
    if (int(getPlotterConfigString("lgVisible"+(i+1))) == 1)
      LineGraph.LineGraph(lineGraphSampleNumbers, lineGraphValues[i]);
  }


  enemy(posX, posY, angle, attackZone);
  miniSumo(posX, posY, angle);

  //Debugg circle
  fill(200,102,0);
  ellipse(250,600,10,10);

  showData();
  sumoSensors(attackZone);
 // showParsedData();
}

void serialEvent(Serial p) { 
  btData = p.readString();
  // split the string at delimiter (,)
  nums = split(btData, ",");
  convertBtData(nums);
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
  textSize(32);
  text("Angle: " + angle, colA, rowA);
  fill(0);
  text("Speed: " + speed, colA, rowB);
  fill(0);
  text("PosX: " + posX, colB, rowA);
  fill(0);
  text("PosY: " + posY, colB, rowB);
}

//Draws the mini sumo inside the dohyo att coordinates x1,y1
void miniSumo(int x1, int y1, int dir) {
  stroke(0);
  strokeWeight(1);
  pushMatrix();
  // negative y1 since the dohyo coordinates are invertet the window coordinates
  translate(x1 + dohyoX, -y1 + dohyoY); 
  rotate(radians(-dir));
  rectMode(CENTER);
  fill(sumoColor);
  rect(0, 0, sumoSize, sumoSize);
  fill(dirColor);
  triangle(0, -dirSize/2, dirSize, 0, 0, dirSize/2);
  popMatrix();
}

// called each time the chart settings are changed by the user 
void setChartSettings() {
  LineGraph.xLabel=" Samples ";
  LineGraph.yLabel="Value";
  LineGraph.Title="";  
  LineGraph.xDiv=20;  
  LineGraph.xMax=0; 
  LineGraph.xMin=-100;  
  LineGraph.yMax=int(getPlotterConfigString("lgMaxY")); 
  LineGraph.yMin=int(getPlotterConfigString("lgMinY"));
}

// handle gui actions
void controlEvent(ControlEvent theEvent) {
  if (theEvent.isAssignableFrom(Textfield.class) || theEvent.isAssignableFrom(Toggle.class) || theEvent.isAssignableFrom(Button.class)) {
    String parameter = theEvent.getName();
    String value = "";
    if (theEvent.isAssignableFrom(Textfield.class))
      value = theEvent.getStringValue();
    else if (theEvent.isAssignableFrom(Toggle.class) || theEvent.isAssignableFrom(Button.class))
      value = theEvent.getValue()+"";

    plotterConfigJSON.setString(parameter, value);
    saveJSONObject(plotterConfigJSON, topSketchPath+"/plotter_config.json");
  }
  setChartSettings();
}

// get gui settings from settings file
String getPlotterConfigString(String id) {
  String r = "";
  try {
    r = plotterConfigJSON.getString(id);
  } 
  catch (Exception e) {
    r = "";
  }
  return r;
}


//Draws a sumo in the bottom left that indicates which sensors that are triggered
void sumoSensors (int zone) {
  rectMode(CENTER);
  fill(sumoSensorColor);
  stroke(0);
  strokeWeight(1);
  float sensorPosX = 0.25 * width;
  float sensorPosY = 0.35 * height;

  rect(sensorPosX, sensorPosY, sumoSensorSize, sumoSensorSize);

  //draws the sensor vision cones
  float tx1S1 = sensorPosX - sumoSensorSize/2;
  float ty1S1 = sensorPosY;
  float tx2S1 = tx1S1 - sensorLength;
  float ty2S1 = ty1S1 + sensorWidth/2;
  float tx3S1 = tx2S1;
  float ty3S1 = ty2S1 - sensorWidth;

  float tx1S2 = sensorPosX - 0.4 * sumoSensorSize;
  float ty1S2 = sensorPosY - sumoSensorSize/2;
  float tx2S2 = tx1S2 - sensorWidth/2;
  float ty2S2 = ty1S2 - sensorLength;
  float tx3S2 = tx2S2 + sensorWidth;
  float ty3S2 = ty2S2;

  float tx1S3 = sensorPosX - 0.1 * sumoSensorSize;
  float ty1S3 = sensorPosY - sumoSensorSize/2;
  float tx2S3 = tx1S3 + 0.7071 * (sensorLength + 80);
  float ty2S3 = ty1S3 - 0.7071 * (sensorLength + 80);
  float tx3S3 = tx2S3 + sensorWidth;
  float ty3S3 = ty2S3;

  float tx1S4 = sensorPosX + 0.1 * sumoSensorSize;
  float ty1S4 = sensorPosY - sumoSensorSize/2;
  float tx2S4 = tx1S4 - 0.7071 * (sensorLength + 80);
  float ty2S4 = ty1S4 - 0.7071 * (sensorLength + 80);
  float tx3S4 = tx2S4 - sensorWidth;
  float ty3S4 = ty2S4;

  float tx1S5 = sensorPosX + 0.4 * sumoSensorSize;
  float ty1S5 = sensorPosY - sumoSensorSize/2;
  float tx2S5 = tx1S5 - sensorWidth/2;
  float ty2S5 = ty1S5 - sensorLength;
  float tx3S5 = tx2S5 + sensorWidth;
  float ty3S5 = ty2S5;  

  float tx1S6 = sensorPosX + sumoSensorSize/2;
  float ty1S6 = sensorPosY;
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

void enemy(int x1, int y1, int dir, int attack) {
  stroke(0);
  strokeWeight(1);
  switch(attack) {
  case 0:
    dohyo();
    break;
  case 1:
    pushMatrix();
    // negative y1 since the dohyo coordinates are invertet the window coordinates
    translate(x1 + dohyoX, -y1 + dohyoY); 
    rotate(radians(-dir));
    fill(enemyColor);
    ellipse(0, -200, sumoSize, sumoSize);
    popMatrix();
    break;
  case 2:
    pushMatrix();
    // negative y1 since the dohyo coordinates are invertet the window coordinates
    translate(x1 + dohyoX, -y1 + dohyoY); 
    rotate(radians(-dir));
    fill(enemyColor);
    ellipse(200, -200, sumoSize, sumoSize);
    popMatrix();
    break;
  case 3:
    pushMatrix();
    // negative y1 since the dohyo coordinates are invertet the window coordinates
    translate(x1 + dohyoX, -y1 + dohyoY); 
    rotate(radians(-dir));
    fill(enemyColor);
    ellipse(200, -100, sumoSize, sumoSize);
    popMatrix();
    break;
  case 4:
    pushMatrix();
    // negative y1 since the dohyo coordinates are invertet the window coordinates
    translate(x1 + dohyoX, -y1 + dohyoY); 
    rotate(radians(-dir));
    fill(enemyColor);
    ellipse(200, 100, sumoSize, sumoSize);
    popMatrix();
    break;
  case 5:
    pushMatrix();
    // negative y1 since the dohyo coordinates are invertet the window coordinates
    translate(x1 + dohyoX, -y1 + dohyoY); 
    rotate(radians(-dir));
    fill(enemyColor);
    ellipse(200, 200, sumoSize, sumoSize);
    popMatrix();
    break;
  case 6:
    pushMatrix();
    // negative y1 since the dohyo coordinates are invertet the window coordinates
    translate(x1 + dohyoX, -y1 + dohyoY); 
    rotate(radians(-dir));
    fill(enemyColor);
    ellipse(0, 200, sumoSize, sumoSize);
    popMatrix();
    break;
  case 7:
    pushMatrix();
    // negative y1 since the dohyo coordinates are invertet the window coordinates
    translate(x1 + dohyoX, -y1 + dohyoY); 
    rotate(radians(-dir));
    fill(enemyColor);
    ellipse(150, -150, sumoSize, sumoSize);
    popMatrix();
    break;
  case 8:
    pushMatrix();
    // negative y1 since the dohyo coordinates are invertet the window coordinates
    translate(x1 + dohyoX, -y1 + dohyoY); 
    rotate(radians(-dir));
    fill(enemyColor);
    ellipse(150, 0, sumoSize, sumoSize);
    popMatrix();
    break;
  case 9:
    pushMatrix();
    // negative y1 since the dohyo coordinates are invertet the window coordinates
    translate(x1 + dohyoX, -y1 + dohyoY); 
    rotate(radians(-dir));
    fill(enemyColor);
    ellipse(150, 150, sumoSize, sumoSize);
    popMatrix();
    break;
  case 10:
    pushMatrix();
    // negative y1 since the dohyo coordinates are invertet the window coordinates
    translate(x1 + dohyoX, -y1 + dohyoY); 
    rotate(radians(-dir));
    fill(enemyColor);
    ellipse(100, -50, sumoSize, sumoSize);
    popMatrix();
    break;
  case 11:
    pushMatrix();
    // negative y1 since the dohyo coordinates are invertet the window coordinates
    translate(x1 + dohyoX, -y1 + dohyoY); 
    rotate(radians(-dir));
    fill(enemyColor);
    ellipse(100, 50, sumoSize, sumoSize);
    popMatrix();
    break;
  case 12:
    pushMatrix();
    // negative y1 since the dohyo coordinates are invertet the window coordinates
    translate(x1 + dohyoX, -y1 + dohyoY); 
    rotate(radians(-dir));
    fill(enemyColor);
    ellipse(75, 0, sumoSize, sumoSize);
    popMatrix();
    break;
  }
}
