#include "ofMain.h"

/*
 This code demonstrates the difference between using an ofMesh and an ofVboMesh.
 The ofMesh is uploaded to the GPU once per frame, while the ofVboMesh is
 uploaded once. This makes it much faster to draw multiple copies of an
 ofVboMesh than multiple copies of an ofMesh.
 */

/*
 These functions are for adding quads and triangles to an ofMesh -- either
 vertices, or texture coordinates.
 */
//--------------------------------------------------------------
void addFace(ofMesh& mesh, ofVec3f a, ofVec3f b, ofVec3f c) {
	mesh.addVertex(a);
	mesh.addVertex(b);
	mesh.addVertex(c);
}

//--------------------------------------------------------------
void addFace(ofMesh& mesh, ofVec3f a, ofVec3f b, ofVec3f c, ofVec3f d) {
	addFace(mesh, a, b, c);
	addFace(mesh, a, c, d);
}

//--------------------------------------------------------------
void addTexCoords(ofMesh& mesh, ofVec2f a, ofVec2f b, ofVec2f c) {
	mesh.addTexCoord(a);
	mesh.addTexCoord(b);
	mesh.addTexCoord(c);
}

//--------------------------------------------------------------
void addTexCoords(ofMesh& mesh, ofVec2f a, ofVec2f b, ofVec2f c, ofVec2f d) {
	addTexCoords(mesh, a, b, c);
	addTexCoords(mesh, a, c, d);
}

/*
 The 3d data is stored in an image where alpha represents depth. Here we create
 a 3d point from the current x,y image position.
 */
//--------------------------------------------------------------
ofVec3f getVertexFromImg(ofImage& img, int x, int y, float maxHeight) {
	ofColor color = img.getColor(x, y);
	if(color.a > 0) {
		float z = ofMap(color.r, 0, 255, 0, maxHeight);
		return ofVec3f(x - img.getWidth() / 2, -y + img.getHeight() / 2, z);
	} else {
		return ofVec3f(0, 0, 0);
	}
}

//--------------------------------------------------------------
ofMesh meshFromImage(ofImage& img, int skip, float maxHeight, bool isWater, float waterLevel, ofVec2f swExtent, ofVec2f neExtent) {
	ofMesh mesh;
	// OF_PRIMITIVE_TRIANGLES means every three vertices create a triangle
	mesh.setMode(OF_PRIMITIVE_TRIANGLES);
	int width = img.getWidth();
	int height = img.getHeight();
    double numFaces;
    float ws = width;
    float hs = height;
	ofVec3f zero(0, 0, 0);
    
	for(int y = 0; y < height - skip; y += skip) {
		for(int x = 0; x < width - skip; x += skip) {
			/*
			 To construct a mesh, we have to build a collection of quads made up of
			 the current pixel, the one to the right, to the bottom right, and
			 beneath. These are called nw, ne, se and sw. To get the texture coords
			 we need to use the actual image indices.
			 */
			ofVec3f nw = getVertexFromImg(img, x, y, maxHeight);
			ofVec3f ne = getVertexFromImg(img, x + skip, y, maxHeight);
			ofVec3f sw = getVertexFromImg(img, x, y + skip, maxHeight);
			ofVec3f se = getVertexFromImg(img, x + skip, y + skip, maxHeight);
                        
			ofVec2f nwi(x / ws, y / hs);
			ofVec2f nei((x + skip) / ws, y / hs);
			ofVec2f swi(x / ws, (y + skip) / hs);
			ofVec2f sei((x + skip) / ws, (y + skip) / hs);
            
			// ignore any zero-data (where there is no depth info)
            int numZero = (nw == zero) + (ne == zero) + (sw == zero) + (se == zero);
			if(numZero == 0) {
                //terrain
                if(!isWater) {
                    addFace(mesh, nw, ne, se, sw);
                    addTexCoords(mesh, nwi, nei, sei, swi);
                    numFaces += 1;
                }
                //water
                else {
                    int numBelow = (nw.z < waterLevel) + (ne.z < waterLevel) + (sw.z < waterLevel) + (se.z < waterLevel);
                    if(numBelow > 0) {
                        
                        
                        ofVec3f nwBot(nw.x, nw.y, min(nw.z, waterLevel));
                        ofVec3f neBot(ne.x, ne.y, min(ne.z, waterLevel));
                        ofVec3f swBot(sw.x, sw.y, min(sw.z, waterLevel));
                        ofVec3f seBot(se.x, se.y, min(se.z, waterLevel));
                        
                        ofVec3f nwTop(nw.x, nw.y, waterLevel);
                        ofVec3f neTop(ne.x, ne.y, waterLevel);
                        ofVec3f swTop(sw.x, sw.y, waterLevel);
                        ofVec3f seTop(se.x, se.y, waterLevel);
                        
                        addFace(mesh, nwTop, neTop, seTop, swTop);
                        addFace(mesh, nwBot, neBot, seBot, swBot);
                        
                        numFaces += 2;
                    }
                }
			}
		}
	}
	
    cout << "generated mesh with faces: " << numFaces << "\n ";
    return mesh;
}
