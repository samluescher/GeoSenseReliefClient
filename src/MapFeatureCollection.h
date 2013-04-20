#include "WorldLayer.h"
#include "MapFeature.h"

class MapFeatureCollection: public WorldLayer {
    
public:
    MapFeatureCollection();
    std::vector<ofVboMesh> featureVboMeshes;
    std::vector<MapFeature> features;
    float timelinePos;
    float pointRadius;
    void addFeatures(std::vector<MapFeature> feats);
    void addFeaturesFromGeoJSON(ofxJSONElement json);
    void customDraw();
    void drawLabels();
};
