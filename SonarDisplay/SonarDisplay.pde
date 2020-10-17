import processing.serial.*;

// Color Constants
final color GREY = color(65);
final color DARK_GREY = color(32, 32, 32);
final color GREEN = color(0, 255, 0);
final color WHITE = color(255, 255, 255);
final color YELLOW = color(255, 255, 0);
final color TEXT_GREEN = color(0, 300, 0);
final color SWEEP_GREEN = color(0, 153, 0, 125);

// Other Constants
final int MIN_ANGLE = 0;
final int MAX_ANGLE = 180;
final int MAX_POINTS = 200;
final int MAX_RANGE = 25;

// Point Class
class Point {
  int x, y;
  
  Point(int xPos, int yPos) {
    x = xPos;
    y = yPos;
  }
  
  int getX() {
    return x;
  }
 
  int getY() {
    return y;
  }
}

// Global Variables
int angle, range;
Serial port;
Point radarOrigin;
Point[] points;

// Functions
void shiftPoints() {
  // Goes through the array to remove the oldest point
  for (int i = MAX_POINTS-1; i > 0; i--) {
    Point oldPoint = points[i-1];
    if (oldPoint != null) {
      points[i] = oldPoint;
    }
  }
}

void drawRadarScreen() {
  stroke(GREEN);
  noFill();
  // Draw border
  strokeWeight(3);
  rect(width/2, height/2, width-1, height);
  strokeWeight(1);
  // Draw 5 semi-circular arcs
  for (int i = 0; i <= 5; i++) {
    arc(radarOrigin.x, radarOrigin.y, 200 * i, 200 * i, MIN_ANGLE, MAX_ANGLE);
  }
  // Draw grid lines and angles
  for (int i = 0; i <= 6; i++) {
    stroke(GREEN);
    line(radarOrigin.x, radarOrigin.y, radarOrigin.x + cos(radians(180+(30*i)))*radarOrigin.x, radarOrigin.y + sin(radians(180+(30*i)))*radarOrigin.y);
    noStroke();
    fill(WHITE);
    text(Integer.toString(0+(30*i)), radarOrigin.x + cos(radians(180+(30*i)))*radarOrigin.x, radarOrigin.y + sin(radians(180+(30*i)))*radarOrigin.y, 25, 50);
  }
} 

void drawText(int angleDegrees) {
  noStroke();
  noFill();
  String rangeText = Integer.toString(range);
  if (range < 0) rangeText = Integer.toString(MAX_RANGE);  // Max range in cm
  // Labels
  text("Angle: " + Integer.toString(angleDegrees), 100, 460, 100, 50);   
  text("degree", 200, 460, 100, 50);      
  text("Range: " + rangeText, 100, 480, 100, 30);  
  text("cm", 200, 490, 100, 50);       
  // Distances
  fill(TEXT_GREEN);
  text("5 cm", 615, 420, 250, 50);
  text("10 cm", 608, 320, 250, 50);
  text("15 cm", 608, 220, 250, 50);
  text("20 cm", 608, 120, 250, 50);
  text("25 cm", 608, 040, 250, 50);
  // Range key
  text("Range Key:", 100, 50, 150, 50);
  text("Far", 115, 70, 150, 50);
  text("Near", 115, 90, 150, 50);
  text("Close", 115, 110, 150, 50);
  
  fill(0,50,0);
  rect(30,53,10,10);
  
  fill(0,110,0);
  rect(30,73,10,10);
  
  fill(0,170,0);
  rect(30,93,10,10);
}

void drawSweep(int theta) {  
  fill(SWEEP_GREEN); 
  arc(radarOrigin.x, radarOrigin.y, width, width, radians(theta-185), radians(theta-175));
}

void drawPoints(int theta, int dist) {
  shiftPoints();
  if (dist > 0) {
    float thetaRadians = radians(theta-90);
    float px = radarOrigin.x + (dist * 20 * sin(thetaRadians));
    float py = radarOrigin.y - (dist * 20 * cos(thetaRadians));
    points[0] = new Point((int)px, (int)py);
  } else {
    points[0] = new Point(0, 0);
  }
  for (int i = 0; i < MAX_POINTS; i++) {
    Point point = points[i];
    if (point != null) {
      int x = point.x;
      int y = point.y;
      if (x == 0 && y == 0) continue;
      int alpha = (int)map(i, 0, MAX_POINTS, 20, 0);
      int size = (int)map(i, 0, MAX_POINTS, 30, 5);
      fill(0, 255, 0, alpha);
      noStroke();
      ellipse(x, y, size, size);
    }
  }
}

// Main
void setup() {
  size(1000, 500, P2D);
  rectMode(CENTER);
  points = new Point[MAX_POINTS];
  radarOrigin = new Point(width / 2, height);
  port = new Serial(this, "COM10" , 115200);
  port.bufferUntil('\n');
}

void draw() {
  background(DARK_GREY);
  drawRadarScreen();
  drawText(angle);
  drawSweep(angle);
  drawPoints(angle, range);
}

// Called when Serial information is available
void serialEvent(Serial eventPort) {
  String packet = eventPort.readStringUntil('\n');
  if (packet != null) {
    packet = trim(packet);
    String[] values = split(packet, ',');
    try {
      angle = Integer.parseInt(values[0]);
      range = Integer.parseInt(values[1]);
    } 
    catch (Exception e) {
      e.printStackTrace();
    }
  }
}
