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
    void oscMessageReceived(ofxOscMessage m);
    bool horizontalPan, verticalPan;
};

