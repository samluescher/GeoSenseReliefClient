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
    //ofVboMesh vboMesh;
    
    ofMesh mesh;
    ofVbo vbo;
    
    ofImage textureImage, heightMap;
    bool drawWireframe, drawTexture;
    
    void loadHeightMap(string filename, float peakHeight);
    void loadTexture(string filename);
    void customDraw();
};
