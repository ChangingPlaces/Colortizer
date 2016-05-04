// import UDP library
import hypermedia.net.*;
UDP udp;  // define the UDP object
String local_UDPAddress = "localhost";
int local_UDPin = 6669;
int local_UDPout = 6152;

boolean busyImporting = false;
boolean viaUDP = true;

String LOCAL_FRIENDLY_NAME = "COLORTIZER";

String udpDataPrevious = ""; //YZ
double udpDataLastTime = 0;

float [] density_values = new float[6];
int [] type_count = new int[6];
float [] density_person = {0.01123,0.018181,0.0666667}; //
float [] persons = new float[3]; // old,med,young 
float floating_min = 10000;
float floating_max = -10000;

void startUDP(){

  if (decode == false) {
    viaUDP = false;
  }

  if (viaUDP) {
    udp = new UDP( this, local_UDPin );
    //udp.log( true );     // <-- printout the connection activity
    udp.listen( true );
  }
}

void sendData() {
  
  if (viaUDP && updateReceived) {
    String dataToSend = "";
    /**
    * state_data
    */
    state_data=new int[0][0];
    
    // tag to denote that tag comes from colortizer
    dataToSend += LOCAL_FRIENDLY_NAME;
    dataToSend += "\n" ;
    
    // Scan Grid Location (for referencing grid offset file)
    dataToSend += "gridIndex";
    dataToSend += "\t" ;
    dataToSend += imageIndex;
    dataToSend += "\n" ;
    
    // UMax and VMax Values
    dataToSend += "gridExtents";
    dataToSend += "\t" ;
    dataToSend += tagDecoder[0].U;
    dataToSend += "\t" ;
    dataToSend += tagDecoder[0].V;
    dataToSend += "\n" ;
    
    // IDMax Value
    dataToSend += "IDMax";
    dataToSend += "\t" ;
    dataToSend += scanGrid[numGAforLoop[imageIndex]].IDMode*8-1;
    dataToSend += "\n" ;
    
    if (enableToggles) {
      dataToSend += "dockID";
      dataToSend += "\t" ;
      dataToSend += tagDecoder[1].id[0][0];
      dataToSend += "\n" ;
      
      dataToSend += "dockRotation";
      dataToSend += "\t" ;
      dataToSend += tagDecoder[1].rotation[0][0];
      dataToSend += "\n" ;
      
      dataToSend += "slider1";
      dataToSend += "\t" ;
      dataToSend += sliderDecoder[0].code;
      dataToSend += "\n" ;
      
      //overwriting the tagdecoder[1].id[0][0]
      //println(tagDecoder[1].id[0][0]);
      
      if(floating_min > sliderDecoder[0].code){
        floating_min = sliderDecoder[0].code;
      }
      
      if(floating_max < sliderDecoder[0].code){
        floating_max = sliderDecoder[0].code;
      }
      
      //
      // update value from slider Y.S.
      //
      float v= 1+((1-(sliderDecoder[0].code-floating_min) / (floating_max-floating_min))*29);
      
      if(tagDecoder[1].id[0][0] != -1 && tagDecoder[1].id[0][0] < 6){
        density_values[tagDecoder[1].id[0][0]] = v;
      }
       
      dataToSend += "toggle1";
      dataToSend += "\t" ;
      dataToSend += colorDecoder[0].id[0][0];
      dataToSend += "\n" ;
      
      dataToSend += "toggle2";
      dataToSend += "\t" ;
      dataToSend += colorDecoder[1].id[0][0];
      dataToSend += "\n" ;
      
      dataToSend += "toggle3";
      dataToSend += "\t" ;
      dataToSend += colorDecoder[2].id[0][0];
      dataToSend += "\n" ;
      
    }
    
    for (int u=0; u<tagDecoder[0].U; u++) {
      for (int v=0; v<tagDecoder[0].V; v++) {

        // Object ID
        dataToSend += tagDecoder[0].id[u][v] ;
        dataToSend += "\t" ;
        
       
        // type counting
        if(tagDecoder[0].id[u][v] != -1 && tagDecoder[0].id[u][v] < 6)
          type_count[tagDecoder[0].id[u][v]] ++;

        // U Position
        dataToSend += tagDecoder[0].U-u-1 + exportOffsets[numGAforLoop[imageIndex]][0];
        dataToSend += "\t" ;

        // V Position
        dataToSend += v + exportOffsets[numGAforLoop[imageIndex]][1];
        dataToSend += "\t" ;
        
//        // U Position
//        dataToSend += tagDecoder[0].U-u-1;
//        dataToSend += "\t" ;
//
//        // V Position
//        dataToSend += v;

        // Rotation
        dataToSend += tagDecoder[0].rotation[u][v];
        dataToSend += "\n" ;

        /**
        * storing data for web (2016/01/05 Y.S.)
        * simplified the data for the sake of example
        */
        if(enableDDP){
          state_data = (int[][])append(state_data,new int[]{tagDecoder[0].id[u][v],tagDecoder[0].rotation[u][v]});
        }
      }
    }
    
    
     // Added from here to 
     //HACK
      dataToSend += round(density_values[0])+"";
      for(int i=1;i<6;i++){ //limiting to 6 values
        dataToSend += "\t" + round(density_values[i]);
      }
      dataToSend += "\n";
      
    for(int i=0;i<3;i++){  
      int floors = round(density_values[i]) * type_count[i]; // floor num
      float area = floors * 62.5 * 62.5 * 0.25; //sqm
      persons[i] = area * density_person[i]; //float num
    }
    
    int mid_old = int(persons[0]+persons[1]/2);
    int young = int(persons[2]);
    
    dataToSend += mid_old+"\t"; //old
    dataToSend += mid_old+"\t"; // mid
    dataToSend += young+"\t"; //young
    dataToSend += "\n";
    
    /* Flinders Toggles
    // Slider and Toggle Values
    for (int i=0; i<sliderDecoder.length; i++) {
      dataToSend += sliderDecoder[i].code;
      if (i != sliderDecoder.length-1) {
        dataToSend += "\t";
      } else {
        dataToSend += "\n";
      }
    }


    // Slider and Toggle Locations
    for (int i=0; i<numGridAreas[0]; i++) {
      dataToSend += gridLocations.getInt(0, 0 + i*4);
      dataToSend += "\t" ;
      dataToSend += gridLocations.getInt(0, 1 + i*4);
      dataToSend += "\t" ;
      dataToSend += gridLocations.getInt(0, 2 + i*4);
      dataToSend += "\t" ;
      dataToSend += gridLocations.getInt(0, 3 + i*4);
      dataToSend += "\n";
    }


    // Slider and Toggle Canvas Dimensions
    dataToSend += vizRatio;
    dataToSend += "\t" ;
    dataToSend += vizWidth;
    dataToSend += "\n" ;
    */
    
    // Saves dataToSend as a text file for Debugging
    //saveStrings("data.txt", split(dataToSend, "\n"));
    
    // Sends dataToSend to local host via UDP
    udp.send( dataToSend, local_UDPAddress, local_UDPout );
    
    // Sends dataToSend to external host via UDP "once in a while"
    if(UDPtoServer && (dataToSend != udpDataPrevious || millis() - udpDataLastTime > 60000)) {
      udp.send( dataToSend, UDPServer_IP, UDPServer_PORT );
      udpDataLastTime = millis();
      //println("data was send through UDP");
    }
     
    //////////////////////////////////////// send to Rhino and Agents ///////////////////////////////////////////////
    
    if (frameCount % 20 == 0 && dataToSend != udpDataPrevious) {
      udp.send( dataToSend, "localhost", 7001 ); //YZ
      udpDataPrevious = dataToSend;
    }
    
    //////////////////////////////////////// send to Rhino and Agents ///////////////////////////////////////////////
    
    

  } else {
    //println("no update received");
  }
}

