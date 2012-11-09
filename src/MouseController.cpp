#include "MouseController.h"

#define MAP_MOVE_INC 0.1f
#define VELOCITY_DECAY 0.15
#define EASING_TIME 2.0f

MouseController::MouseController() {
    ofAddListener(ofEvents().keyPressed,this,&MouseController::keyPressed);
    ofRegisterMouseEvents(this);
}

//--------------------------------------------------------------
void MouseController::update(ofCamera * camera) {
    dragVelocity *= 1-(VELOCITY_DECAY);
    float scaled = ofMap(ofGetElapsedTimef(),easeStartTime,easeStartTime+EASING_TIME,1,0,1);
    camera->move(dragVelocity*ofxEasingFunc::Quad::easeOut(scaled));  
}

void MouseController::keyPressed(ofKeyEventArgs & args){ 
    switch (args.key) {
        case 356:
            dragVelocity.set(MAP_MOVE_INC,0,0);
            easeStartTime = ofGetElapsedTimef();
            break;
        case 357:
            dragVelocity.set(0,0,MAP_MOVE_INC);
            easeStartTime = ofGetElapsedTimef();
            break;
        case 358:
            dragVelocity.set(-MAP_MOVE_INC,0,0);
            easeStartTime = ofGetElapsedTimef();
            break;
        case 359:
            dragVelocity.set(0,0,-MAP_MOVE_INC);
            easeStartTime = ofGetElapsedTimef();
            break;
    }; 
}

//--------------------------------------------------------------
void MouseController::mouseDragged(ofMouseEventArgs & args){
    if(args.button == 0) {
        dragVelocity = (ofVec3f(args.x,args.y,0)-previousMousePosition)*0.01;    
        dragVelocity.x = -dragVelocity.x;
    } if(args.button == 2) {
        dragVelocity.z += (args.y - previousMousePosition.y)*0.001;
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

