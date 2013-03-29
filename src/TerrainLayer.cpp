//
//  TerrainLayer.cpp
//  GeoSenseReliefClientOSX
//
//  Created by Samuel Luescher on 3/28/13.
//
//

#include "TerrainLayer.h"
#include "ImageMesh.h"

void TerrainLayer::loadHeightMap(string filename, float peakHeight) {
    ofLog() << "Loading height map: " << filename;
    heightMap.loadImage(filename);
    vboMesh = meshFromImage(heightMap, 1, peakHeight);
}

void TerrainLayer::loadTexture(string filename) {
    ofLog() << "Loading texture: " << filename;
    textureImage.loadImage(filename);
    drawTexture = true;
}

void TerrainLayer::customDraw() {
    if (!drawWireframe) {
        ofSetColor(255, 255, 255, 255 * opacity);
        if (drawTexture) {
            textureImage.getTextureReference().bind();
        }
        vboMesh.draw();
        if (drawTexture) {
            textureImage.getTextureReference().unbind();
        }
    } else {
        ofSetColor(100, 100, 100, 20);
        vboMesh.drawWireframe();
    }
}
