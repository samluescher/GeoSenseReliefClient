#pragma once

#include "ofMain.h"
#include "ofEvents.h"
#include "SceneController.h"
#include "ofxOsc.h"

#define MIN_EASE_VELOCITY .005f

#define RELIEF_PORT 78746

#define PAN_SCALE 30.0f

//--------------------------------------------------------
class OscReceiverController : public SceneController{
public:
    OscReceiverController();
    void oscMessageReceived(ofxOscMessage m);
    bool horizontalPan, verticalPan;
    
    ofVec3f center;
    
    ofVec3f p0;
    ofVec3f p1;
    ofVec3f p2;
    ofVec3f p3;
    
    ofVec3f n;
};

