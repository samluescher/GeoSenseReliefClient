#pragma once

#include "ofMain.h"
#include "ofxOsc.h"
#include "TargetConditionals.h"

#define RELIEF_HOST "18.111.18.106"
#define RELIEF_PORT 78746

#define RELIEF_SIZE_X 12
#define RELIEF_SIZE_Y 12
#define RELIEF_MAX_VALUE 255

#if (TARGET_OS_IPHONE)
#include "ofxiPhone.h"
class ReliefClientBase : public ofxiPhoneApp {
#else
    class ReliefClientBase : public ofBaseApp {
#endif
        
    public:
        ReliefClientBase();
        ~ReliefClientBase();
        void reliefSetup(string host, int port);
        void reliefUpdate();
        
        virtual void reliefMessageReceived(ofxOscMessage m);
        void reliefMessageSend(ofxOscMessage m);
        
        ofxOscSender reliefSender;
        ofxOscReceiver reliefReceiver;
        
        float lastHearbeat;
        
    };
