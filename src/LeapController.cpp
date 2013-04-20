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
    hands = leap.getLeapHands();
    
    if(leap.isFrameNew() && hands.size()){
        
        for(int i = 0; i < hands.size(); i++){
            
            Hand hand = hands[i];
            
            if (handsPrevious.size() == hands.size() && hand.fingers().count() == 3){
                
                float dx =  hand.palmPosition().x - handsPrevious[i].palmPosition().x;
                float dy =  hand.palmPosition().z - handsPrevious[i].palmPosition().z;
                float dz = -hand.palmPosition().y + handsPrevious[i].palmPosition().y;
                int numFingers = hands[i].fingers().count();
                
//                horizontalPan = (numFingers == 2);
                horizontalPan = false;
                verticalPan = true;
                
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
            static GestureEventArgs args;
            args.pos = ofVec3f(tap.position().x, tap.position().y, tap.position().z);
            ofNotifyEvent(onTapScreen, args, this);
        } else if (gestures[i].type() == Gesture::TYPE_KEY_TAP) {
            KeyTapGesture tap = gestures[i];
            static GestureEventArgs args;
            args.pos = ofVec3f(tap.position().x, tap.position().y, tap.position().z);
            ofNotifyEvent(onTapDown, args, this);
            
            //cout << "LEAP TAP GESTURE AT: " << pos << endl;
        
        } else if (gestures[i].type() == Gesture::TYPE_SWIPE) {
            SwipeGesture swipe = gestures[i];
            Vector diff = 0.004f*(swipe.position() - swipe.startPosition());
            static GestureEventArgs args;
            args.pos = ofVec3f(swipe.position().x, swipe.position().y, swipe.position().z);
            args.startPos = ofVec3f(swipe.startPosition().x, swipe.startPosition().y, swipe.startPosition().z);
            args.state = swipe.state();
            ofNotifyEvent(onSwipe, args, this);
            
            //cout << "LEAP SWIPE GESTURE" << endl;
        
        } else if (gestures[i].type() == Gesture::TYPE_CIRCLE) {
            CircleGesture circle = gestures[i];
            float progress = circle.progress();
            
            if (progress >= 1.0f) {
                double curAngle = 6.5;
                
                //cout << "LEAP CIRCLE GESTURE" << endl;
            }
            static GestureEventArgs args;
            args.pos = ofVec3f(circle.center().x, circle.center().y, circle.center().z);
            args.normal = ofVec3f(circle.normal().x, circle.normal().y, circle.normal().z);
            args.progress = circle.progress();
            ofNotifyEvent(onCircle, args, this);
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
