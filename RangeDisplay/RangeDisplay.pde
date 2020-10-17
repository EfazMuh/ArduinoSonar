import processing.serial.*;
 
// Color Constants
final color BLACK = color(0);
final color GREY = color(65);
final color WHITE = color(255);
final color DARK_GREY = color(32, 32, 32);
final color RED = color(255, 0, 0);
final color GREEN = color(0, 255, 0);
final color YELLOW = color(255, 255, 0);
final color ORANGE = color(255, 165, 0);
final color TEXT_GREEN = color(0, 300, 0);
final color SWEEP_GREEN = color(0, 153, 0, 125);
final color SWEEP_BLACK = color(0, 0, 0, 125);
final color SWEEP_ORANGE = color(255, 165, 0, 125);

// Graph Constants
final int GRAPH_WIDTH = 630;
final int GRAPH_HEIGHT = 480;
final int RIGHT_COL_X = 740;
final int Y_AXIS = 1;
final int X_AXIS = 2;
final Point GRAPH_ORIGIN = new Point(70, 10);

// Other Constants
final int MAX_RANGE = 30;
final int MAX_ANGLE = 180;
final int MAX_POINTS = 200;

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
float lastAngle = 0;
float lastFrameRate = 30.0;
int angle, range;
Serial port;
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

void setGradient(int x, int y, float w, float h, color c1, color c2, int axis ) {
  noFill();
  if (axis == Y_AXIS) {  // Top to bottom gradient
    for (int i = y; i <= y+h; i++) {
      float inter = map(i, y, y+h, 0, 1);
      color c = lerpColor(c1, c2, inter);
      stroke(c);
      line(x, i, x+w, i);
    }
  }  
  else if (axis == X_AXIS) {  // Left to right gradient
    for (int i = x; i <= x+w; i++) {
      float inter = map(i, x, x+w, 0, 1);
      color c = lerpColor(c1, c2, inter);
      stroke(c);
      line(i, y, i, y+h);
    }
  }
}

void drawGraph() {
  stroke(ORANGE);
  noFill();
  // Draw Border
  strokeWeight(3);
  rectMode(CENTER);
  rect(width/2, height/2, width-1, height);
  strokeWeight(1);
  // Draw Graph Border
  rectMode(CORNER);
  rect(GRAPH_ORIGIN.x, GRAPH_ORIGIN.y, GRAPH_WIDTH, GRAPH_HEIGHT);
  // Draw Info Box
  rect(GRAPH_ORIGIN.x + GRAPH_WIDTH + 10, GRAPH_ORIGIN.y, 250, GRAPH_HEIGHT);
  // Draw Range Tick Marks
  for (int y = GRAPH_ORIGIN.y + GRAPH_HEIGHT; y > GRAPH_ORIGIN.y; y -= 50) {
    stroke(WHITE);
    line(GRAPH_ORIGIN.x - 5, y, GRAPH_ORIGIN.x + 5, y);
    stroke(ORANGE);
    for (int i = 0; i <= 50; i++) {
      float px = lerp(GRAPH_ORIGIN.x + 5, GRAPH_ORIGIN.x + GRAPH_WIDTH, i/50.0);
      float py = lerp(y, y, i/50.0);
      point(px, py);
    }
  }
  // Draw Angle Tick Marks
  stroke(WHITE);
  int tickNum = GRAPH_WIDTH/18;
  for (int x = GRAPH_ORIGIN.x + tickNum; x <= GRAPH_ORIGIN.x + GRAPH_WIDTH; x += tickNum) {
    line(x, GRAPH_ORIGIN.y + GRAPH_HEIGHT - 5, x, GRAPH_ORIGIN.y + GRAPH_HEIGHT + 5);
  }
}

