//
//  MapFeature.cpp
//
//  Created by Samuel Lüscher on 7/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#include "MapFeature.h"

void MapFeature::customDraw() {
    ofVec3f pos = getPosition();
    ofPushMatrix();
    ofTranslate(-pos);
    setScale(width, width, height);
    ofFill();
    ofSetColor(min(normVal * 255, 255.0f), 128, 200, 255);
    ofTranslate(0, 0, 0.5);
    ofBox(1);
    ofPopMatrix();
}
