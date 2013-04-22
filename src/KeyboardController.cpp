#include "KeyboardController.h"

KeyboardController::KeyboardController() {
    ofRegisterKeyEvents(this);
}

bool isKeyDown[1024];

void KeyboardController::keyPressed(ofKeyEventArgs & args) {
    ofLog() << "  " << args.key;
    isKeyDown[args.key] = true;
}

void KeyboardController::update() {
    bool shift = ofGetKeyPressed(32);
    
    ofVec3f vel;
    bool changed = false;
    if (shift) {
        vel = lookVelocity;
    } else {
        vel = panVelocity;
    }
    
    if (isKeyDown[OF_KEY_LEFT]) {
        vel.x = -KEY_PAN_VELOCITY;
        changed = true;
    }

    if (isKeyDown[OF_KEY_UP]) {
        vel.y = KEY_PAN_VELOCITY;
        changed = true;
     }
    
     if (isKeyDown[OF_KEY_RIGHT]) {
         vel.x = KEY_PAN_VELOCITY;
         changed = true;
     }
    
     if (isKeyDown[OF_KEY_DOWN]) {
         vel.y = -KEY_PAN_VELOCITY;
         changed = true;
     }
    
     if (isKeyDown[OF_KEY_PAGE_UP]) {
         vel.z = KEY_PAN_VELOCITY;
         changed = true;
     }

    if (isKeyDown[OF_KEY_PAGE_DOWN]) {
        vel.z = -KEY_PAN_VELOCITY;
        changed = true;
    }

    if (changed) {
        if (shift) {
            lookVelocity = vel;
            lookEaseStart = ofGetElapsedTimef();
            lookEase = true;
        } else {
            panVelocity = vel;
            panEaseStart = ofGetElapsedTimef();
            panEase = true;
        }
        
    }
  
    SceneController::update();
    
    /*    case OF_KEY_UP:
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
        case OF_KEY_PAGE_UP:
            panVelocity.z = KEY_PAN_VELOCITY;
            panEaseStart = ofGetElapsedTimef();
            panEase = true;
            break;
        case OF_KEY_PAGE_DOWN:
            panVelocity.z = -KEY_PAN_VELOCITY;
            panEaseStart = ofGetElapsedTimef();
            panEase = true;
            break;
    
    };*/
}

void KeyboardController::keyReleased(ofKeyEventArgs & args) {
    isKeyDown[args.key] = false;
}
