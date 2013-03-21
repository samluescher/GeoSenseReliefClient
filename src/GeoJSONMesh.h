//
//  GeoJSON.h
//  GeoSenseReliefClientOSX
//
//  Created by Samuel Luescher on 3/8/13.
//
//

#include "ofMain.h"

ofVec3f getVecFromCoordinates(Json::Value coordinates) {
    int size = coordinates.size();
    ofVec3f vec;
    switch (size) {
        default:
        case 3:
            vec.z = coordinates[2U].asDouble();
        case 2:
            vec.y = coordinates[1U].asDouble();
        case 1:
            vec.x = coordinates[0U].asDouble();
            return vec;
        case 0:
            return vec;
    }
}

std::vector<ofVec3f> getVerticesFromCoordinates(Json::Value coordinates) {
    int size = coordinates.size();
    std::vector<ofVec3f> verts;
    for (int i = 0; i < size; i++) {
        if (coordinates[i].size() > 0) {
            if (coordinates[i][0U].type() == arrayValue) {
                std::vector<ofVec3f> childVerts = getVerticesFromCoordinates(coordinates[i]);
                for (int j = 0; j < childVerts.size(); j++) {
                    verts.push_back(childVerts.at(j));
                }
            } else {
                ofVec3f vec = getVecFromCoordinates(coordinates[i]);
                verts.push_back(vec);
            }
        }
    }
    return verts;
}

std::vector<ofMesh> geoJSONFeatureCollectionToMeshes(ofxJSONElement &featureCollection)
{
    int size = featureCollection["features"].size();
    std::vector<ofMesh> meshes;
    ofLog() << "features in FeatureCollection: " << size;
    for (int i = 0; i < size; i++) {
        const ofxJSONElement feature = featureCollection["features"][i];
        const Json::Value geometry = feature["geometry"];
        const Json::Value coordinates = feature["geometry"]["coordinates"];
        string featureType = feature["type"].asString();
        string geometryType = geometry["type"].asString();
        ofVboMesh mesh;
        if (featureType.compare("Polygon")) {
            mesh.setMode(OF_PRIMITIVE_LINE_LOOP);
            std::vector<ofVec3f> verts = getVerticesFromCoordinates(coordinates);
            for (int j = 0; j < verts.size(); j++) {
                mesh.addVertex(verts.at(j));
            }
            meshes.push_back(mesh);
        }
    }

    ofLog() << "Generated meshes: " << meshes.size();
    return meshes;
}

