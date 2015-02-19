/**
 * Simple Read
 * 
 * Read data from the serial port and change the color of a rectangle
 * when a switch connected to a Wiring or Arduino board is pressed and released.
 * This example works with the Wiring / Arduino program that follows below.
 */


import processing.serial.*;
import processing.video.*;
import java.text.*;
import java.util.Date;
import java.util.Timer;
import java.util.TimerTask;
import java.util.Map;

import twitter4j.*;

Boolean debug_no_arduino = false;    //FALSE si esta conectado al arduino, TRUE para pruebas locales

Capture cam;
Serial myPort;  // Create object from Serial class
int val;      // Data received from the serial port
int dry = 50;
int activar_bomba;
Boolean enviar_notificacion = true;
float moisture;
float minima;
float maxima;
Date start_run_date;
String oldID = "";

static String OAuthConsumerKey = "KcnnOrCgBi8jUV6YG5f6zqv0d";
static String OAuthConsumerSecret = "ag176KgFOipwJtMpl6725DzuzP0ujYiY8TcJ5p6FhWRxvUzLQh";
static String AccessToken = "2690178402-jZhe3oVhaJ1mGUaocuitvWgP1bZ9Ls3IN9boMy6";
static String AccessTokenSecret = "6w1LUJZjja85eSTcANlfkIrc35c1iaDOE9bEOfJxXoYO7";
Twitter twitter = new TwitterFactory().getInstance();
TwitterStream twitterStream = new TwitterStreamFactory().getInstance();






void loginTwitter() {
  twitter.setOAuthConsumer(OAuthConsumerKey, OAuthConsumerSecret);
  AccessToken accessToken = loadAccessToken();
  twitter.setOAuthAccessToken(accessToken);
  
  twitterStream.setOAuthConsumer(OAuthConsumerKey, OAuthConsumerSecret);
  twitterStream.setOAuthAccessToken(new AccessToken( AccessToken, AccessTokenSecret) );
}

private static AccessToken loadAccessToken() {
  return new AccessToken(AccessToken, AccessTokenSecret);
}






class SayHello extends TimerTask {
    public void run() {
       println(">>automatic action!!");
       printStatus();
       getMention();
       delay(60000);
    }
 }

/////////////////////////////////////////////////////////////////////////////////////

void setup() {
  size(640, 480);
  cam = new Capture(this, width, height);
  cam.start();
  
  start_run_date = new Date();
  
  // I know that the first port in the serial list on my mac
  // is always my  FTDI adaptor, so I open Serial.list()[0].
  // On Windows machines, this generally opens COM1.
  // Open whatever port is the one you're using.
  if(!debug_no_arduino){
    String portName = Serial.list()[0];
    myPort = new Serial(this, portName, 9600);
  }
  
  loginTwitter();
  Timer timer = new Timer();
  timer.schedule(new SayHello(), 0, 10000);
}

void mousePressed() {
  println(">>manual action!!");
  printStatus();
  getMention();
}

void draw(){  
  checkMoisture();
}

/////////////////////////////////////////////////////////////////////////////////////


void checkMoisture(){
  
  if (!debug_no_arduino && myPort.available() > 0) {  // If data is available,
    //val = myPort.read();         // read it and store it in val
    //readString += val; 
    String inString = myPort.readStringUntil('\n');
 
    if (inString != null && !inString.equals("")) {
      // trim off any whitespace:
      inString = trim(inString);
      //println(inString);  //debug
      
      //procesar inString: estado-bomba,minimo,maximo,actual 
      String[] arduino_outputs = inString.split(",");
      moisture = Float.parseFloat(arduino_outputs[3]);
      maxima = Float.parseFloat(arduino_outputs[2]);
      minima = Float.parseFloat(arduino_outputs[1]);
      activar_bomba = Integer.parseInt(arduino_outputs[0]);
      //println(moisture);
      
      if(moisture > 0){
        //activado sistema
       
        //Notificar
        if(enviar_notificacion){
          enviar_notificacion = false;
          String mensaje = "Tomando agua #sedienta";
          enviarTweet(mensaje);
        }
        
      }
      else{
        //Desactivado sistema
        
        //Notificar
        if(!enviar_notificacion){
            enviar_notificacion = true;
            String mensaje = "Ya tome suficiente agua... #repleta xD";
            enviarTweet(mensaje);
          }
      }
    }
  }
}






