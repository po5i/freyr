/**
 * Simple Read
 * 
 * Read data from the serial port and change the color of a rectangle
 * when a switch connected to a Wiring or Arduino board is pressed and released.
 * This example works with the Wiring / Arduino program that follows below.
 */


import processing.serial.*;
import java.text.*;
import java.util.Date;

Serial myPort;  // Create object from Serial class
int val;      // Data received from the serial port
int dry = 50;
Boolean activar_bomba = false;
Boolean enviar_notificacion = true;

void enviar_tweet(String tweet){
  try {
      ConfigurationBuilder cb = new ConfigurationBuilder();
      cb.setOAuthConsumerKey("KcnnOrCgBi8jUV6YG5f6zqv0d");
      cb.setOAuthConsumerSecret("ag176KgFOipwJtMpl6725DzuzP0ujYiY8TcJ5p6FhWRxvUzLQh");
      cb.setOAuthAccessToken("2690178402-jZhe3oVhaJ1mGUaocuitvWgP1bZ9Ls3IN9boMy6");
      cb.setOAuthAccessTokenSecret("6w1LUJZjja85eSTcANlfkIrc35c1iaDOE9bEOfJxXoYO7");
      // The factory instance is re-useable and thread safe.
      //Twitter twitter = TwitterFactory.getSingleton();
      
      TwitterFactory tf = new TwitterFactory(cb.build());
      Twitter twitter = tf.getInstance();
    
      //Query query = new Query("Guayaquil");
      //QueryResult result = twitter.search(query);
      //for (Status status : result.getTweets()) {
      //    println("@" + status.getUser().getScreenName() + ":" + status.getText() + "("+status.getCreatedAt()+")");
      //    println("");
      //}
      
      // The factory instance is re-useable and thread safe.
      //String tweet = "@CTIbot1 Probando #arduino desde #processing, valor de luz recibido del sensor: "+value;
      Status status = twitter.updateStatus(tweet);
      System.out.println("Successfully updated the status to [" + status.getText() + "].");
      
      //DirectMessage message = twitter.sendDirectMessage("CTIbot1", tweet);
    }
    catch (TwitterException te) {
        println("Couldn't connect: " + te);
    };
}

void setup() {
  size(200, 200);
  // I know that the first port in the serial list on my mac
  // is always my  FTDI adaptor, so I open Serial.list()[0].
  // On Windows machines, this generally opens COM1.
  // Open whatever port is the one you're using.
  String portName = Serial.list()[5];
  myPort = new Serial(this, portName, 9600);
}

void draw(){
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
          //TODO: activar la bomba con relay
          
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




