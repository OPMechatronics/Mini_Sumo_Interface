
void convertBtData(String[] input){
  angle = int(input[0]);
  attackZone = int(input[1]);
  posX = int(input[2]);
  posY = int(input[3]);
  speedLeft = int(input[4]);
  speedRight = int(input[5]);
  edgeTurnAngle = int(input[6]);
  pidOutput = int(input[7]);
}

void showParsedData() {
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
