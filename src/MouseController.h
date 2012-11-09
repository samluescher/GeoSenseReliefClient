#pragma once

#include "ofMain.h"
#include "ofxEasingFunc.h"
#include "ofEvents.h"
#include "SceneController.h"

//--------------------------------------------------------
class MouseController : public SceneController{
	public:
        MouseController();
        void keyPressed(ofKeyEventArgs & args);
        void mouseMoved(ofMouseEventArgs & args);
        void mouseDragged(ofMouseEventArgs & args);
        void mousePressed(ofMouseEventArgs & args);
        void mouseReleased(ofMouseEventArgs & args);
        void update(ofCamera* camera);

        float easeStartTime;
        ofVec3f previousMousePosition;
        ofVec3f dragVelocity;
};

