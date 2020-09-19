import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import java.awt.Frame; 
import java.awt.BorderLayout; 
import controlP5.*; 
import processing.serial.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class MiniSumoInterface extends PApplet {

/** //<>// //<>//
 *Mini Sumo Interface
 Rev001
 
 Created by:
 Oskar Persson

For the line graph, RealtimePlotter by Sebastian Nilsson was used.
https://github.com/sebnil/RealtimePlotter

 */

// import libraries


 // http://www.sojamo.de/libraries/controlP5/


//Dohyo
int dohyoX = 1440;
int dohyoY = 540;
int dohyoSize = 770;

//Mini Sumo
int sumoColor = color(130);
int sumoSensorColor = color(30);
int dirColor = color(255, 0, 0);
int enemyColor = color(255, 0, 0);
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
int speedLeft = 0;
int speedRight = 0;
int posX = 185;
int posY = 0;
int attackZone = 0;
int edgeDetect = 0;
int totalDistX = 0;
int edgeTurnAngle = 0;
int pidOutput = 0;

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
int[] graphColors = new int[6];

// helper for saving the executing path
String topSketchPath = "";

//Bluetooth
Serial serialPort;  // The serial port
String btData;
String[] parsedBTData = new String[8]; //Expecting 8 input data
String[] nums = new String[6]; //6 lines in line graph

// If you want to debug the plotter without using a real serial port set this to true
boolean mockupSerial = false;

// ================================================================
// ===                ---- INITIAL SETUP ----                   ===
// ================================================================

public void setup() {
  frame.setTitle("Mini Sumo Interface");
  

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
  cp5.addToggle("lgVisible1").setPosition(x1=x1-50, y1=y1-300).setValue(PApplet.parseInt(getPlotterConfigString("lgVisible1"))).setColorCaptionLabel(0).
  setMode(ControlP5.SWITCH).setColorActive(graphColors[0]).setCaptionLabel("SPEED LEFT");
  cp5.addToggle("lgVisible2").setPosition(x1, y1=y1+60).setValue(PApplet.parseInt(getPlotterConfigString("lgVisible2"))).setColorCaptionLabel(0).
  setMode(ControlP5.SWITCH).setColorActive(graphColors[1]).setCaptionLabel("SPEED RIGHT");
  cp5.addToggle("lgVisible3").setPosition(x1, y1=y1+60).setValue(PApplet.parseInt(getPlotterConfigString("lgVisible3"))).setColorCaptionLabel(0).
  setMode(ControlP5.SWITCH).setColorActive(graphColors[2]).setCaptionLabel("PID OUTPUT");
  cp5.addToggle("lgVisible4").setPosition(x1, y1=y1+60).setValue(PApplet.parseInt(getPlotterConfigString("lgVisible4"))).setColorCaptionLabel(0).
  setMode(ControlP5.SWITCH).setColorActive(graphColors[3]).setCaptionLabel("SIGNAL 1");
  cp5.addToggle("lgVisible5").setPosition(x1, y1=y1+60).setValue(PApplet.parseInt(getPlotterConfigString("lgVisible5"))).setColorCaptionLabel(0).
  setMode(ControlP5.SWITCH).setColorActive(graphColors[4]).setCaptionLabel("SIGNAL 2");
  cp5.addToggle("lgVisible6").setPosition(x1, y1=y1+60).setValue(PApplet.parseInt(getPlotterConfigString("lgVisible6"))).setColorCaptionLabel(0).
  setMode(ControlP5.SWITCH).setColorActive(graphColors[5]).setCaptionLabel("SIGNAL 3");
}

// ================================================================
// ===                    ---- MAIN ----                        ===
// ================================================================

//byte[] inBuffer = new byte[100]; // holds serial message
int i = 0; // loop variable
public void draw() {
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
    if (PApplet.parseInt(getPlotterConfigString("lgVisible"+(i+1))) == 0) {
      numberOfInvisibleLineGraphs++;
    }
  }

  // build the arrays for line graphs
  for (i=0; i<nums.length; i++) {

    // update line graph
    try {
      if (i<lineGraphValues.length) {
        for (int k=0; k<lineGraphValues[i].length-1; k++) {
          lineGraphValues[i][k] = lineGraphValues[i][k+1];
        }

        lineGraphValues[i][lineGraphValues[i].length-1] = PApplet.parseFloat(nums[i])*PApplet.parseFloat(getPlotterConfigString("lgMultiplier"+(i+1)));
      }
    }
    catch (Exception e) {
    }
  }

  // draw the line graphs
  LineGraph.DrawAxis();
  for (int i=0;i<lineGraphValues.length; i++) {
    LineGraph.GraphColor = graphColors[i];
    if (PApplet.parseInt(getPlotterConfigString("lgVisible"+(i+1))) == 1)
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

public void serialEvent(Serial p) { 
  btData = p.readString();
  // split the string at delimiter (,)
  parsedBTData = split(btData, ",");
  convertBtData(parsedBTData);
  nums[0] = parsedBTData[4];  //speed left
  nums[1] = parsedBTData[5];  //speed right
  nums[2] = parsedBTData[7];  //pidoutput
}

//Draws the Dohyo
public void dohyo() {
  stroke(0);
  strokeWeight(4);
  fill(255);
  ellipse(dohyoX, dohyoY, dohyoSize, dohyoSize);
  fill(0);
  ellipse(dohyoX, dohyoY, dohyoSize - 50, dohyoSize - 50);
}

//Prints the input in the top left
public void showData() {
  textAlign(LEFT);
  fill(0);
  textSize(32);
  text("Angle: " + angle, colA, rowA);
  fill(0);
  text("Turn Angle: " + edgeTurnAngle, colA, rowB);
  fill(0);
  text("PosX: " + posX, colB, rowA);
  fill(0);
  text("PosY: " + posY, colB, rowB);
}

//Draws the mini sumo inside the dohyo att coordinates x1,y1
public void miniSumo(int x1, int y1, int dir) {
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
public void setChartSettings() {
  LineGraph.xLabel=" Samples ";
  LineGraph.yLabel="Value";
  LineGraph.Title="";  
  LineGraph.xDiv=20;  
  LineGraph.xMax=0; 
  LineGraph.xMin=-100;  
  LineGraph.yMax=PApplet.parseInt(getPlotterConfigString("lgMaxY")); 
  LineGraph.yMin=PApplet.parseInt(getPlotterConfigString("lgMinY"));
}

// handle gui actions
public void controlEvent(ControlEvent theEvent) {
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
public String getPlotterConfigString(String id) {
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
public void sumoSensors (int zone) {
  rectMode(CENTER);
  fill(sumoSensorColor);
  stroke(0);
  strokeWeight(1);
  float sensorPosX = 0.25f * width;
  float sensorPosY = 0.35f * height;

  rect(sensorPosX, sensorPosY, sumoSensorSize, sumoSensorSize);

  //draws the sensor vision cones
  float tx1S1 = sensorPosX - sumoSensorSize/2;
  float ty1S1 = sensorPosY;
  float tx2S1 = tx1S1 - sensorLength;
  float ty2S1 = ty1S1 + sensorWidth/2;
  float tx3S1 = tx2S1;
  float ty3S1 = ty2S1 - sensorWidth;

  float tx1S2 = sensorPosX - 0.4f * sumoSensorSize;
  float ty1S2 = sensorPosY - sumoSensorSize/2;
  float tx2S2 = tx1S2 - sensorWidth/2;
  float ty2S2 = ty1S2 - sensorLength;
  float tx3S2 = tx2S2 + sensorWidth;
  float ty3S2 = ty2S2;

  float tx1S3 = sensorPosX - 0.1f * sumoSensorSize;
  float ty1S3 = sensorPosY - sumoSensorSize/2;
  float tx2S3 = tx1S3 + 0.7071f * (sensorLength + 80);
  float ty2S3 = ty1S3 - 0.7071f * (sensorLength + 80);
  float tx3S3 = tx2S3 + sensorWidth;
  float ty3S3 = ty2S3;

  float tx1S4 = sensorPosX + 0.1f * sumoSensorSize;
  float ty1S4 = sensorPosY - sumoSensorSize/2;
  float tx2S4 = tx1S4 - 0.7071f * (sensorLength + 80);
  float ty2S4 = ty1S4 - 0.7071f * (sensorLength + 80);
  float tx3S4 = tx2S4 - sensorWidth;
  float ty3S4 = ty2S4;

  float tx1S5 = sensorPosX + 0.4f * sumoSensorSize;
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

public void enemy(int x1, int y1, int dir, int attack) {
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

public void convertBtData(String[] input){
  angle = PApplet.parseInt(input[0]);
  attackZone = PApplet.parseInt(input[1]);
  posX = PApplet.parseInt(input[2]);
  posY = PApplet.parseInt(input[3]);
  speedLeft = PApplet.parseInt(input[4]);
  speedRight = PApplet.parseInt(input[5]);
  edgeTurnAngle = PApplet.parseInt(input[6]);
  pidOutput = PApplet.parseInt(input[7]);
}

public void showParsedData() {
    print("angle ");
    println(angle);
    print("attackZone ");
    println(attackZone);
    print("posX ");
    println(posX);
    print("posY ");
    println(posY);
    print("speedLeft ");
    println(speedLeft);
    print("speedRight ");
    println(speedRight);
    print("edgeTurnAngle ");
    println(edgeTurnAngle);
    print("pidOutput ");
    println(pidOutput);
}
  
/*   =================================================================================       
     The Graph class contains functions and variables that have been created to draw 
     graphs. Here is a quick list of functions within the graph class:
          
       Graph(int x, int y, int w, int h,color k)
       DrawAxis()
       Bar([])
       smoothLine([][])
       DotGraph([][])
       LineGraph([][]) 
     
     =================================================================================*/   

    
    class Graph 
    {
      
      boolean Dot=true;            // Draw dots at each data point if true
      boolean RightAxis;            // Draw the next graph using the right axis if true
      boolean ErrorFlag=false;      // If the time array isn't in ascending order, make true  
      boolean ShowMouseLines=true;  // Draw lines and give values of the mouse position
    
      int     xDiv=5,yDiv=5;            // Number of sub divisions
      int     xPos,yPos;            // location of the top left corner of the graph  
      int     Width,Height;         // Width and height of the graph
    

      int   GraphColor;
      int   BackgroundColor=color(255);  
      int   StrokeColor=color(180);     
      
      String  Title="Title";          // Default titles
      String  xLabel="x - Label";
      String  yLabel="y - Label";

      float   yMax=1024, yMin=0;      // Default axis dimensions
      float   xMax=10, xMin=0;
      float   yMaxRight=1024,yMinRight=0;
  
      PFont   Font;                   // Selected font used for text 
      
  //    int Peakcounter=0,nPeakcounter=0;
     
      Graph(int x, int y, int w, int h,int k) {  // The main declaration function
        xPos = x;
        yPos = y;
        Width = w;
        Height = h;
        GraphColor = k;
        
      }
    
     
       public void DrawAxis(){
       
   /*  =========================================================================================
        Main axes Lines, Graph Labels, Graph Background
       ==========================================================================================  */
    
        fill(BackgroundColor); color(0);stroke(StrokeColor);strokeWeight(1);
        int t=60;
       
        rect(xPos+Width/2-50,yPos+Height/2,Width+t*2.5f,Height+t*2);            // outline
        textAlign(CENTER);textSize(18);
        float c=textWidth(Title);
        fill(BackgroundColor); color(0);stroke(0);strokeWeight(1);
        //rect(xPos+Width/2-c/2,yPos-35,c,0);                         // Heading Rectangle  
        //rect(xPos+35,yPos-35,500,500);                         // Heading Rectangle  

        fill(0);
        text(Title,xPos+Width/2,yPos-37);                            // Heading Title
        textAlign(CENTER);textSize(14);
        text(xLabel,xPos+Width/2,yPos+Height+t/1.5f);                     // x-axis Label 
        
        rotate(-PI/2);                                               // rotate -90 degrees
        text(yLabel,-yPos-Height/2,xPos-t*1.6f+50);                   // y-axis Label  
        rotate(PI/2);                                                // rotate back
        
        textSize(10); noFill(); stroke(0); smooth();strokeWeight(1);
          //Edges
          line(xPos-3,yPos+Height,xPos-3,yPos);                        // y-axis line 
          line(xPos-3,yPos+Height,xPos+Width+5,yPos+Height);           // x-axis line 
          
           stroke(200);
          if(yMin<0){
                    line(xPos-7,                                       // zero line 
                         yPos+Height-(abs(yMin)/(yMax-yMin))*Height,   // 
                         xPos+Width,
                         yPos+Height-(abs(yMin)/(yMax-yMin))*Height
                         );
          
                    
          }
          
          if(RightAxis){                                       // Right-axis line   
              stroke(0);
              line(xPos+Width+3,yPos+Height,xPos+Width+3,yPos);
            }
            
           /*  =========================================================================================
                Sub-devisions for both axes, left and right
               ==========================================================================================  */
            
            stroke(0);
            
           for(int x=0; x<=xDiv; x++){
       
            /*  =========================================================================================
                  x-axis
                ==========================================================================================  */
             
            line(PApplet.parseFloat(x)/xDiv*Width+xPos-3,yPos+Height,       //  x-axis Sub devisions    
                 PApplet.parseFloat(x)/xDiv*Width+xPos-3,yPos+Height+5);     
                 
            textSize(10);                                      // x-axis Labels
            String xAxis=str(xMin+PApplet.parseFloat(x)/xDiv*(xMax-xMin));  // the only way to get a specific number of decimals 
            String[] xAxisMS=split(xAxis,'.');                 // is to split the float into strings 
            text(xAxisMS[0]+"."+xAxisMS[1].charAt(0),          // ...
                 PApplet.parseFloat(x)/xDiv*Width+xPos-3,yPos+Height+15);   // x-axis Labels
          }
          
          
           /*  =========================================================================================
                 left y-axis
               ==========================================================================================  */
          
          for(int y=0; y<=yDiv; y++){
            line(xPos-3,PApplet.parseFloat(y)/yDiv*Height+yPos,                // ...
                  xPos-7,PApplet.parseFloat(y)/yDiv*Height+yPos);              // y-axis lines 
            
            textAlign(RIGHT);fill(20);
            
            String yAxis=str(yMin+PApplet.parseFloat(y)/yDiv*(yMax-yMin));     // Make y Label a string
            String[] yAxisMS=split(yAxis,'.');                    // Split string
           
            text(yAxisMS[0]+"."+yAxisMS[1].charAt(0),             // ... 
                 xPos-15,PApplet.parseFloat(yDiv-y)/yDiv*Height+yPos+3);       // y-axis Labels 
                        
                        
            /*  =========================================================================================
                 right y-axis
                ==========================================================================================  */
            
            if(RightAxis){
             
              color(GraphColor); stroke(GraphColor);fill(20);
            
              line(xPos+Width+3,PApplet.parseFloat(y)/yDiv*Height+yPos,             // ...
                   xPos+Width+7,PApplet.parseFloat(y)/yDiv*Height+yPos);            // Right Y axis sub devisions
                   
              textAlign(LEFT); 
            
              String yAxisRight=str(yMinRight+PApplet.parseFloat(y)/                // ...
                                yDiv*(yMaxRight-yMinRight));           // convert axis values into string
              String[] yAxisRightMS=split(yAxisRight,'.');             // 
           
               text(yAxisRightMS[0]+"."+yAxisRightMS[1].charAt(0),     // Right Y axis text
                    xPos+Width+15,PApplet.parseFloat(yDiv-y)/yDiv*Height+yPos+3);   // it's x,y location
            
              noFill();
            }stroke(0);
            
          
          }
          
 
      }
      
      
   /*  =========================================================================================
       Bar graph
       ==========================================================================================  */   
      
      public void Bar(float[] a ,int from, int to) {
        
         
          stroke(GraphColor);
          fill(GraphColor);
          
          if(from<0){                                      // If the From or To value is out of bounds 
           for (int x=0; x<a.length; x++){                 // of the array, adjust them 
               rect(PApplet.parseInt(xPos+x*PApplet.parseFloat(Width)/(a.length)),
                    yPos+Height-2,
                    Width/a.length-2,
                    -a[x]/(yMax-yMin)*Height);
                 }
          }
          
          else {
          for (int x=from; x<to; x++){
            
            rect(PApplet.parseInt(xPos+(x-from)*PApplet.parseFloat(Width)/(to-from)),
                     yPos+Height-2,
                     Width/(to-from)-2,
                     -a[x]/(yMax-yMin)*Height);
                     
    
          }
          }
          
      }
  public void Bar(float[] a ) {
  
              stroke(GraphColor);
          fill(GraphColor);
    
  for (int x=0; x<a.length; x++){                 // of the array, adjust them 
               rect(PApplet.parseInt(xPos+x*PApplet.parseFloat(Width)/(a.length)),
                    yPos+Height-2,
                    Width/a.length-2,
                    -a[x]/(yMax-yMin)*Height);
                 }
          }
  
  
   /*  =========================================================================================
       Dot graph
       ==========================================================================================  */   
       
        public void DotGraph(float[] x ,float[] y) {
          
         for (int i=0; i<x.length; i++){
                    strokeWeight(2);stroke(GraphColor);noFill();smooth();
           ellipse(
                   xPos+(x[i]-x[0])/(x[x.length-1]-x[0])*Width,
                   yPos+Height-(y[i]/(yMax-yMin)*Height)+(yMin)/(yMax-yMin)*Height,
                   2,2
                   );
         }
                             
      }
      
   /*  =========================================================================================
       Streight line graph 
       ==========================================================================================  */
       
      public void LineGraph(float[] x ,float[] y) {
          
         for (int i=0; i<(x.length-1); i++){
                    strokeWeight(2);stroke(GraphColor);noFill();smooth();
           line(xPos+(x[i]-x[0])/(x[x.length-1]-x[0])*Width,
                                            yPos+Height-(y[i]/(yMax-yMin)*Height)+(yMin)/(yMax-yMin)*Height,
                                            xPos+(x[i+1]-x[0])/(x[x.length-1]-x[0])*Width,
                                            yPos+Height-(y[i+1]/(yMax-yMin)*Height)+(yMin)/(yMax-yMin)*Height);
         }
                             
      }
      
      /*  =========================================================================================
             smoothLine
          ==========================================================================================  */
    
      public void smoothLine(float[] x ,float[] y) {
         
        float tempyMax=yMax, tempyMin=yMin;
        
        if(RightAxis){yMax=yMaxRight;yMin=yMinRight;} 
         
        int counter=0;
        int xlocation=0,ylocation=0;
         
//         if(!ErrorFlag |true ){    // sort out later!
          
          beginShape(); strokeWeight(2);stroke(GraphColor);noFill();smooth();
         
            for (int i=0; i<x.length; i++){
              
           /* ===========================================================================
               Check for errors-> Make sure time array doesn't decrease (go back in time) 
              ===========================================================================*/
              if(i<x.length-1){
                if(x[i]>x[i+1]){
                   
                  ErrorFlag=true;
                
                }
              }
         
         /* =================================================================================       
             First and last bits can't be part of the curve, no points before first bit, 
             none after last bit. So a streight line is drawn instead   
            ================================================================================= */ 

              if(i==0 || i==x.length-2)line(xPos+(x[i]-x[0])/(x[x.length-1]-x[0])*Width,
                                            yPos+Height-(y[i]/(yMax-yMin)*Height)+(yMin)/(yMax-yMin)*Height,
                                            xPos+(x[i+1]-x[0])/(x[x.length-1]-x[0])*Width,
                                            yPos+Height-(y[i+1]/(yMax-yMin)*Height)+(yMin)/(yMax-yMin)*Height);
                                            
          /* =================================================================================       
              For the rest of the array a curve (spline curve) can be created making the graph 
              smooth.     
             ================================================================================= */ 
                            
              curveVertex( xPos+(x[i]-x[0])/(x[x.length-1]-x[0])*Width,
                           yPos+Height-(y[i]/(yMax-yMin)*Height)+(yMin)/(yMax-yMin)*Height);
                           
           /* =================================================================================       
              If the Dot option is true, Place a dot at each data point.  
             ================================================================================= */    
           
             if(Dot)ellipse(
                             xPos+(x[i]-x[0])/(x[x.length-1]-x[0])*Width,
                             yPos+Height-(y[i]/(yMax-yMin)*Height)+(yMin)/(yMax-yMin)*Height,
                             2,2
                             );
                             
         /* =================================================================================       
             Highlights points closest to Mouse X position   
            =================================================================================*/ 
                          
              if( abs(mouseX-(xPos+(x[i]-x[0])/(x[x.length-1]-x[0])*Width))<5 ){
                
                 
                  float yLinePosition = yPos+Height-(y[i]/(yMax-yMin)*Height)+(yMin)/(yMax-yMin)*Height;
                  float xLinePosition = xPos+(x[i]-x[0])/(x[x.length-1]-x[0])*Width;
                  strokeWeight(1);stroke(240);
                 // line(xPos,yLinePosition,xPos+Width,yLinePosition);
                  strokeWeight(2);stroke(GraphColor);
                  
                  ellipse(xLinePosition,yLinePosition,4,4);
              }
              
     
              
            }  
       
          endShape(); 
          yMax=tempyMax; yMin=tempyMin;
                float xAxisTitleWidth=textWidth(str(map(xlocation,xPos,xPos+Width,x[0],x[x.length-1])));
          
           
       if((mouseX>xPos&mouseX<(xPos+Width))&(mouseY>yPos&mouseY<(yPos+Height))){   
        if(ShowMouseLines){
              // if(mouseX<xPos)xlocation=xPos;
            if(mouseX>xPos+Width)xlocation=xPos+Width;
            else xlocation=mouseX;
            stroke(200); strokeWeight(0.5f);fill(255);color(50);
            // Rectangle and x position
            line(xlocation,yPos,xlocation,yPos+Height);
            rect(xlocation-xAxisTitleWidth/2-10,yPos+Height-16,xAxisTitleWidth+20,12);
            
            textAlign(CENTER); fill(160);
            text(map(xlocation,xPos,xPos+Width,x[0],x[x.length-1]),xlocation,yPos+Height-6);
            
           // if(mouseY<yPos)ylocation=yPos;
             if(mouseY>yPos+Height)ylocation=yPos+Height;
            else ylocation=mouseY;
          
           // Rectangle and y position
            stroke(200); strokeWeight(0.5f);fill(255);color(50);
            
            line(xPos,ylocation,xPos+Width,ylocation);
             int yAxisTitleWidth=PApplet.parseInt(textWidth(str(map(ylocation,yPos,yPos+Height,y[0],y[y.length-1]))) );
            rect(xPos-15+3,ylocation-6, -60 ,12);
            
            textAlign(RIGHT); fill(GraphColor);//StrokeColor
          //    text(map(ylocation,yPos+Height,yPos,yMin,yMax),xPos+Width+3,yPos+Height+4);
            text(map(ylocation,yPos+Height,yPos,yMin,yMax),xPos -15,ylocation+4);
           if(RightAxis){ 
                          
                           stroke(200); strokeWeight(0.5f);fill(255);color(50);
                           
                           rect(xPos+Width+15-3,ylocation-6, 60 ,12);  
                            textAlign(LEFT); fill(160);
                           text(map(ylocation,yPos+Height,yPos,yMinRight,yMaxRight),xPos+Width+15,ylocation+4);
           }
            noStroke();noFill();
         }
       }
            
   
      }

       
          public void smoothLine(float[] x ,float[] y, float[] z, float[] a ) {
           GraphColor=color(188,53,53);
            smoothLine(x ,y);
           GraphColor=color(193-100,216-100,16);
           smoothLine(z ,a);
   
       }
       
       
       
    }
    
 
// If you want to debug the plotter without using a real serial port

int mockupValue = 0;
int mockupDirection = 10;
public String mockupSerialFunction() {
  mockupValue = (mockupValue + mockupDirection);
  if (mockupValue > 100)
    mockupDirection = -10;
  else if (mockupValue < -100)
    mockupDirection = 10;
  String r = "";
  for (int i = 0; i<6; i++) {
    switch (i) {
    case 0:
      r += mockupValue+",";
      break;
    case 1:
      r += 100*cos(mockupValue*(2*3.14f)/1000)+",";
      break;
    case 2:
      r += mockupValue/4+",";
      break;
    case 3:
      r += mockupValue/8+",";
      break;
    case 4:
      r += mockupValue/16+",";
      break;
    case 5:
      r += mockupValue/32+",";
      break;
    }
    if (i < 7)
      r += '\r';
  }
  delay(10);
  return r;
}
  public void settings() {  size(1920, 1080); }
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "MiniSumoInterface" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
