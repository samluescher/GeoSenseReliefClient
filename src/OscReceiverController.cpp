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
        
        horizontalPan = m.getArgAsInt32(3);
        verticalPan = m.getArgAsInt32(4);
        
        cout << "horizontal pan = " << horizontalPan << ", vertical pan = " << verticalPan << endl;
        
        
        if (horizontalPan) {
            panVelocity.z = 0;
            panVelocity.x = -dx / ofGetWidth() * PAN_SCALE;
            panVelocity.y = dy / ofGetHeight() * PAN_SCALE;
        }
        if (verticalPan) {
            panVelocity.y = 0;
            panVelocity.x = 0;
            panVelocity.z = dz / ofGetHeight() * PAN_SCALE;
        }
        
        panEaseStart = ofGetElapsedTimef();
        panEase = panVelocity.length() > MIN_EASE_VELOCITY;
    }
    
}
