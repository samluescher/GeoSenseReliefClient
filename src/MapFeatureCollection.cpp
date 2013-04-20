#include "MapFeatureCollection.h"
#include "config.h"

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

std::vector<MapFeature> featuresFromGeoJSON(ofxJSONElement &featureCollection)
{
    int size = featureCollection["features"].size();
    int numVerts = 0;
    std::vector<MapFeature> features;
    ofLog() << "features in FeatureCollection: " << size;
    for (int i = 0; i < size; i++) {
        const ofxJSONElement jsonFeature = featureCollection["features"][i];
        const Json::Value geometry = jsonFeature["geometry"];
        const Json::Value coordinates = jsonFeature["geometry"]["coordinates"];
        string featureType = jsonFeature["type"].asString();
        string geometryType = geometry["type"].asString();
        
        if (geometryType == "Polygon" || geometryType == "MultiLineString") {
            for (int j = 0; j < coordinates.size(); j++) {
                ofMesh mesh;
                MapFeature feature;
                std::vector<ofVec3f> verts = getVerticesFromCoordinates(coordinates[j]);
                if (geometryType == "Polygon") {
                    mesh.setMode(OF_PRIMITIVE_LINE_LOOP);
                } else if (geometryType == "MultiLineString") {
                    mesh.setMode(OF_PRIMITIVE_LINE_STRIP);
                }
                mesh.addVertices(verts);
                numVerts += verts.size();
                feature.type = feature.MESH;
                feature.mesh = mesh;
                feature.properties = jsonFeature["properties"];
                features.push_back(feature);
            }
        } else if (geometryType == "MultiPolygon") {
            for (int j = 0; j < coordinates.size(); j++) {
                for (int k = 0; k < coordinates[j].size(); k++) {
                    std::vector<ofVec3f> verts = getVerticesFromCoordinates(coordinates[j][k]);
                    ofMesh mesh;
                    MapFeature feature;
                    mesh.setMode(OF_PRIMITIVE_LINE_LOOP);
                    mesh.addVertices(verts);
                    feature.type = feature.MESH;
                    feature.mesh = mesh;
                    feature.properties = jsonFeature["properties"];
                    features.push_back(feature);
                    numVerts += verts.size();
                }
            }
        } else {
            MapFeature feature;
            feature.type = feature.POINT;
            feature.setPosition(getVecFromCoordinates(coordinates));
            feature.properties = jsonFeature["properties"];
            features.push_back(feature);
            numVerts++;
        }
        
    }
    
    ofLog() << "Generated features: " << features.size() << ", vertices: " << numVerts;
    return features;
}



MapFeatureCollection::MapFeatureCollection() {
    timelinePos = -1;
    pointRadius = .25;
}

void MapFeatureCollection::customDraw() {
    glLineWidth(LINE_WIDTH_MAP_FEATURES);
    for (int i = 0; i < featureVboMeshes.size(); i++) {
        ofSetColor(255, 255, 255, opacity * 255);
        featureVboMeshes.at(i).draw();
    }
    glLineWidth(1);
    for (int i = 0; i < features.size(); i++) {
        MapFeature feature = features.at(i);
        if (feature.type == feature.POINT && pointRadius > 0) {
            ofFill();
            ofCircle(feature.getPosition(), pointRadius);
        }
    }
    drawLabels();
}

void MapFeatureCollection::drawLabels() {
    for (int i = 0; i < features.size(); i++) {
        MapFeature feature = features.at(i);
        ofSetColor(feature.labelColor);
        string name = feature.properties["name"].asString();
        ofVec3f pos = feature.getPosition();
        if (feature.type == feature.POINT) {
            pos += pointRadius * 1.2;
        }
        if (name != "") {
            ofDrawBitmapString(name, pos);
            ofLog() << name << "  " << feature.getPosition();
            
        }
    }
}

void MapFeatureCollection::addFeatures(std::vector<MapFeature> feats) {
    int i;
    for (i = 0; i < feats.size(); i++) {
        MapFeature feature = feats.at(i);
        switch (feature.type) {
            {
            case feature.MESH:
                ofVboMesh vboMesh = feature.mesh;
                featureVboMeshes.push_back(vboMesh);
                break;
            }
        }
        features.push_back(feature);
    }
}

void MapFeatureCollection::addFeaturesFromGeoJSON(ofxJSONElement json) {
    addFeatures(featuresFromGeoJSON(json));
}

