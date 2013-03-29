//
//  OscReceiverController.cpp
//  GeoSenseReliefClientOSX
//
//  Created by Samuel Luescher on 3/28/13.
//
//

#include "OscReceiverController.h"

//--------------------------------------------------------------
void OscReceiverController::oscMessageReceived(ofxOscMessage m) {
//    ofLog() << "osc message: " << m.getAddress();
    
    if (m.getAddress() == "/camtracker/pan") {
        float dx = m.getArgAsFloat(0);
        float dy = m.getArgAsFloat(1);
        float dz = m.getArgAsFloat(2);
        
        verticalPan = m.getArgAsInt32(3);
        //horizontalPan = m.getArgAsInt32(5);
        
        if (horizontalPan) {
            panVelocity.z = 0;
            panVelocity.x = -dx / ofGetWidth() * PAN_SCALE;
            panVelocity.y = dy / ofGetHeight() * PAN_SCALE;
            
            panEaseStart = ofGetElapsedTimef();
            panEase = panVelocity.length() > MIN_EASE_VELOCITY;
        }
        if (verticalPan) {
            panVelocity.x = 0;
            panVelocity.y = 0;
            panVelocity.z = dz / ofGetHeight() * PAN_SCALE;
            
            panEaseStart = ofGetElapsedTimef();
            panEase = panVelocity.length() > MIN_EASE_VELOCITY;
        }
    }
    
}
