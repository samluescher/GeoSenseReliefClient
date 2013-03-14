//
//  MapFeatureLayer.h
//  GeoSenseReliefClientOSX
//
//  Created by Samuel Luescher on 3/8/13.
//
//

#include "ofMain.h"

class MapFeatureLayer: public ofNode {
    
public:
    std::vector<ofMesh> featureMeshes;
    void customDraw();
};
