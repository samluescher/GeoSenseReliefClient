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
    
    leap.open();
    leap.setupGestures();
}

void LeapController::update() {
    
    justTyped = false;
    justTapped = false;
    justSwiped = false;
    justCircled = false;
    
    hands = leap.getLeapHands();
    
    if(leap.isFrameNew() && hands.size()){
        
        for(int i = 0; i < hands.size(); i++){
            
            Hand hand = hands[i];
            
            if (handsPrevious.size() == hands.size() && hand.fingers().count() <= 2){
                
                float dx =  hand.palmPosition().x - handsPrevious[i].palmPosition().x;
                float dy =  hand.palmPosition().z - handsPrevious[i].palmPosition().z;
                float dz = -hand.palmPosition().y + handsPrevious[i].palmPosition().y;
                int numFingers = hands[i].fingers().count();
                
//                horizontalPan = (numFingers == 2);
                horizontalPan = false;
                verticalPan = (numFingers == 0);
                
                pan(dx,dy,dz);
            }
        }
    }
    
    Frame frame = controller.frame();
    GestureList gestures =  framePrevious.isValid()       ?
    frame.gestures(framePrevious) :
    frame.gestures();
    framePrevious = frame;
    
    for (size_t i=0; i < gestures.count(); i++) {
        if (gestures[i].type() == Gesture::TYPE_SCREEN_TAP) {
            ScreenTapGesture tap = gestures[i];
            pos = tap.position();
            justTyped = true;
            
            //cout << "LEAP TYPE GESTURE AT: " << pos << endl;
            
            
            
            
        } else if (gestures[i].type() == Gesture::TYPE_KEY_TAP) {
            KeyTapGesture tap = gestures[i];
            pos = tap.position();
            justTapped = true;
            
            //cout << "LEAP TAP GESTURE AT: " << pos << endl;
        
        } else if (gestures[i].type() == Gesture::TYPE_SWIPE) {
            SwipeGesture swipe = gestures[i];
            Vector diff = 0.004f*(swipe.position() - swipe.startPosition());
            justSwiped = true;
            
            //cout << "LEAP SWIPE GESTURE" << endl;
        
        } else if (gestures[i].type() == Gesture::TYPE_CIRCLE) {
            CircleGesture circle = gestures[i];
            float progress = circle.progress();
            
            if (progress >= 1.0f) {
                double curAngle = 6.5;
                justCircled = true;
                
                //cout << "LEAP CIRCLE GESTURE" << endl;
            }
        }
    }
    
    handsPrevious = hands;
    
	leap.markFrameAsOld();
    
    SceneController::update();
}

void LeapController::pan(float dx, float dy, float dz) {
    
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
