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

Capture cam;
Serial myPort;  // Create object from Serial class
int val;      // Data received from the serial port
int dry = 50;
Boolean activar_bomba = false;
Boolean enviar_notificacion = true;

static String OAuthConsumerKey = "KcnnOrCgBi8jUV6YG5f6zqv0d";
static String OAuthConsumerSecret = "ag176KgFOipwJtMpl6725DzuzP0ujYiY8TcJ5p6FhWRxvUzLQh";
static String AccessToken = "2690178402-jZhe3oVhaJ1mGUaocuitvWgP1bZ9Ls3IN9boMy6";
static String AccessTokenSecret = "6w1LUJZjja85eSTcANlfkIrc35c1iaDOE9bEOfJxXoYO7";
Twitter twitter = new TwitterFactory().getInstance();
TwitterStream twitterStream = new TwitterStreamFactory().getInstance();
String oldID = "";

Boolean debug_no_arduino = true;
Date start_run_date;



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
  //startListener();
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
      
      float moisture = Float.parseFloat(inString);
      //println(moisture);
      
      if(moisture > 0){
        //notification for tweeter
        //activar sistema
        if(!activar_bomba){
          activar_bomba = true;
          
          if(enviar_notificacion){
            enviar_notificacion = false;
            String mensaje = "Tomando agua #sedienta";
            enviarTweet(mensaje);
          }
        }
      }
      else{
        //Desactivar bomba
        activar_bomba = false;
        
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

float readMoisture(){
  if (!debug_no_arduino && myPort.available() > 0) {  // If data is available,
    //val = myPort.read();         // read it and store it in val
    //readString += val; 
    String inString = myPort.readStringUntil('\n');
 
    if (inString != null && !inString.equals("")) {
      // trim off any whitespace:
      inString = trim(inString);
      //println(inString);  //debug
      
      float moisture = Float.parseFloat(inString);
      return(moisture);
    }
  }
  return 0;
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
      Float humedad = readMoisture();    //TODO: hacer que el arduino retorne el valor de la humedad y el estado de la bomba
      String mensaje = "La humedad de la tierra es "+humedad;
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


/*void startListener(){
  StatusListener listener = new StatusListener() {
      @Override
      public void onStatus(Status status) {
          System.out.println("@" + status.getUser().getScreenName() + " - " + status.getText());
      }

      @Override
      public void onDeletionNotice(StatusDeletionNotice statusDeletionNotice) {
          System.out.println("Got a status deletion notice id:" + statusDeletionNotice.getStatusId());
      }

      @Override
      public void onTrackLimitationNotice(int numberOfLimitedStatuses) {
          System.out.println("Got track limitation notice:" + numberOfLimitedStatuses);
      }

      @Override
      public void onScrubGeo(long userId, long upToStatusId) {
          System.out.println("Got scrub_geo event userId:" + userId + " upToStatusId:" + upToStatusId);
      }

      @Override
      public void onStallWarning(StallWarning warning) {
          System.out.println("Got stall warning:" + warning);
      }

      @Override
      public void onException(Exception ex) {
          ex.printStackTrace();
      }
  };
  twitterStream.addListener(listener);
  twitterStream.sample();
}*/


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

