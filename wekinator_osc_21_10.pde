import processing.video.*;
import oscP5.*;
import netP5.*;

Capture cam;

OscP5 oscP5;
NetAddress dest;

int[] data = new int[100];
int RESOLUTION = 25; // how many real pixels will be compacted. Default 50
int SKIP_STEP = 12; // skip every X pixel in brightness calculation for an area.
int CROP_SIZE = 500;  // Define the size of the central portion

void setup() {
  size(500, 500);
  noStroke();
  
  oscP5 = new OscP5(this,12000);
  dest = new NetAddress("127.0.0.1",6448);

  String[] cameras = Capture.list();

  // print all available camera in case the default setting does not work.
  //if (cameras.length == 0) {
  //  println("There are no cameras available for capture.");
  //  exit();
  //} else {
  //  println("Available cameras:");
  //  for (int i = 0; i < cameras.length; i++) {
  //    println(cameras[i]);
  //  }
  //}
    
    // The camera can be initialized directly using an 
    // element from the array returned by list():
    cam = new Capture(this, cameras[0]);
    cam.start();  

  // hack to make the webcam work. use if necessary.
  //cam = new Capture(this, "pipeline:autovideosrc");
  //cam.start(); 
}

void draw() {
  if (cam.available() == true) {
    cam.read();
  }
  
  // Calculate the coordinates to crop the center of the image
  int startX = (cam.width - CROP_SIZE) / 2;
  int startY = (cam.height - CROP_SIZE) / 2;
  
  // Extract the central portion of the image
  PImage centerImage = cam.get(startX, startY, CROP_SIZE, CROP_SIZE);
  
  // mirror horizontally
  pushMatrix();
  scale(-1, 1);
  image(centerImage, -width, 0);
  popMatrix();
  
  getPixelData();
  
  OscMessage msg = new OscMessage("/wek/inputs");
  
  for (int i = 0; i < data.length; i++) {
    msg.add((float)data[i]);  
  }
  
  oscP5.send(msg, dest);
  
  delay(30);
  
}

int[] getPixelData() {
  int count = 0;
  
  for(int xStep = 0; xStep < 10; xStep++) {
    for (int yStep = 0; yStep < 10; yStep++) {
      
      int currentX = xStep * RESOLUTION;
      int currentY = yStep * RESOLUTION;
      
      data[count] = 0;
      
      // dont read every pixel form a certain region for brightness average.
      for (int x = 0; x < RESOLUTION; x += SKIP_STEP) {
        for (int y = 0; y < RESOLUTION; y += SKIP_STEP) {
           data[count] = (int) (data[count] + brightness(get(currentX + x,currentY + y))) / 2;
        }
      }
      
      fill(data[count]);
      rect(currentX, currentY, RESOLUTION, RESOLUTION);
      
      count++;
    }
  }
  
  return data;
}
