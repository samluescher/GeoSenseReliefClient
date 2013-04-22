#pragma once

#include "ofMain.h"
#include "ofEvents.h"
#include "SceneController.h"

#define KEY_PAN_VELOCITY 1.f

//--------------------------------------------------------
class KeyboardController : public SceneController{
public:
    KeyboardController();
    virtual void update();
    void keyPressed(ofKeyEventArgs & args);
    void keyReleased(ofKeyEventArgs & args);
};