// Implemented for SDL Rhino Interface (deprecated)
void ImportData(String inputStr[]) {

  for (int i=0 ; i<inputStr.length;i++) {

    String tempS = inputStr[i];
    String[] split = split(tempS, "\t");
    
    if (useUMI) {
      // Sends commands to Rhino Server to run UMI functions
      if (split.length == 1) {
  
        switch(int(split[0])) {
          case 1:
            if (writer != null) { writer.println("resimulate"); }
            break;
          case 2:
            if (writer != null) { writer.println("save"); }
            break;
          case 3:
            if (writer != null) { writer.println("displaymode energy"); }
            break;
          case 4:
            if (writer != null) { writer.println("displaymode walkability"); }
            break;
          case 5:
            if (writer != null) { writer.println("displaymode daylighting"); }
            break;
          case 6:
            if(useUMI) {
              initServer();
            }
            break;
        }
        println(split[0]);
      }
    }
  }

  busyImporting = false;
}

void receive( byte[] data, String ip, int port ) {  // <-- extended handler

  // get the "real" message =
  String message = new String( data );
  //println(message);
  //saveStrings("data.txt", split(message, "\n"));
  String[] split = split(message, "\n");

  if (!busyImporting) {
    busyImporting = true;
    ImportData(split);
  }
}
