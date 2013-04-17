//
//  MapFeature.cpp
//
//  Created by Samuel Lüscher on 7/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#include "MapFeatureLayer.h"

void MapFeatureLayer::customDraw() {
    for (int i = 0; i < featureVboMeshes.size(); i++) {
        featureVboMeshes.at(i).draw();
    }
}

void MapFeatureLayer::addMeshes(std::vector<ofMesh> meshes) {
    int i;
    for (i = 0; i < meshes.size(); i++) {
        ofVboMesh vboMesh = meshes.at(i);
        featureVboMeshes.push_back(vboMesh);
    }
}
