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

class MapFeature: public ofNode {
public:
    MapFeature();
    enum FeatureType {
        POINT = 1,
        MESH = 2
    };
    int type;
    ofMesh mesh;
    ofNode point;
    
    ofColor color;
    ofColor labelColor;
    
    Json::Value properties;
};

#endif /* defined(__GeoSenseReliefClientOSX__MapFeature__) */
