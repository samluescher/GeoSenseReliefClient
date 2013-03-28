//
//  OscReceiverController.cpp
//  GeoSenseReliefClientOSX
//
//  Created by Samuel Luescher on 3/28/13.
//
//

#include "OscReceiverController.h"

//--------------------------------------------------------------
void OscReceiverController::setup(){
	// listen on the given port
//	cout << "listening for osc messages on port " << PORT << "\n";
	receiver.setup(RELIEF_PORT);
//    
//	current_msg_string = 0;
//	mouseX = 0;
//	mouseY = 0;
//	mouseButtonState = "";
//    
//	ofBackground(30, 30, 130);

}

//--------------------------------------------------------------
void OscReceiverController::oscMessageReceived(ofxOscMessage m) {
//    ofLog() << "osc message: " << m.getAddress();
    
    if (m.getAddress() == "/camtracker/pan") {
        float dx = m.getArgAsFloat(0);
        float dy = m.getArgAsFloat(1);
        float dz = m.getArgAsFloat(2);
        
        panVelocity = ofVec3f(dx,dy,dz);
        panVelocity.x = -panVelocity.x / ofGetWidth();
        panVelocity.y = panVelocity.y / ofGetHeight();
        panVelocity.z = panVelocity.z / ofGetHeight();
        
        panEaseStart = ofGetElapsedTimef();
        panEase = panVelocity.length() > MIN_EASE_VELOCITY;
        
        cout << panVelocity << endl;
    }
    
}
