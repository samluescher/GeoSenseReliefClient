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
    int numVerts = 0;
    std::vector<ofMesh> meshes;
    ofLog() << "features in FeatureCollection: " << size;
    for (int i = 0; i < size; i++) {
        const ofxJSONElement feature = featureCollection["features"][i];
        const Json::Value geometry = feature["geometry"];
        const Json::Value coordinates = feature["geometry"]["coordinates"];
        string featureType = feature["type"].asString();
        string geometryType = geometry["type"].asString();

        if (geometryType == "Polygon" || geometryType == "MultiLineString") {
            for (int j = 0; j < coordinates.size(); j++) {
                ofMesh mesh;
                std::vector<ofVec3f> verts = getVerticesFromCoordinates(coordinates[j]);
                if (geometryType == "Polygon") {
                    mesh.setMode(OF_PRIMITIVE_LINE_LOOP);
                } else if (geometryType == "MultiLineString") {
                    mesh.setMode(OF_PRIMITIVE_LINE_STRIP);
                }
                mesh.addVertices(verts);
                numVerts += verts.size();
                meshes.push_back(mesh);
            }
        } else if (geometryType == "MultiPolygon") {
            for (int j = 0; j < coordinates.size(); j++) {
                for (int k = 0; k < coordinates[j].size(); k++) {
                    std::vector<ofVec3f> verts = getVerticesFromCoordinates(coordinates[j][k]);
                    ofMesh mesh;
                    mesh.setMode(OF_PRIMITIVE_LINE_LOOP);
                    mesh.addVertices(verts);
                    meshes.push_back(mesh);
                    numVerts += verts.size();
                }
            }
        } else {
            ofLog() << "Ignoring geometry.type: " << geometryType;
        }
        
    }

    ofLog() << "Generated meshes: " << meshes.size() << ", vertices: " << numVerts;
    return meshes;
}

