//
//  util.h
//  GeoSenseReliefClientOSX
//
//  Created by Samuel Luescher on 3/5/13.
//
//

#ifndef GeoSenseReliefClientOSX_util_h
#define GeoSenseReliefClientOSX_util_h

#include "ofMain.h"

int getBrightness(ofColor c) {
    return MAX(MAX(c.r,c.g),c.b);
}

int getLightness(ofColor c) {
    return (c.r + c.g + c.b) / 3.f;
}

int getHue(ofColor c) {
    float max = MAX(MAX(c.r, c.g), c.b);
    float min = MIN(MIN(c.r, c.g), c.b);
    float delta = max-min;
    if (c.r==max) return (0 + (c.g-c.b) / delta) * 42.5;  //yellow...magenta
    if (c.g==max) return (2 + (c.b-c.r) / delta) * 42.5;  //cyan...yellow
    if (c.b==max) return (4 + (c.r-c.g) / delta) * 42.5;  //magenta...cyan
    return 0;
}

int getSaturation(ofColor c) {
    float min = MIN(MIN(c.r, c.g), c.b);
    float max = MAX(MAX(c.r, c.g), c.b);
    float delta = max-min;
    if (max!=0) return int(delta/max*255);
    return 0;
}

void copyImageWithScaledColors(ofImage &from, ofImage &to, float alphaScale, float saturationScale) {
    for (int y = 0; y < from.height; y++) {
        for (int x = 0; x < from.height; x++) {
            ofColor c = from.getColor(x, y);
            ofColor targetC = ofColor::fromHsb(getHue(c), getSaturation(c) * saturationScale, getBrightness(c));
            targetC.a = alphaScale * c.a;
            to.setColor(x, y, targetC);
        }
    }
}

#endif
