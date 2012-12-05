#include "ofMain.h"
#include <math.h>
#include "ofxEasingFunc.h"
const float AMPLITUDE = 2.0;
const float DURATION = 2.0;
const float SPEED = 0.8;
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
float calcZOffset(float time, float startTime, float xCurrent, float xMin, float xMax) {
    float timeOffset = (xCurrent - xMin) / (xMax - xMin) * DURATION / SPEED;
    
    time -= timeOffset + startTime;
   
    if(time < 0 || time > 4*DURATION)
        return 0.0;
    else if(time <= DURATION) {
        return AMPLITUDE * ofxEasingFunc::Sine::easeInOut(time / DURATION);
    }
    else if(time <= 2*DURATION) {
        return AMPLITUDE * (1.0 - ofxEasingFunc::Sine::easeInOut(time / DURATION - 1.0));
    }
    else if(time <= 3*DURATION) {
        return -AMPLITUDE * ofxEasingFunc::Sine::easeInOut(time / DURATION - 2.0);
    }
    else {
        return -AMPLITUDE * (1.0 - ofxEasingFunc::Sine::easeInOut(time / DURATION - 3.0));
    }
}
//--------------------------------------------------------------
ofMesh meshFromImage(ofImage& img, int skip, float maxHeight) {
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
            if(nw != zero && ne != zero && sw != zero && se != zero) {
                
                ofVec3f diag1 = ne - sw;
                ofVec3f diag2 = nw - se;
                diag1.normalize();
                diag2.normalize();
                ofVec3f normal = diag1.perpendicular(diag2);
                
                addFace(mesh, nw, ne, se, sw);
                addTexCoords(mesh, nwi, nei, sei, swi);
                //mesh.addNormal(normal);
                
                numFaces += 1;
			}
		}
	}
	
    cout << "generated mesh with faces: " << numFaces << "\n ";
    return mesh;
}

ofMesh waterMeshFromImage(ofImage& img, float skip, float maxHeight, float waterLevel, ofVec2f waterSW, ofVec2f waterNE, float time, float startTime) {
	ofMesh mesh;
    
	mesh.setMode(OF_PRIMITIVE_TRIANGLES);
	int width = img.getWidth();
	int height = img.getHeight();
    double numFaces = 0;
    float ws = width;
    float hs = height;
	ofVec3f zero(0, 0, 0);
    
    //scans from north-south then west-east
    float xStart = waterSW.x + ws/2.0;
    float xEnd = waterNE.x + ws/2.0;
    float yStart = -waterNE.y + hs/2.0;
    float yEnd = -waterSW.y + hs/2.0;
    
    for(float y = yStart; y < yEnd; y += skip) { //north to south
		for(float x = xStart; x < xEnd; x += skip) { //west to east
			ofVec3f nw = getVertexFromImg(img, x, y, maxHeight);
			ofVec3f ne = getVertexFromImg(img, x + skip, y, maxHeight);
			ofVec3f sw = getVertexFromImg(img, x, y + skip, maxHeight);
			ofVec3f se = getVertexFromImg(img, x + skip, y + skip, maxHeight);
            
			if(nw != zero && ne != zero && sw != zero && se != zero) {
                float waterLevelAfterOffset = waterLevel + calcZOffset(time, startTime, x, xStart, xEnd);
                float waterLevelAfterOffsetSkip = waterLevel + calcZOffset(time, startTime, x+skip, xStart, xEnd);
                if(nw.z < waterLevelAfterOffset || ne.z < waterLevelAfterOffset || sw.z < waterLevelAfterOffset || se.z < waterLevelAfterOffset) {
                    ofVec3f nwBot(nw.x, nw.y, min(nw.z, waterLevel));
                    ofVec3f neBot(ne.x, ne.y, min(ne.z, waterLevel));
                    ofVec3f swBot(sw.x, sw.y, min(sw.z, waterLevel));
                    ofVec3f seBot(se.x, se.y, min(se.z, waterLevel));
                    
                    ofVec3f diagBot1 = neBot - swBot;
                    ofVec3f diagBot2 = nwBot - seBot;
                    diagBot1.normalize();
                    diagBot2.normalize();
                    ofVec3f normalBot = diagBot1.perpendicular(diagBot2);
                    
                    addFace(mesh, nwBot, neBot, seBot, swBot);
                    //mesh.addNormal(normalBot);
                    
                    ofVec3f nwTop(nw.x, nw.y, waterLevelAfterOffset);
                    ofVec3f neTop(ne.x, ne.y, waterLevelAfterOffsetSkip);
                    ofVec3f swTop(sw.x, sw.y, waterLevelAfterOffset);
                    ofVec3f seTop(se.x, se.y, waterLevelAfterOffsetSkip);
                    
                    ofVec3f diagTop1 = neTop - swTop;
                    ofVec3f diagTop2 = nwTop - seTop;
                    diagTop1.normalize();
                    diagTop2.normalize();
                    ofVec3f normalTop = diagTop1.perpendicular(diagTop2);
                    
                    addFace(mesh, nwTop, neTop, seTop, swTop);
                    //mesh.addNormal(normalTop);
                    
                    numFaces += 2;
                    
                    if(x == xStart) { //west edge
                        addFace(mesh, swTop, nwTop, nw, sw);
                        numFaces++;
                    }
                    if(y == yStart) { //north edge
                        addFace(mesh, nwTop, neTop, ne, nw);
                        numFaces++;
                    }
                    if(x + skip >= xEnd) { //east edge
                        addFace(mesh, seTop, neTop, ne, se);
                        numFaces++;
                    }
                    if(y + skip >= yEnd) { //south edge
                        addFace(mesh, seTop, swTop, sw, se);
                        numFaces++;
                    }
                }
			}
		}
	}
	
    //cout << "generated water mesh with faces: " << numFaces << "\n ";
    return mesh;
}
