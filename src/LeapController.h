//
//  LeapController.h
//  GeoSenseReliefClientOSX
//
//  Created by Zachary Barryte on 3/31/13.
//  Copyright (c) 2013 Massachusetts Institute of Technology. All rights reserved.
//

#pragma once

#include "ofMain.h"
#include "ofEvents.h"
#include "SceneController.h"
#include "ofxLeapMotion.h"

#define PAN_SCALE 30.0f

//--------------------------------------------------------
class LeapController: public SceneController{
public:
    LeapController();
    void update();
    
    void pan(float dx, float dy, float dz);
    
    bool horizontalPan, verticalPan;
    
    ofxLeapMotion leap;
    vector <ofxLeapMotionSimpleHand> simpleHands;
    vector <ofxLeapMotionSimpleHand> simpleHandsPrevious;
};
