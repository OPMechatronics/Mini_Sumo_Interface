
void convertBtData(String[] input){
  angle = int(input[0]);
  attackZone = int(input[1]);
  posX = int(input[2]);
  posY = int(input[3]);
  speed = int(input[4]);
  totalDistX = int(input[5]);
  edgeTurnAngle = int(input[6]);
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
    print("speed ");
    println(speed);
    print("totalDistX ");
    println(totalDistX);
    print("edgeTurnAngle ");
    println(edgeTurnAngle);
}
