#pragma once

#include "ofMain.h"
#include "ofEvents.h"
#include "TargetConditionals.h"

#if (TARGET_OS_IPHONE)
#include "ofxQCAR.h"
#include "ofxQCAR_Utils.h"
#include "ofxiPhone.h"
#include "ofxiPhoneExtras.h"
#include "ofPinchGestureRecognizer.h"
#define USE_ARTK false
#define USE_QCAR !(USE_ARTK)
#else
#define USE_QCAR false
#define USE_ARTK false
#include "KeyboardController.h"
#endif

#if (USE_ARTK)
#include "ARTKController.h"
#endif

#include "OscReceiverController.h"

#include "MouseController.h"
#include "MapFeature.h"
#include "MapFeatureLayer.h"
#include "ofxJSONElement.h"
#include "ReliefClientBase.h"
#include "ofxOsc.h"

#include "ofxUI.h"
#include "config.h"

#include <time.h>

//class MouseController;

class mainApp : public ReliefClientBase{
	
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
    void moved();
#endif

    #if (USE_ARTK)
    ARTKController artkController;
    bool artkEnabled;
    #endif
    
    void setCalibrationMode(bool state);
    
    MouseController mouseController;
    OscReceiverController oscReceiverController;
    
    #if !(TARGET_OS_IPHONE)
    KeyboardController keyboardController;
    #endif
    
    void onPan(const void* sender, ofVec3f & distance);
    void onZoom(const void* sender, float & factor);
    void onViewpointChange(const void* sender, ofNode & viewpoint);
    
    ofVboMesh terrainVboMesh, terrainWaterMesh;
    ofImage terrainTex, heightMap, terrainCrop, sendMap, featureMap, featureMapCrop, featureHeightMap;
    ofVec2f terrainSW, terrainNE, terrainCenterOffset, waterSW, waterNE;
    ofVec3f terrainToHeightMapScale;
    float sendMapResampledValues[RELIEF_SIZE_X * RELIEF_SIZE_Y];
    ofVec2f normalizedMapCenter, normalizedReliefSize;
    float terrainPeakHeight, featureHeight;
    ofVec3f surfaceAt(ofVec2f pos);
    float waterLevel, prevWaterLevel;
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
    
    
    std::vector<MapFeatureLayer> featureLayers;
    

    void loadFeaturesFromGeoJSONFile(string filePath);
    void addFeatureLayerFromGeoJSONString(string jsonStr);    

    ofLight pointLight, directionalLight;
    
    ofVec2f touchPoint;
    int deviceOrientation;
    float startTime;
    float terrainUnitToScreenUnit, reliefUnitToScreenUnit, reliefUnitToTerrainUnit;
    bool calibrationMode, zoomMode;
    float timeSinceLastDoubleTap;
    ofVec3f reliefOffset, reliefToMarker1Offset, reliefToMarker2Offset;
    float globalScale;
    ofVec2f terrainExtents;
    
    ofMatrix4x4 modelViewMatrix, projectionMatrix;
    int noMarkerSince;
    
    ofVec3f mapCenter, newMapCenter;
//    ofCamera cam;
    ofCamera cam;
    void resetCam();
    
    void drawIdentity();
    void drawWater(float waterLevel);
    void drawTerrain(bool transparent, bool wireframe);
    void drawGrid(ofVec2f sw, ofVec2f ne, int subdivisionsX, int subdivisionsY, ofColor line);
    void drawGrid(ofVec2f sw, ofVec2f ne, int subdivisionsX, int subdivisionsY, ofColor line, ofColor background);
    void drawReliefGrid();
    void drawReliefFrame();
    void drawTerrainGrid();
    void drawMapFeatures();
    void drawGUI();
    void updateVisibleMap(bool updateServer);
    
    bool drawTerrainEnabled, drawTerrainGridEnabled, drawDebugEnabled, drawMapFeaturesEnabled, drawMiniMapEnabled, drawWaterEnabled, tetherWaterEnabled, fullscreenEnabled, lightingEnabled;
    
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