//http://www.instructables.com/id/Twitter-Mention-Mood-Light/?ALLSTEPS
void getMention() {
  ResponseList mentions = null;
  try {
    mentions = twitter.getMentionsTimeline();
  }
  catch(TwitterException e) {
    println("Exception: " + e + "; statusCode: " + e.getStatusCode());
  }
  Status status = (Status)mentions.get(0);
  String newID = str(status.getId());
  if (oldID.equals(newID) == false){
    oldID = newID;
    
    if(status.getCreatedAt().compareTo(start_run_date) < 0){
      println("el comando pertenece al pasado");
      return;
    }
    
    println(status.getText()+", by @"+status.getUser().getScreenName());
    
    //procesar comandos
    if(status.getText().contains("@freyr_bot estado")){
      String mensaje = "La humedad de la tierra es "+moisture+", Rango de humedad entre "+minima+"% a "+maxima+"%.";
      enviarTweet(mensaje);
    }
    else if(status.getText().contains("@freyr_bot selfie")){
      if(cam.available()) {
          cam.read();
        }
        image(cam, 0,0);
        saveFrame("selfie.jpg");  //http://forum.processing.org/one/topic/save-an-image-from-webcam-capture.html
        File file = new File(sketchPath("selfie.jpg"));
        tweetPic(file, "#selfie");
    }
    else{
      enviarTweet("Los comandos son: estado, selfie");
    }
  }
}




/////////////////////////////////////////////////////////////////////////////////////


//http://forum.processing.org/two/discussion/2897/tweeting-a-photo-with-twitter4j-how-solved
void tweetPic(File _file, String theTweet){
  DateFormat dateFormat = new SimpleDateFormat("yyyy/MM/dd HH:mm:ss");
  Date date = new Date();
  String current_date = dateFormat.format(date);

  try{
       StatusUpdate status = new StatusUpdate(theTweet+"|"+current_date);
       status.setMedia(_file);
       twitter.updateStatus(status);
       System.out.println("Successfully updated the status to [" + theTweet + "].");
    }
    catch (TwitterException te){
        println("Error: "+ te.getMessage()); 
    }
}

void enviarTweet(String tweet){
  DateFormat dateFormat = new SimpleDateFormat("yyyy/MM/dd HH:mm:ss");
  Date date = new Date();
  String current_date = dateFormat.format(date);


  try {   
      //Query query = new Query("Guayaquil");
      //QueryResult result = twitter.search(query);
      //for (Status status : result.getTweets()) {
      //    println("@" + status.getUser().getScreenName() + ":" + status.getText() + "("+status.getCreatedAt()+")");
      //    println("");
      //}
      
      // The factory instance is re-useable and thread safe.
      Status status = twitter.updateStatus(tweet+"|"+current_date);
      System.out.println("Successfully updated the status to [" + status.getText() + "].");
      
      //DirectMessage message = twitter.sendDirectMessage("CTIbot1", tweet);
    }
    catch (TwitterException te) {
        println("Couldn't connect: " + te);
    };
}


void printStatus(){
  try {
      System.out.println("=======================================");
      //Twitter twitter = new TwitterFactory().getInstance();
      Map<String ,RateLimitStatus> rateLimitStatus = twitter.getRateLimitStatus();
      for (String endpoint : rateLimitStatus.keySet()) {
        RateLimitStatus status = rateLimitStatus.get(endpoint);
        if(status.getLimit() != status.getRemaining()){          
          System.out.println("Endpoint: " + endpoint);
          System.out.println(" Limit: " + status.getLimit());
          System.out.println(" Remaining: " + status.getRemaining());
          System.out.println(" ResetTimeInSeconds: " + status.getResetTimeInSeconds());
          System.out.println(" SecondsUntilReset: " + status.getSecondsUntilReset());
        }
      }
      System.out.println("=======================================");
  } catch (TwitterException te) {
      te.printStackTrace();
      System.out.println("Failed to get rate limit status: " + te.getMessage());
      System.exit(-1);
  }
}

