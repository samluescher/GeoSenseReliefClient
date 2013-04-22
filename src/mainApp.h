#pragma once

#include "ofMain.h"
#include "ofEvents.h"
#include "TargetConditionals.h"
#include "ofEasyCam.h"
#include "ofxFensterManager.h"

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
#define TERRAIN_OPACITY 1.f
#else 
#define TERRAIN_OPACITY 1.f
#endif

#include "OscReceiverController.h"
#include "LeapController.h"

#include "MouseController.h"
#include "MapFeatureLayer.h"
#include "TerrainLayer.h"
#include "ofxJSONElement.h"
#include "ReliefClientBase.h"
#include "ofxOsc.h"

#include "ofxUI.h"
#include "config.h"
#include "Timeline.h"

#include "ofxFX.h"



#include <time.h>

//class MouseController;

class mainApp : public ReliefClientBase{
	
public:
    void setup();
    void setupGUI();
    void setupLayers();
    void setupViewports();
    void updateGUI();
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
   
    
    bool drawDebugEnabled;
    
    
    Timeline timeline;
    
    void setCalibrationMode(bool state);
    
    MouseController mouseController;
    OscReceiverController oscReceiverController;
    LeapController leapController;
    
    #if !(TARGET_OS_IPHONE)
    KeyboardController keyboardController;
    #endif
    
    void onPan(const void* sender, ofVec3f & distance);
    void onLook(const void* sender, ofVec3f & distance);
    void onZoom(const void* sender, float & factor);
    void onSwipe(GestureEventArgs & args);
    void onCircle(GestureEventArgs & args);
    void onTapDown(GestureEventArgs & args);
    void onTapScreen(GestureEventArgs & args);
    void onViewpointChange(const void* sender, MapWidget & viewpoint);
    
    ofVboMesh terrainVboMesh;
    ofImage terrainCrop, sendMap, featureMap, featureMapCrop, featureHeightMap;
    ofVec2f terrainSW, terrainNE, terrainSE, terrainNW, terrainCenterOffset, waterSW, waterNE;
    ofVec3f terrainToHeightMapScale;
    float sendMapResampledValues[RELIEF_SIZE_X * RELIEF_SIZE_Y];
    ofVec2f normalizedMapCenter, normalizedReliefSize;
    float terrainPeakHeight, featureHeight;
    ofVec3f surfaceAt(ofVec2f pos);
    float waterLevel, prevWaterLevel;
    bool isPanning;
    
    ofFbo screenFbo;
    ofxGlow glow;
    
    std::vector<MapWidget*> mapWidgets;
    
    ofVboMesh mapFeaturesMesh;
    void urlResponse(ofHttpResponse & response);
    void addItemsFromJSONString(string jsonStr);
    int numLoading;
    
    /*void loadFeaturesFromURL(string url);*/
    void loadFeaturesFromFile(string filePath);
    
    float gridSize;
    
    std::vector<MapFeatureLayer *> featureLayers;
    std::vector<TerrainLayer *> terrainLayers;
    std::vector<TerrainLayerCollection *> terrainOverlays;

    TerrainLayer *addTerrainLayerFromHeightMap(string name, string heightmap, string texture, float peakHeight);
    TerrainLayer *addTerrainLayer(string name);
    TerrainLayerCollection *addTerrainOverlay(string name);
    TerrainLayer *createTerrainOverlayItem(string name, ofVec3f p1, ofVec3f p2, float depth, string texture);
    TerrainLayer *focusLayer;

    MapFeatureLayer* addMapFeaturelayer(string title);
    MapFeatureCollection* loadFeaturesFromGeoJSONURL(string url, string title, MapFeatureLayer* layer);
    MapFeatureCollection* loadFeaturesFromGeoJSONFile(string filePath, string title);
    MapFeatureCollection* loadFeaturesFromGeoJSONURL(string url, string title);
    
    std::map<string, MapFeatureCollection*> urlToMapFeatureCollectionIndex;
    MapFeatureCollection* addFeaturesFromGeoJSONString(string jsonStr, MapFeatureCollection *coll);
    void setFeatureLayerVisible(int index, bool visible);
    void setTerrainLayerVisible(int index, bool visible);
    void setTerrainOverlayVisible(int index, bool visible);
    

    std::vector<ofLight *> lights;
    
    ofVec2f touchPoint;
    int deviceOrientation;
    float startTime;
    float terrainUnitToGlUnit, realworldUnitToGlUnit, realworldUnitToTerrainUnit;
    bool calibrationMode, zoomMode;
    float timeSinceLastDoubleTap;
    ofVec3f reliefToMarker1Offset, reliefToMarker2Offset;
    ofVec2f terrainExtents;
    
    ofMatrix4x4 modelViewMatrix, projectionMatrix;
    int noMarkerSince;
    
    ofVec3f mapCenter, newMapCenter;
    /*ofEasyCam cam;*/
    void resetCam(ofCamera& cam);
    
    int selectedViewport = 0;
    
    void drawIdentity(int viewport);
    void drawTerrain(int viewport);
    void drawTerrainOverlays(int viewport);
    void drawGrid(int viewport, ofVec2f sw, ofVec2f ne, int subdivisionsX, int subdivisionsY, ofColor line);
    void drawGrid(int viewport, ofVec2f sw, ofVec2f ne, int subdivisionsX, int subdivisionsY, ofColor line, ofColor background);

    void drawReliefGrid(int viewport);
    void drawReliefFrame(int viewport);
    void drawTerrainGrid(int viewport);
    void drawLights(int viewport);
    void drawMapFeatures(int viewport);
    void drawMapWidgets(int viewport);

    void drawGUI();
    
    void drawWorld(int viewport, bool externalMatrix);
    void updateVisibleMap(bool updateServer);

    ofxXmlSettings settings;
    
    void loadSettings();
    void saveSettings();
    
    
    void reliefMessageReceived(ofxOscMessage m);
    void updateRelief();
    int reliefSendMode;
    
    int cursorNotMovedSince;
    
    int animateLight;
    float animateLightStart;
    ofVec3f animateLightStartPos;
    
    int animatePlate;
    float animatePlateStart;
    ofVec3f animatePlateStartPos;
    
#if (TARGET_OS_IPHONE)
    ofPinchGestureRecognizer *pinchRecognizer;
    void handlePinch(ofPinchEventArgs &e);
#endif 
    
	ofxUICanvas *calibrationGUI, *layersGUI;
    void guiEvent(ofxUIEventArgs &e);
    
    ofxRipples rip;
    ofxBounce bounce;
};

