//
//  MapFeature.h
//  GeoSenseReliefClientOSX
//
//  Created by Samuel Luescher on 19.04.13.
//
//

#ifndef __GeoSenseReliefClientOSX__MapFeature__
#define __GeoSenseReliefClientOSX__MapFeature__

#include "ofMain.h"
#include "ofxJSONElement.h"
#include "config.h"

class MapFeature: public ofNode {
public:
    MapFeature() {
        labelColor = COLOR_LABEL;
        labelShadowColor = COLOR_LABEL_SHADOW;
        labelColor = ofColor(255);
        color = ofColor(255);
    };
    enum FeatureType {
        POINT = 1,
        MESH = 2
    };
    int type;
    ofMesh mesh;
    ofNode point;
    
    float opacity;
    ofColor color;
    ofColor labelColor;
    ofColor labelShadowColor;
    
    Json::Value properties;
};

#endif /* defined(__GeoSenseReliefClientOSX__MapFeature__) */
