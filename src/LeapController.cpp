//
//  LeapController.cpp
//  GeoSenseReliefClientOSX
//
//  Created by Zachary Barryte on 3/31/13.
//  Copyright (c) 2013 Massachusetts Institute of Technology. All rights reserved.
//

#include "LeapController.h"

LeapController::LeapController() {
    ofSetFrameRate(60);
    ofSetVerticalSync(true);
	//ofSetLogLevel(OF_LOG_VERBOSE);
    
	leap.open(); 
}

void LeapController::update() {
    //cout << leap.getSimpleHands().size() << endl;
    
    simpleHands = leap.getSimpleHands();
    
    if( leap.isFrameNew() && simpleHands.size() ){
        
        for(int i = 0; i < simpleHands.size(); i++){
            
            if (simpleHandsPrevious.size() == simpleHands.size() && simpleHands[i].fingers.size() <= 2){
                
                float dx = simpleHands[i].handPos.x - simpleHandsPrevious[i].handPos.x;
                float dy = simpleHands[i].handPos.z - simpleHandsPrevious[i].handPos.z;
                float dz = -simpleHands[i].handPos.y + simpleHandsPrevious[i].handPos.y;
                int numFingers = simpleHands[i].fingers.size();
                
                horizontalPan = (numFingers == 2);
                verticalPan = (numFingers == 0);
                
                pan(dx,dy,dz);
            }
        }
    }
    
    simpleHandsPrevious = simpleHands;
    
	leap.markFrameAsOld();
    
    SceneController::update();
}

void LeapController::pan(float dx, float dy, float dz) {
    
//    cout << dx << " " << dy << " " << dz << endl;
    
    if (horizontalPan) {
        panVelocity.z = 0;
        panVelocity.x = -dx / ofGetWidth() * PAN_SCALE;
        panVelocity.y = dy / ofGetHeight() * PAN_SCALE;
        
        panEaseStart = ofGetElapsedTimef();
        panEase = panVelocity.length() > MIN_EASE_VELOCITY;
    }
    if (verticalPan) {
        
//        cout << "vertical panning" << endl;
//        cout << panVelocity.z << endl;
        
        panVelocity.x = 0;
        panVelocity.y = 0;
        panVelocity.z = dz / ofGetHeight() * PAN_SCALE;
        
        panEaseStart = ofGetElapsedTimef();
        panEase = panVelocity.length() > MIN_EASE_VELOCITY;
    }
}
