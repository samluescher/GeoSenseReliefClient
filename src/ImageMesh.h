#include "ofMain.h"
#include <math.h>
#include "ofxEasingFunc.h"
#include <vector>
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
struct Face {
    ofVec3f nw, ne, sw, se;
    ofVec2f nwi, nei, swi, sei;
    ofVec3f normal;
};
struct Vertex {
    ofVec3f position;
    ofVec3f normal;
    Vertex(ofVec3f position, ofVec3f normal) {
        this->position = position;
        this->normal = normal;
    }
};
void addFace(ofMesh& mesh, Vertex a, Vertex b, Vertex c) {
    mesh.addVertex(a.position);
    mesh.addNormal(a.normal);
    mesh.addVertex(b.position);
    mesh.addNormal(b.normal);
    mesh.addVertex(c.position);
    mesh.addNormal(c.normal);
}

//--------------------------------------------------------------
void addFace(ofMesh& mesh, Vertex a, Vertex b, Vertex c, Vertex d) {
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
    
    vector< vector<Face> > meshFaces(width, vector<Face>(height));
    
    for(int y = 0; y < height - skip; y += skip) {
        for(int x = 0; x < width - skip; x += skip) {
            meshFaces[x][y].nw = getVertexFromImg(img, x, y, maxHeight);
            meshFaces[x][y].ne = getVertexFromImg(img, x + skip, y, maxHeight);
            meshFaces[x][y].sw = getVertexFromImg(img, x, y + skip, maxHeight);
            meshFaces[x][y].se = getVertexFromImg(img, x + skip, y + skip, maxHeight);
            
            meshFaces[x][y].nwi = ofVec2f(x / ws, y / hs);
            meshFaces[x][y].nei = ofVec2f((x + skip) / ws, y / hs);
            meshFaces[x][y].swi = ofVec2f(x / ws, (y + skip) / hs);
            meshFaces[x][y].sei = ofVec2f((x + skip) / ws, (y + skip) / hs);
            
            ofVec3f diag1 = meshFaces[x][y].ne - meshFaces[x][y].sw;
            ofVec3f diag2 = meshFaces[x][y].nw - meshFaces[x][y].se;
            diag1.normalize();
            diag2.normalize();
            meshFaces[x][y].normal = diag1.perpendicular(diag2);
            
        }
    }
    
    for(int y = 0; y < height - skip; y += skip) {
        for(int x = 0; x < width - skip; x += skip) {
            Face face = meshFaces[x][y];
            if(face.nw != zero && face.ne != zero && face.sw != zero && face.se != zero) {
                if(x == 0 || y == 0 || x == width - 2*skip || y == height - 2*skip) {
                    addFace(mesh, Vertex(face.nw, face.normal), Vertex(face.ne, face.normal), Vertex(face.se, face.normal), Vertex(face.sw, face.normal));
                    addTexCoords(mesh, face.nwi, face.nei, face.sei, face.swi);
                    numFaces += 1;
                    continue;
                }
                ofVec3f nwNormal(0.0, 0.0, 0.0);
                nwNormal += face.normal;
                nwNormal += meshFaces[x-1][y].normal;
                nwNormal += meshFaces[x-1][y-1].normal;
                nwNormal += meshFaces[x][y-1].normal;
                nwNormal /= 4.0;
                nwNormal.normalize();
                
                ofVec3f neNormal(0.0, 0.0, 0.0);
                neNormal += face.normal;
                neNormal += meshFaces[x+1][y].normal;
                neNormal += meshFaces[x+1][y-1].normal;
                neNormal += meshFaces[x][y-1].normal;
                neNormal /= 4.0;
                neNormal.normalize();
                
                ofVec3f seNormal(0.0, 0.0, 0.0);
                seNormal += face.normal;
                seNormal += meshFaces[x+1][y].normal;
                seNormal += meshFaces[x+1][y+1].normal;
                seNormal += meshFaces[x][y+1].normal;
                seNormal /= 4.0;
                seNormal.normalize();
                
                ofVec3f swNormal(0.0, 0.0, 0.0);
                swNormal += face.normal;
                swNormal += meshFaces[x-1][y].normal;
                swNormal += meshFaces[x-1][y+1].normal;
                swNormal += meshFaces[x][y+1].normal;
                swNormal /= 4.0;
                swNormal.normalize();
                addFace(mesh, Vertex(face.nw, nwNormal), Vertex(face.ne, neNormal), Vertex(face.se, seNormal), Vertex(face.sw, swNormal));
                addTexCoords(mesh, face.nwi, face.nei, face.sei, face.swi);
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
                    
                    addFace(mesh, Vertex(nwBot, normalBot), Vertex(neBot, normalBot), Vertex(seBot, normalBot), Vertex(swBot, normalBot));
                    
                    ofVec3f nwTop(nw.x, nw.y, waterLevelAfterOffset);
                    ofVec3f neTop(ne.x, ne.y, waterLevelAfterOffsetSkip);
                    ofVec3f swTop(sw.x, sw.y, waterLevelAfterOffset);
                    ofVec3f seTop(se.x, se.y, waterLevelAfterOffsetSkip);
                    
                    ofVec3f diagTop1 = neTop - swTop;
                    ofVec3f diagTop2 = nwTop - seTop;
                    diagTop1.normalize();
                    diagTop2.normalize();
                    ofVec3f normalTop = diagTop1.perpendicular(diagTop2);
                    
                    addFace(mesh, Vertex(nwTop, normalTop), Vertex(neTop, normalTop), Vertex(seTop, normalTop), Vertex(swTop, normalTop));
                    
                    numFaces += 2;
                    
                    if(x == xStart) { //west edge
                        ofVec3f diag1 = swTop - nw;
                        ofVec3f diag2 = nwTop - sw;
                        diag1.normalize();
                        diag2.normalize();
                        ofVec3f normal = diag1.perpendicular(diag2);
                        
                        addFace(mesh, Vertex(swTop, normal), Vertex(nwTop, normal), Vertex(nw, normal), Vertex(sw, normal));
                        numFaces++;
                    }
                    if(y == yStart) { //north edge
                        ofVec3f diag1 = nwTop - ne;
                        ofVec3f diag2 = neTop - nw;
                        diag1.normalize();
                        diag2.normalize();
                        ofVec3f normal = diag1.perpendicular(diag2);
                        
                        addFace(mesh, Vertex(nwTop, normal), Vertex(neTop, normal), Vertex(ne, normal), Vertex(nw, normal));
                        numFaces++;
                    }
                    if(x + skip >= xEnd) { //east edge
                        ofVec3f diag1 = seTop - ne;
                        ofVec3f diag2 = neTop - se;
                        diag1.normalize();
                        diag2.normalize();
                        ofVec3f normal = diag1.perpendicular(diag2);
                        
                        addFace(mesh, Vertex(seTop, normal), Vertex(neTop, normal), Vertex(ne, normal), Vertex(se, normal));
                        numFaces++;
                    }
                    if(y + skip >= yEnd) { //south edge
                        
                        ofVec3f diag1 = seTop - sw;
                        ofVec3f diag2 = swTop - se;
                        diag1.normalize();
                        diag2.normalize();
                        ofVec3f normal = diag1.perpendicular(diag2);
                        
                        addFace(mesh, Vertex(seTop, normal), Vertex(swTop, normal), Vertex(sw, normal), Vertex(se, normal));
                        numFaces++;
                    }
                }
            }
        }
    }
    //cout << "generated water mesh with faces: " << numFaces << "\n ";
    return mesh;
}
