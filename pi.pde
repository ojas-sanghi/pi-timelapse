import processing.io.*;
import gohai.glvideo.*;
import java.net.URLConnection;
import java.net.HttpURLConnection;
import java.net.URLEncoder;
import java.net.URL;
GLCapture camera;

boolean cameraOn = false;
boolean processingImages = false;

int buttonPin = 2;

void setup() 
{
  size(320, 240, P2D); // Important to note the renderer

  String[] devices = GLCapture.list(); 
  camera = new GLCapture(this, devices[0], 640, 480, 5);
  camera.start();

  GPIO.pinMode(buttonPin, GPIO.INPUT_PULLUP);

  frameRate(5);
}

void updateStatus(String msg)
{
  try
  {
    String address = "https://pi-timelapse-server.herokuapp.com/update-status";
    String charset = java.nio.charset.StandardCharsets.UTF_8.name();
    String query = "status=" + URLEncoder.encode(msg, charset);
    
    URL url = new URL(address + "?" + query);
    HttpURLConnection con = (HttpURLConnection) url.openConnection();
    con.setRequestMethod("GET");
    con.connect();
    println(con.getResponseCode());
    con.disconnect();
    println("update sent");
  }
  catch (Exception e)
  {
    e.printStackTrace();
    println("oops something went wrong encoding the http request or just sending it in general!");
  }
}

void draw() 
{  
  background(0);
  // Read camera data
  if (camera.available()) {
    camera.read();
  }
  // Copy pixels into a PImage object and show on the screen
  image(camera, 0, 0, width, height);

  // save each frame to file
  if (cameraOn)
    saveFrame("frame-######.png");


  // hardware button pressed
  if (GPIO.digitalRead(buttonPin) == GPIO.LOW) 
  {
    // stop camera if on and make the gif
    if (cameraOn)
    {
      updateStatus("Camera off, processing...");
      println("Camera off, processing...");
      
      cameraOn = false;
      processingImages = true;
      try 
      {    
        Runtime rut = Runtime.getRuntime();

        // convert images to gif
        updateStatus("Converting images to gif...");
        println("Converting images to gif...");
        
        // -delay 10
        Process p1 = rut.exec(new String[] {"bash", "-c", "/usr/bin/convert -loop 0 frame-*.png timelapse.gif" }, null, new File("/home/pi/Desktop/timelapse"));
        try
        {
          p1.waitFor();
        }
        catch (InterruptedException e)
        {
          updateStatus("Interrupted!");
          println("Interrupted!");
          e.printStackTrace();
        }

        // once done, delete all old images
        updateStatus("Converted! Deleting images...");
        println("Converted! Deleting images...");
        Process p2 = rut.exec(new String[] {"bash", "-c", "find . -name 'frame-*.png' -delete" }, null, new File("/home/pi/Desktop/timelapse"));
        try
        {
          p2.waitFor();
        }
        catch (InterruptedException e)
        {
          updateStatus("Interrupted!");
          println("Interrupted!");
          e.printStackTrace();
        }
        
        // rotate the gif
        updateStatus("Deleted! Rotating gif...");
        println("Deleted! Rotating gif...");
        Process p3 = rut.exec(new String[] {"bash", "-c", "/usr/bin/convert -rotate 270 timelapse.gif rotate.gif" }, null, new File("/home/pi/Desktop/timelapse"));
        try
        {
          p3.waitFor();
        }
        catch (InterruptedException e)
        {
          println("Interrupted!");
          e.printStackTrace();
        }

        // upload gif
        updateStatus("Rotated! Uploading gif...");
        println("Rotated! Uploading gif...");
        Process p4 = rut.exec(new String[] {"bash", "-c", "sudo imgurbash2 -l -a Z2vwnOA rotate.gif" }, null, new File("/home/pi/Desktop/timelapse"));
        try
        {
          p4.waitFor();
        }
        catch (InterruptedException e)
        {
          updateStatus("Interrupted!");
          println("Interrupted!");
          e.printStackTrace();
        }

        // delete gif
        //updateStatus("Uploaded! Deleting gif...");
        //println("Uploaded! Deleting gif...");
        //Process p5 = rut.exec(new String[] {"bash", "-c", "rm timelapse.gif rotate.gif" }, null, new File("/home/pi/Desktop/timelapse"));
        //try
        //{
          //p5.waitFor();
        //}
        //catch (InterruptedException e)
        //{
          //updateStatus("Interrupted!");
          //println("Interrupted!");
          //e.printStackTrace();
        //}
      }
      catch (IOException e)
      {
        e.printStackTrace();
      }

      processingImages = false;
      updateStatus("Done processing");
      println("Done processing");
    } 
    else
    {
      // only start camera if not processing old gif
      if (!processingImages)
      {
        updateStatus("Camera on");
        println("Camera on");
        cameraOn = true;
      } 
      else
      {
        updateStatus("Still processing! Please wait");
        println("Still processing! Please wait");
      }
    }
  }
}
