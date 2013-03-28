#pragma once

#include "ofMain.h"
#include "ofEvents.h"
#include "SceneController.h"
#include "ofxOsc.h"

#define EASING_TIME .5f
#define MIN_EASE_VELOCITY .005f

#define RELIEF_PORT 78746

//--------------------------------------------------------
class OscReceiverController : public SceneController{
public:
    void setup();
    void oscMessageReceived(ofxOscMessage m);
    
    ofxOscReceiver receiver;
};

