#pragma once

#include "ofMain.h"
#include "ofEvents.h"
#include "ofxEasingFunc.h"
#include "MapWidget.h"

#define EASING_TIME .5f
#define MIN_EASE_VELOCITY .005f

class GestureEventArgs : public ofEventArgs {
public:
    ofVec3f pos;
    ofVec3f startPos;
    ofVec3f normal;
    int state;
    float progress;

    enum GestureState {
        STATE_INVALID = -1, /**< An invalid state */
        STATE_START   = 1,  /**< The gesture is starting. Just enough has happened to recognize it. */
        STATE_UPDATE  = 2,  /**< The gesture is in progress. (Note: not all gestures have updates). */
        STATE_STOP    = 3,  /**< The gesture has completed or stopped. */
    };

};

//--------------------------------------------------------
class SceneController{
    public:
        virtual void update();
        bool panEase;
        float panEaseStart;
        bool lookEase;
        float lookEaseStart;
    
        ofVec3f panVelocity;
        ofVec3f lookVelocity;
    
        ofEvent<GestureEventArgs> onSwipe;
        ofEvent<GestureEventArgs> onCircle;
        ofEvent<GestureEventArgs> onTapDown;
        ofEvent<GestureEventArgs> onTapScreen;
        ofEvent<ofVec3f> onPan;
        ofEvent<ofVec3f> onLook;
        ofEvent<float> onZoom;
        ofEvent<MapWidget> onViewpointChange;

        template<class ListenerClass>
        void registerEvents(ListenerClass * listener){
            ofAddListener(onPan, listener, &ListenerClass::onPan);
            ofAddListener(onLook, listener, &ListenerClass::onLook);
            ofAddListener(onZoom, listener, &ListenerClass::onZoom);
            ofAddListener(onViewpointChange, listener, &ListenerClass::onViewpointChange);
            ofAddListener(onSwipe, listener, &ListenerClass::onSwipe);
            ofAddListener(onCircle, listener, &ListenerClass::onCircle);
            ofAddListener(onTapDown, listener, &ListenerClass::onTapDown);
            ofAddListener(onTapScreen, listener, &ListenerClass::onTapScreen);
        }

};

