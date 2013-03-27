#include "KeyboardController.h"

KeyboardController::KeyboardController() {
    ofRegisterKeyEvents(this);
}

void KeyboardController::keyPressed(ofKeyEventArgs & args){
    //    ofLog() << "KEY:" << args.key;
    switch (args.key) {
        case OF_KEY_LEFT:
            panVelocity.x = -KEY_PAN_VELOCITY;
            panEaseStart = ofGetElapsedTimef();
            panEase = true;
            break;
        case OF_KEY_UP:
            panVelocity.y = KEY_PAN_VELOCITY;
            panEaseStart = ofGetElapsedTimef();
            panEase = true;
            break;
        case OF_KEY_RIGHT:
            panVelocity.x = KEY_PAN_VELOCITY;
            panEaseStart = ofGetElapsedTimef();
            panEase = true;
            break;
        case OF_KEY_DOWN:
            panVelocity.y = -KEY_PAN_VELOCITY;
            panEaseStart = ofGetElapsedTimef();
            panEase = true;
            break;
    };
}

void KeyboardController::keyReleased(ofKeyEventArgs & args) {
}
