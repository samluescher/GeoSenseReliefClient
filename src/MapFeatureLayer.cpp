#include "MapFeatureLayer.h"

MapFeatureLayer::MapFeatureLayer() {
    
}

void MapFeatureLayer::customDraw() {
    for (int i = 0; i < featureCollections.size(); i++) {
        MapFeatureCollection *coll = featureCollections.at(i);
        if (coll->visible) {
            coll->draw();
        }
    }
}

void MapFeatureLayer::drawLabels() {
    for (int i = 0; i < featureCollections.size(); i++) {
        MapFeatureCollection *coll = featureCollections.at(i);
        if (coll->visible) {
            coll->drawLabels();
        }
    }
}

void MapFeatureLayer::addFeatureCollection(MapFeatureCollection *coll) {
    featureCollections.push_back(coll);
}
