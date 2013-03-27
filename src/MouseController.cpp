#include "MouseController.h"

#define MAP_MOVE_INC 0.1f
#define VELOCITY_DECAY 0.15
#define EASING_TIME 2.0f

MouseController::MouseController() {
    ofAddListener(ofEvents().keyPressed,this,&MouseController::keyPressed);
    ofRegisterMouseEvents(this);
}

//--------------------------------------------------------------
void MouseController::updateCenter(ofVec3f &center){
    dragVelocity *= 1-(VELOCITY_DECAY);
//    dragVelocity *= 2.2;
    float scaled = ofMap(ofGetElapsedTimef(),easeStartTime,easeStartTime+EASING_TIME,1,0,1);
    center += 0.22*dragVelocity*ofxEasingFunc::Quad::easeOut(scaled);
}

void MouseController::keyPressed(ofKeyEventArgs & args){
//    ofLog() << "KEY:" << args.key;
    switch (args.key) {
        case OF_KEY_LEFT:
            dragVelocity.set(MAP_MOVE_INC,0,0);
            easeStartTime = ofGetElapsedTimef();
            break;
        case OF_KEY_UP:
            dragVelocity.set(0,-MAP_MOVE_INC,0);
            easeStartTime = ofGetElapsedTimef();
            break;
        case OF_KEY_RIGHT:
            dragVelocity.set(-MAP_MOVE_INC,0,0);
            easeStartTime = ofGetElapsedTimef();
            break;
        case OF_KEY_DOWN:
            dragVelocity.set(0,MAP_MOVE_INC,0);
            easeStartTime = ofGetElapsedTimef();
            break;
    }; 
}

//--------------------------------------------------------------
void MouseController::mouseDragged(ofMouseEventArgs & args){
    //main->cam.disableMouseInput();
    if(args.button == 0) {
        dragVelocity = (ofVec3f(args.x,args.y,0)-previousMousePosition)*0.01;    
        dragVelocity.x = -dragVelocity.x;
    } if(args.button == 2) {
        dragVelocity.z += (args.y - previousMousePosition.y)*0.01;
    }
    
    easeStartTime = ofGetElapsedTimef();
    previousMousePosition.set(args.x,args.y,0);
}

//--------------------------------------------------------------
void MouseController::mousePressed(ofMouseEventArgs & args){
	previousMousePosition.set(args.x,args.y,0);
}

void MouseController::mouseReleased(ofMouseEventArgs & args){
    
}

void MouseController::mouseMoved(ofMouseEventArgs & args){
}

