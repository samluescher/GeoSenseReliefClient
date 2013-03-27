#pragma once

#include "ofMain.h"
#include "ofEvents.h"
#include "SceneController.h"

//--------------------------------------------------------
class MouseController : public SceneController{
	private:
        ofVec3f previousMousePosition;
    public:
        MouseController();
        //virtual void update();
        void mouseMoved(ofMouseEventArgs & args);
        void mouseDragged(ofMouseEventArgs & args);
        void mousePressed(ofMouseEventArgs & args);
        void mouseReleased(ofMouseEventArgs & args);
};

