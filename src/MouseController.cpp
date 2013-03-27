#include "MouseController.h"

MouseController::MouseController() {
    ofRegisterMouseEvents(this);
}

void MouseController::mouseDragged(ofMouseEventArgs & args){
    if (args.button == 0) {
        panVelocity = ofVec3f(args.x, args.y, 0) - previousMousePosition;
        panVelocity.x = -panVelocity.x / ofGetWidth();
        panVelocity.y = panVelocity.y / ofGetHeight();
        panVelocity.z = 0;
    } if (args.button == 2) {
        panVelocity.x = 0;
        panVelocity.y = 0;
        panVelocity.z += (args.y - previousMousePosition.y) / ofGetHeight();
    }
    previousMousePosition.set(args.x, args.y, 0);
    panEaseStart = ofGetElapsedTimef();
    panEase = panVelocity.length() > MIN_EASE_VELOCITY;
}

void MouseController::mousePressed(ofMouseEventArgs & args){
	previousMousePosition.set(args.x,args.y,0);
}

void MouseController::mouseReleased(ofMouseEventArgs & args){
}

void MouseController::mouseMoved(ofMouseEventArgs & args){
}

