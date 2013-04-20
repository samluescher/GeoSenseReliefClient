#include "WorldLayer.h"
#include "MapFeatureCollection.h"

class MapFeatureLayer: public WorldLayer {
    
public:
    MapFeatureLayer();
    std::vector<MapFeatureCollection *> featureCollections;
    void addFeatureCollection(MapFeatureCollection *coll);
    void customDraw();
    void drawLabels();
};
