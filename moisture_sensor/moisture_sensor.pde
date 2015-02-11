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
String oldID = "";

void enviar_tweet(String tweet){
  try {   
      //Query query = new Query("Guayaquil");
      //QueryResult result = twitter.search(query);
      //for (Status status : result.getTweets()) {
      //    println("@" + status.getUser().getScreenName() + ":" + status.getText() + "("+status.getCreatedAt()+")");
      //    println("");
      //}
      
      // The factory instance is re-useable and thread safe.
      Status status = twitter.updateStatus(tweet);
      System.out.println("Successfully updated the status to [" + status.getText() + "].");
      
      //DirectMessage message = twitter.sendDirectMessage("CTIbot1", tweet);
    }
    catch (TwitterException te) {
        println("Couldn't connect: " + te);
    };
}

void setup() {
  size(640, 480);
  cam = new Capture(this, width, height);
  cam.start();
  
  // I know that the first port in the serial list on my mac
  // is always my  FTDI adaptor, so I open Serial.list()[0].
  // On Windows machines, this generally opens COM1.
  // Open whatever port is the one you're using.
  String portName = Serial.list()[0];
  myPort = new Serial(this, portName, 9600);
  loginTwitter();
}

void loginTwitter() {
  twitter.setOAuthConsumer(OAuthConsumerKey, OAuthConsumerSecret);
  AccessToken accessToken = loadAccessToken();
  twitter.setOAuthAccessToken(accessToken);
}

private static AccessToken loadAccessToken() {
  return new AccessToken(AccessToken, AccessTokenSecret);
}






void draw(){
  checkMoisture();
  getMention();
  delay(15000); // wait 15 seconds to avoid Twitter Rate Limit
}

void checkMoisture(){
  DateFormat dateFormat = new SimpleDateFormat("yyyy/MM/dd HH:mm:ss");
  Date date = new Date();
  String current_date = dateFormat.format(date);


  if ( myPort.available() > 0) {  // If data is available,
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
            String mensaje = "Tomando agua #sedienta - "+current_date;
            enviar_tweet(mensaje);
          }
        }
      }
      else{
        //Desactivar bomba
        activar_bomba = false;
        
        //Notificar
        if(!enviar_notificacion){
            enviar_notificacion = true;
            String mensaje = "Ya tome suficiente agua... #repleta xD "+current_date;
            enviar_tweet(mensaje);
          }
      }
    }
  }
}

float readMoisture(){
  if ( myPort.available() > 0) {  // If data is available,
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
    println(status.getText()+", by @"+status.getUser().getScreenName());
    
    //TODO: el problema con los estados es que twitter no permite al usuario enviar el mismo tweet dos veces. 
    if(status.getText().equals("@freyr_bot estado")){
      Float humedad = readMoisture();    //TODO: hacer que el arduino retorne el valor de la humedad y el estado de la bomba
      String mensaje = "La humedad de la tierra es "+humedad;
      enviar_tweet(mensaje);
    }
    else if(status.getText().equals("@freyr_bot selfie")){
      if(cam.available()) {
          cam.read();
        }
        image(cam, 0,0);
        saveFrame("selfie.jpg");  //http://forum.processing.org/one/topic/save-an-image-from-webcam-capture.html
        File file = new File(sketchPath("selfie.jpg"));
        tweetPic(file, "#selfie");
    }
    else{
      enviar_tweet("Los comandos son: estado, selfie");
    }
  }
}


//http://forum.processing.org/two/discussion/2897/tweeting-a-photo-with-twitter4j-how-solved
void tweetPic(File _file, String theTweet){
  try{
       StatusUpdate status = new StatusUpdate(theTweet);
       status.setMedia(_file);
       twitter.updateStatus(status);
       System.out.println("Successfully updated the status to [" + theTweet + "].");
    }
    catch (TwitterException te){
        println("Error: "+ te.getMessage()); 
    }
}