void drawText(int angleDegrees) {
  noStroke();
  fill(WHITE);
  text("ANGLE", GRAPH_ORIGIN.x + GRAPH_WIDTH/2 - 50, GRAPH_ORIGIN.y + GRAPH_HEIGHT + 50);
  // Print out angle labels on x-axis
  int tickNum = GRAPH_WIDTH/18;
  int px = GRAPH_ORIGIN.x - 10;
  int py = GRAPH_ORIGIN.y + GRAPH_HEIGHT + 25;
  for (int ax = 10; ax <= MAX_ANGLE; ax += 10) {
    px += tickNum;
    text(Integer.toString(ax), px, py);
  }
  // Print out range labels on y-axis
  int range_label = 0;
  for (int ry = GRAPH_ORIGIN.y + GRAPH_HEIGHT; ry > GRAPH_ORIGIN.y; ry -= 50) {
    text(range_label, GRAPH_ORIGIN.x - 30, ry);
    range_label += 5;
  }
  float rangeScaled = (180 * range)/(MAX_RANGE * 10);
  String rangeText = Integer.toString(range/10);
  if (range < 0) {
    rangeText = Integer.toString(MAX_RANGE);
    rangeScaled = 180;
  }
  if (frameCount % 10 == 0) lastFrameRate = frameRate;
  text("Frame Rate: " + nf(lastFrameRate, 2, 1), RIGHT_COL_X, 280);
  text("Angle: " + Integer.toString(angleDegrees), RIGHT_COL_X, 350, 100, 50);   
  text("degree", RIGHT_COL_X + 80, 350, 100, 50);   
  text("Range: " + rangeText, RIGHT_COL_X, 420, 100, 30);  
  text("mm", RIGHT_COL_X + 80, 420, 100, 50);
  fill(ORANGE);
  // Draw angle and range bar graphs
  rect(RIGHT_COL_X, 370, angleDegrees, 10);
  setGradient(RIGHT_COL_X, 440, 180, 10, RED, GREEN, X_AXIS);
  fill(BLACK);
  stroke(BLACK);
  rect(RIGHT_COL_X + rangeScaled, 440, 180 - rangeScaled, 10);
  int x = 10;
  int y = GRAPH_ORIGIN.y + GRAPH_HEIGHT/2 - 10;
  fill(WHITE);
  pushMatrix();
  translate(x, y);
  rotate(HALF_PI);
  translate(-x, -y);
  text("RANGE (cm)", x, y);
  popMatrix();
}

void drawSweep(int angleDegrees) {
  float hysteresis = 0.5;
  float oneDegree = GRAPH_WIDTH/180.0;
  int inc = (int)(oneDegree * angleDegrees);
  if (angleDegrees > lastAngle) {
    setGradient((GRAPH_ORIGIN.x + inc) - (int)(oneDegree * 10), GRAPH_ORIGIN.y, oneDegree * 10, GRAPH_HEIGHT, SWEEP_BLACK, SWEEP_ORANGE, X_AXIS);
    lastAngle = angleDegrees - hysteresis;
  } else {
    setGradient(GRAPH_ORIGIN.x + inc, GRAPH_ORIGIN.y, oneDegree * 10, GRAPH_HEIGHT, SWEEP_ORANGE, SWEEP_BLACK, X_AXIS);
    lastAngle = angleDegrees + hysteresis;
  }
}

void drawPoints(int angleDegrees, int dist) {
  shiftPoints();
  if (dist > 0 && dist < MAX_RANGE*10) {
    float oneDegree = GRAPH_WIDTH/180.0;
    int px = (int)(GRAPH_ORIGIN.x + (oneDegree * angleDegrees));
    int py = GRAPH_ORIGIN.y + GRAPH_HEIGHT - dist;
    points[0] = new Point(px, py);
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
      fill(255, 165, 0, alpha);
      noStroke();
      ellipse(x, y, size, size);
    }
  }
}
  
// Main
void setup() {
  size(1000, 550, P2D);
  points = new Point[MAX_POINTS];
  port = new Serial(this, "COM10", 115200);
  port.bufferUntil('\n');
}

void draw() {
  background(DARK_GREY);
  drawSweep(angle);
  drawGraph();
  drawText(angle);
  drawPoints(angle, range);
}

void serialEvent(Serial eventPort) {
  String packet = eventPort.readStringUntil('\n');
  if (packet != null) {
    packet = trim(packet);
    String[] values = split(packet, ',');
    try {
      angle = Integer.parseInt(values[0]);
      range = int(map(Integer.parseInt(values[1]), 1, MAX_RANGE, 1, height));   
    } catch (Exception e) {
      e.printStackTrace();
    }
  }
}
