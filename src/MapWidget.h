//
//  MapFeature.h
//
//  Created by Samuel Lüscher on 7/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#include "ofMain.h"

class MapWidget: public ofNode {

private:
    ofColor baseColor;
    int initialLifetime, lifetime;
    
public:
    MapWidget();
    
    void customDraw();
    void update();
    void setBaseColor(ofColor color);
    void setLifetime(int frames);
    bool shouldRemove();
};
