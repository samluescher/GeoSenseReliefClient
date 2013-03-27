#pragma once

#include "ofMain.h"
#include "ofEvents.h"
#include "ofxEasingFunc.h"

#define EASING_TIME .5f
#define MIN_EASE_VELOCITY .005f

//--------------------------------------------------------
class SceneController{
    public:
        virtual void update();
        bool panEase;
        float panEaseStart;
    
        ofVec3f panVelocity;
        ofEvent<ofVec3f> onPan;
        ofEvent<float> onZoom;
        ofEvent<ofNode> onViewpointChange;

        template<class ListenerClass>
        void registerEvents(ListenerClass * listener){
            ofAddListener(onPan, listener, &ListenerClass::onPan);
            ofAddListener(onZoom, listener, &ListenerClass::onZoom);
            ofAddListener(onViewpointChange, listener, &ListenerClass::onViewpointChange);
        }

};

