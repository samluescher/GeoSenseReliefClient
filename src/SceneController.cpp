#include "SceneController.h"

void SceneController::update() {
    if (panVelocity.length() > 0) {
        ofLog() << "pan";
        ofNotifyEvent(onPan, panVelocity, this);
    }
    if (panEase) {
        float decay = ofxEasingFunc::Quad::easeOut(1.0f - (ofGetElapsedTimef() - panEaseStart) / EASING_TIME);
        if (decay > 0) {
            panVelocity *= decay;
        } else {
            panVelocity.set(0);
        }
    } else {
        panVelocity.set(0);
    }

    if (lookVelocity.length() > 0) {
        ofLog() << "look";
        ofNotifyEvent(onLook, lookVelocity, this);
    }
    if (lookEase) {
        float decay = ofxEasingFunc::Quad::easeOut(1.0f - (ofGetElapsedTimef() - lookEaseStart) / EASING_TIME);
        if (decay > 0) {
            lookVelocity *= decay;
        } else {
            lookVelocity.set(0);
        }
    } else {
        lookVelocity.set(0);
    }
}
