#pragma once

#include "ofMain.h"
#include "TargetConditionals.h"

#if (TARGET_OS_IPHONE)
#include "ofxQCAR.h"
#include "ofxQCAR_Utils.h"
#include "ofxiPhone.h"
#include "ofxiPhoneExtras.h"
#include "ofPinchGestureRecognizer.h"
#define USE_QCAR true
#else
#define USE_QCAR false
#endif

#include "MapFeature.h"
#include "ofxJSONElement.h"
#include "ReliefClientBase.h"
#include "ofxOsc.h"

#include "ofxUI.h"
#include "config.h"

class testApp : public ReliefClientBase{
	
public:
    void setup();
    void update();
    void draw();
    void exit();
	
#if (TARGET_OS_IPHONE)
    void touchDown(ofTouchEventArgs & touch);
    void touchMoved(ofTouchEventArgs & touch);
    void touchUp(ofTouchEventArgs & touch);
    void touchDoubleTap(ofTouchEventArgs & touch);
    void touchCancelled(ofTouchEventArgs & touch);
    
    void lostFocus();
    void gotFocus();
    void gotMemoryWarning();
    void deviceOrientationChanged(int newOrientation);
#else
	void keyPressed(int key);
	void keyReleased(int key);
    
	void mouseMoved(int x, int y );
	void mouseDragged(int x, int y, int button);
	void mousePressed(int x, int y, int button);
	void mouseReleased(int x, int y, int button);
	void windowResized(int w, int h);
	void dragEvent(ofDragInfo dragInfo);
	void gotMessage(ofMessage msg);
#endif
    
    void setCalibrationMode(bool state);
    
    ofVboMesh terrainVboMesh;
    ofImage terrainTex, terrainTexAlpha, heightMap, terrainCrop, sendMap, featureMap, featureMapCrop, featureHeightMap;
    ofVec2f terrainSW, terrainNE, terrainCenterOffset;
    ofVec3f terrainToHeightMapScale;
    float sendMapResampledValues[RELIEF_SIZE_X * RELIEF_SIZE_Y];
    ofVec2f normalizedMapCenter, normalizedReliefSize;
    float terrainPeakHeight, featureHeight;
    ofVec3f surfaceAt(ofVec2f pos);
    float waterLevel;
    bool isPanning;
    
    std::vector<MapFeature*> mapFeatures;
    ofVboMesh mapFeaturesMesh;
    void urlResponse(ofHttpResponse & response);
    void addItemsFromJSONString(string jsonStr);
    ofMesh getMeshFromFeatures(std::vector<MapFeature*> mapFeatures);
    int numLoading;
    void loadFeaturesFromURL(string url);
    void loadFeaturesFromFile(string filePath);
    float gridSize;
    
    ofLight light;
    
    ofVec2f touchPoint;
    int deviceOrientation;
    
    float terrainUnitToScreenUnit, reliefUnitToScreenUnit, reliefUnitToTerrainUnit;
    bool calibrationMode, zoomMode;
    float timeSinceLastDoubleTap;
    ofVec3f reliefOffset, reliefToMarker1Offset, reliefToMarker2Offset;
    float globalScale;
    ofVec2f terrainExtents;
    
    ofMatrix4x4 modelViewMatrix, projectionMatrix;
    int noMarkerSince;
    
    ofVec3f mapCenter, newMapCenter;
    ofEasyCam cam;
    void resetCam(); 
    
    void drawIdentity();
    void drawTerrain(bool transparent, bool wireframe);
    void drawGrid(ofVec2f sw, ofVec2f ne, int subdivisionsX, int subdivisionsY, ofColor line);
    void drawGrid(ofVec2f sw, ofVec2f ne, int subdivisionsX, int subdivisionsY, ofColor line, ofColor background);
    void drawReliefGrid();
    void drawReliefFrame();
    void drawTerrainGrid();
    void drawMapFeatures();
    void drawGUI();
    void updateVisibleMap(bool updateServer);
    
    bool drawTerrainEnabled, drawTerrainGridEnabled, drawDebugEnabled, drawMapFeaturesEnabled, drawMiniMapEnabled, drawWaterEnabled, tetherWaterEnabled, fullscreenEnabled;
    
    void reliefMessageReceived(ofxOscMessage m);
    void updateRelief();
    int reliefSendMode;
    
    int cursorNotMovedSince;
    
    
#if (TARGET_OS_IPHONE)
    ofPinchGestureRecognizer *pinchRecognizer;
    void handlePinch(ofPinchEventArgs &e);
#endif 
    
	ofxUICanvas *calibrationGUI, *layersGUI;
    void guiEvent(ofxUIEventArgs &e);
};

