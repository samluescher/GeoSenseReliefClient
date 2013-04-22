//
//  MapFeatureLayer.h
//  GeoSenseReliefClientOSX
//
//  Created by Samuel Luescher on 3/8/13.
//
//

#include "WorldLayer.h"

class TerrainLayer: public WorldLayer {
    
public:
    ofVboMesh vboMesh;
    ofMesh mesh;
    
    ofImage textureImage, heightMap;
    ofTexture* texture;
    bool drawWireframe, drawTexture;
    
    void loadHeightMap(string filename, float peakHeight);
    void loadTexture(string filename);
    void setMesh(ofMesh m);
    ofTexture& getTextureReference();
    void setTextureReference(ofTexture& tex);
    void customDraw();
};

class TerrainLayerCollection: public WorldLayer {

public:
    vector<TerrainLayer*> terrainLayers;
    void addLayer(TerrainLayer* layer) {
        terrainLayers.push_back(layer);
    }
};
