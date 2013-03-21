//
//  MapFeature.cpp
//
//  Created by Samuel Lüscher on 7/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#include "MapFeatureLayer.h"

void MapFeatureLayer::customDraw() {
    for (int i = 0; i < featureMeshes.size(); i++) {
        ofMesh mesh = featureMeshes.at(i);
        mesh.setMode(OF_PRIMITIVE_LINE_LOOP);
        mesh.draw();
    }
}
