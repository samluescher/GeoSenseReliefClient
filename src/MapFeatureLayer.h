//
//  MapFeatureLayer.h
//  GeoSenseReliefClientOSX
//
//  Created by Samuel Luescher on 3/8/13.
//
//

#include "WorldLayer.h"

class MapFeatureLayer: public WorldLayer {
    
public:
    std::vector<ofVboMesh> featureVboMeshes;
    void addMeshes(std::vector<ofMesh>);
    void customDraw();
};
