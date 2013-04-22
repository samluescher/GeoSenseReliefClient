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
    setMesh(meshFromImage(heightMap, 1, peakHeight));
}

void TerrainLayer::setMesh(ofMesh m) {
    mesh = m;
    vboMesh = mesh;
}

void TerrainLayer::loadTexture(string filename) {
    ofLog() << "Loading texture: " << filename;
    textureImage.loadImage(filename);
    setTextureReference(textureImage.getTextureReference());
}

ofTexture& TerrainLayer::getTextureReference() {
    return textureImage.getTextureReference();
}

void TerrainLayer::setTextureReference(ofTexture& tex) {
    texture = &tex;
    drawTexture = true;
}

void TerrainLayer::customDraw() {
    ofSetColor(255, 255, 255, 255 * opacity);
    if (drawTexture) {
        texture->bind();
    }
    vboMesh.draw();
    if (drawTexture) {
        texture->unbind();
    }
    if (drawWireframe) {
        ofSetColor(50, 50, 50, 128);
        vboMesh.drawWireframe();
    }
}
