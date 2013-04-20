//
//  TimeLine.cpp
//  GeoSenseReliefClientOSX
//
//  Created by Samuel Luescher on 18.04.13.
//
//

#include "Timeline.h"

Timeline::Timeline() {
    cursorPos = 0;
}

void Timeline::customDraw() {
    float hw = width / 2;
    ofVec3f position = getPosition();
    ofSetLineWidth(4);
    ofCircle(position.x - hw + cursorPos * width, position.y, 4);
    ofSetLineWidth(1);
    ofLine(position.x - hw, position.y, position.x + hw, position.y);
    ofPopMatrix();
}

void Timeline::setCursorPos(float pos) {
    cursorPos = fmax(0, fmin(1, pos));
}

float Timeline::getCursorPos() {
    return cursorPos;
}
