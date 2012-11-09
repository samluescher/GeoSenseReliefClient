//
//  MapFeature.h
//
//  Created by Samuel Lüscher on 7/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#include "ofMain.h"

class MapFeature: public ofNode {
    
    public:
        float normVal;
        float width;
        float height;
        ofColor color;

    void customDraw();
};
