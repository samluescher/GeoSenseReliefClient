#pragma once

#include "ofMain.h"
#include "ofEvents.h"
#include "SceneController.h"

#define KEY_PAN_VELOCITY 0.01f

//--------------------------------------------------------
class KeyboardController : public SceneController{
public:
    KeyboardController();
    void keyPressed(ofKeyEventArgs & args);
    void keyReleased(ofKeyEventArgs & args);
};

