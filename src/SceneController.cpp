#include "SceneController.h"

void SceneController::update() {
    if (panVelocity.length() > 0) {
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
}
