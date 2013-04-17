#include "mainApp.h"
#include "ofEvents.h"
#include "util.h"
#include "GeoJSONMesh.h"

#define NO_MARKER_TOLERANCE_FRAMES 10
#define GRID_SUBDIVISIONS 10
#define MAX_VAL 500.0f // for normalizing val -- this will come from db later
#define MINI_MAP_W 350
#define LIGHT_POS_INC .2
#define PAN_POS_INC .05
#define WATER_POS_INC 1

#define KEYBOARD_INC .2f


#define MIN_ZOOM 5 //300
#define MAX_ZOOM 200

#define fukushima ofVec2f(141.033247, 37.425252)

#define RELIEF_SEND_TERRAIN 1
#define RELIEF_SEND_FEATURES 2
#define RELIEF_SEND_OFF 0


ofVec3f mainApp::surfaceAt(ofVec2f pos) {
    /*
     ofVec2f normPos = (pos - terrainSW) / terrainExtents;
     if (normPos.x >= 0 && normPos.x <= 1 && normPos.y >= 0 && normPos.y <= 1) {
     ofColor c = heightMap.getColor(normPos.x * heightMap.width, heightMap.height - normPos.y * heightMap.height);
     return ofVec3f(pos.x, pos.y, 0);
     }
     */
    return ofVec3f(pos.x, pos.y, 0);
}

//--------------------------------------------------------------
void mainApp::setup() 
{
    //ofSetLogLevel(OF_LOG_VERBOSE);
    
#if (USE_QCAR)
    ofLog() << "*** Initializing QCAR";
    [ofxQCAR_Utils getInstance].targetType = TYPE_FRAMEMARKERS;
    ofxQCAR * qcar = ofxQCAR::getInstance();
    qcar->autoFocusOn();
    qcar->setup();
    noMarkerSince = -NO_MARKER_TOLERANCE_FRAMES;
#endif
    
    #if (USE_ARTK)
    artkEnabled = true;
    ofLog() << "artkEnabled = " << artkEnabled;
    #endif
    
    startTime = ofGetElapsedTimef();
    
    terrainSW = ofVec2f(128, 28);
    terrainNE = ofVec2f(150, 46);
    waterSW = ofVec2f(20, 10);
    waterNE = ofVec2f(40, 40);
    terrainExtents = ofVec2f(terrainNE.x - terrainSW.x, terrainNE.y - terrainSW.y);
    ofLog() << "terrainExtents: " << terrainExtents.x << "," << terrainExtents.y;
    ofVec2f center = terrainSW + terrainExtents / 2;
    terrainCenterOffset = ofVec3f(center.x, center.y, 0); 
    mapCenter = fukushima - ofVec3f(2.75, 0, 0); // initially center on off-shore Fukushima
    
    terrainUnitToGlUnit = 1 / GL_UNIT_TO_TERRAIN_UNIT_INITIAL;
    realworldUnitToGlUnit = 3.5f;
    globalScale = ofVec3f(1.f, 1.f, 1.f);

    #if (IS_DESK_CEILING)
    globalScale = ofVec3f(.95f, .95f, .95f);
    #endif

    #if (IS_RELIEF_CEILING)
    // offset of physical Relief to physical marker
    reliefOffset = ofVec3f(0, 0, 0);
    reliefToMarker1Offset = ofVec3f(0, 265, 0);
    reliefToMarker2Offset = ofVec3f(-275, 0, 0);

    reliefOffset.x = -30.5;
    reliefOffset.y = 94.25;
    globalScale = ofVec3f(1.27f, 1.27f, 1.27f);
    #endif
    
    ofEnableNormalizedTexCoords();
    
    float s = terrainExtents.x / 880; //heightMap.width;
    terrainToHeightMapScale = ofVec3f(s, s, 1);
    terrainToHeightMapScale.z = (terrainToHeightMapScale.x + terrainToHeightMapScale.y) / 2;
    ofLog() << "terrainToHeightMapScale: " << terrainToHeightMapScale;

    terrainPeakHeight = terrainToHeightMapScale.z * 350.0f;
    featureHeight = .5f;

    
	fingerMovie.loadMovie("movies/tsunami-propagation.mov");
    
    
    
    ofLog() << " *** Creating terrain layers";
    float seaFloorPeakHeight = terrainPeakHeight * 13;
    TerrainLayer *layer;
    
    layer = addTerrainLayer("CRUST", "maps/heightmap.ASTGTM2_128,28,149,45-1600-with-water.png", "maps/srtm.ASTGTM2_128,28,149,45-14400-with-water.png", terrainPeakHeight);
    layer->setScale(1);

    layer = addTerrainLayer("PLATES", "maps/heightmap.ETOPO1_128,28,149,45-downsampled-blur.png", "maps/greenblue.ETOPO1_128,28,149,45.png", seaFloorPeakHeight);
    layer->move(ofVec3f(0, 0, -(seaFloorPeakHeight + terrainPeakHeight * .2)));
    layer->setScale(ofVec3f(focusLayer->heightMap.getWidth() / layer->heightMap.getWidth(), focusLayer->heightMap.getHeight() / layer->heightMap.getHeight(), 1));

    /*
    layer = addTerrainLayer("J PLATE", "maps/bathymetry_128,28,149,45-1600-j-plate.png", "maps/ocean.blue_128,28,149,45-1600.png", seaFloorPeakHeight);
    layer->move(ofVec3f(0, 0, -(seaFloorPeakHeight + terrainPeakHeight * .2)));
    layer->setScale(ofVec3f(focusLayer->heightMap.getWidth() / layer->heightMap.getWidth(), focusLayer->heightMap.getHeight() / layer->heightMap.getHeight(), 1));

    layer = addTerrainLayer("P PLATE", "maps/bathymetry_128,28,149,45-1600-p-plate.png", "maps/ocean.blue_128,28,149,45-1600.png", seaFloorPeakHeight);
    layer->move(ofVec3f(0, 0, -(seaFloorPeakHeight + terrainPeakHeight * .2)));
    layer->setScale(ofVec3f(focusLayer->heightMap.getWidth() / layer->heightMap.getWidth(), focusLayer->heightMap.getHeight() / layer->heightMap.getHeight(), 1));*/
    
    layer = addTerrainLayer("MANTLE", "maps/heightmap.mantle.png", "maps/mantle.png", terrainPeakHeight);
    layer->move(ofVec3f(0, 0, -(terrainPeakHeight + seaFloorPeakHeight + terrainPeakHeight * .1)));
    layer->setScale(ofVec3f(focusLayer->heightMap.getWidth() / layer->heightMap.getWidth(), focusLayer->heightMap.getHeight() / layer->heightMap.getHeight(), 1));
    //layer->lighting = false;
 
    
    ofSetSmoothLighting(true);
    lightAttenuation = LIGHT_ATTENUATION;
    animateLight = -1;
    animatePlate = -1;
    
    ofLight* pointLight = new ofLight();
	pointLight->setPointLight();
    pointLight->setPosition(mapCenter + ofVec3f(3, -4, 5));
    pointLight->setDiffuseColor( ofColor(255.f, 255.f, 255.f));
	pointLight->setSpecularColor( ofColor(255.f, 255.f, 255.f));
    lights.push_back(pointLight);

    pointLight = new ofLight();
	pointLight->setPointLight();
    pointLight->setPosition(mapCenter + ofVec3f(-3, 1, 1));
    pointLight->setDiffuseColor( ofColor(255.f, 255.f, 255.f));
	pointLight->setSpecularColor( ofColor(255.f, 255.f, 255.f));
    lights.push_back(pointLight);

    numLoading = 0;
    ofRegisterURLNotification(this);  
    //loadFeaturesFromURL("http://map.safecast.org/api/mappoints/4ff47bc60aea6a01ec00000f?b=&"+ofToString(terrainSW.x)+"b="+ofToString(terrainSW.y)+"&b="+ofToString(terrainNE.x)+"&b="+ofToString(terrainNE.y)+"&z=8");
    
    //loadFeaturesFromFile("json/safecast.8.json");
    //loadFeaturesFromFile("json/earthquakes.json");
    
    // ripple (from ofxFX)
    rip.allocate(555,555);
    
    
    loadFeaturesFromGeoJSONFile("json/japan-prefectures.json");
    loadFeaturesFromGeoJSONFile("json/plateboundaries.json");
    loadFeaturesFromGeoJSONFile("json/tsunamiinundationmerge_jpf.json");
    
    for (int i = 0; i < featureLayers.size(); i++) {
        MapFeatureLayer *layer = featureLayers.at(i);
        layer->visible = i == 0;
    }
    
    #if (TARGET_OS_IPHONE)
    EAGLView *view = ofxiPhoneGetGLView();  
    pinchRecognizer = [[ofPinchGestureRecognizer alloc] initWithView:view];
    ofAddListener(pinchRecognizer->ofPinchEvent,this, &mainApp::handlePinch);
    #endif
    
    drawDebugEnabled = true;
    drawWireframesEnabled = false;
    calibrationMode = false;
    drawTerrainEnabled = false;
    drawTexturesEnabled = true;
    drawVideoEnabled = true;
    drawAnimationEnabled = false;
    drawTerrainGridEnabled = false;
    drawMapFeaturesEnabled = true;
    drawMiniMapEnabled = false;
    drawWaterEnabled = false;
    tetherWaterEnabled = false;
    waterLevel = 0.3;
    prevWaterLevel = 0.0;
    reliefSendMode = RELIEF_SEND_OFF;
    fullscreenEnabled = false;
    dualscreenEnabled = false;
    lightingEnabled = false;
    ofSetFullscreen(fullscreenEnabled);
    
#if (IS_RELIEF_CEILING)
    drawMiniMapEnabled = false;
    drawWaterEnabled = true;
#endif
    
    float guiW = 350;
    float spacing = OFX_UI_GLOBAL_WIDGET_SPACING;
#if (TARGET_OS_IPHONE)
    float dim = 100; // Retina resolution
	layersGUI->setWidgetFontSize(OFX_UI_FONT_LARGE);
#else
    float dim = 16;
#endif
    
#if (IS_RELIEF_CEILING)
    cam.enableOrtho();
#endif
    
    layersGUI = new ofxUICanvas(spacing, spacing, guiW, ofGetHeight());
    for (int i = 0; i < terrainLayers.size(); i++) {
        TerrainLayer *layer = terrainLayers.at(i);
        layersGUI->addToggle(layer->layerName, layer->visible, dim, dim);
    }
	layersGUI->addWidgetDown(new ofxUILabel("", OFX_UI_FONT_LARGE));
    for (int i = 0; i < featureLayers.size(); i++) {
        MapFeatureLayer *layer = featureLayers.at(i);
        layersGUI->addToggle(layer->layerName, layer->visible, dim, dim);
    }
	layersGUI->addWidgetDown(new ofxUILabel("", OFX_UI_FONT_LARGE));

#if !(TARGET_OS_IPHONE)
	layersGUI->addToggle("FULLSCREEN", fullscreenEnabled, dim, dim);
	layersGUI->addToggle("DUALSCREEN", dualscreenEnabled, dim, dim);
	layersGUI->addToggle("ORTHOGONAL", cam.getOrtho(), dim, dim);
    //    layersGUI->addButton("RESET CAMERA", false, dim, dim);
#endif
    layersGUI->addToggle("LIGHTING", lightingEnabled, dim, dim);
    layersGUI->addSlider("ATTENUATION", 0, 1.5, lightAttenuation, guiW - spacing * 2, dim);
	layersGUI->addWidgetDown(new ofxUILabel("", OFX_UI_FONT_LARGE));
    layersGUI->addSlider("ZOOM", MIN_ZOOM, MAX_ZOOM, 1 / terrainUnitToGlUnit, guiW - spacing * 2, dim);
	layersGUI->addWidgetDown(new ofxUILabel("", OFX_UI_FONT_LARGE));
	layersGUI->addWidgetDown(new ofxUILabel("", OFX_UI_FONT_LARGE)); 
	layersGUI->addToggle("TERRAIN", drawTerrainEnabled, dim, dim);
	layersGUI->addToggle("TEXTURES", drawTexturesEnabled, dim, dim);
	layersGUI->addToggle("GRID", drawTerrainGridEnabled, dim, dim);
	layersGUI->addToggle("FEATURES", drawMapFeaturesEnabled, dim, dim);
	layersGUI->addToggle("MINIMAP", drawMiniMapEnabled, dim, dim);
	layersGUI->addToggle("WATER", drawWaterEnabled, dim, dim);
    layersGUI->addSlider("WATER LEVEL", 0, 5.0, waterLevel, guiW - spacing * 2, dim);
    #if (USE_QCAR || USE_ARTK)
	layersGUI->addToggle("VIDEO", drawVideoEnabled, dim, dim);
    #endif
	layersGUI->addToggle("DEBUG", drawDebugEnabled, dim, dim);
	layersGUI->addToggle("WIREFRAMES", drawWireframesEnabled, dim, dim);
    
	layersGUI->addWidgetDown(new ofxUILabel("", OFX_UI_FONT_LARGE)); 
	layersGUI->addWidgetDown(new ofxUILabel("", OFX_UI_FONT_LARGE)); 
	layersGUI->addWidgetDown(new ofxUILabel("RELIEF SERVER", OFX_UI_FONT_LARGE));
	layersGUI->addToggle("SEND TERRAIN", reliefSendMode == RELIEF_SEND_TERRAIN, dim, dim);
	layersGUI->addToggle("SEND FEATURES", reliefSendMode == RELIEF_SEND_FEATURES, dim, dim);
    
    /*
     layersGUI->addWidgetDown(new ofxUILabel("", OFX_UI_FONT_LARGE)); 
     layersGUI->addWidgetDown(new ofxUILabel("", OFX_UI_FONT_LARGE)); 
     layersGUI->addWidgetDown(new ofxUILabel("SIMULATION", OFX_UI_FONT_LARGE)); 
     layersGUI->addToggle("TETHER WATER", tetherWaterEnabled, dim, dim);
     */
    
    layersGUI->setDrawBack(true);
    layersGUI->setColorBack(ofColor(60, 60, 60, 100));
	ofAddListener(layersGUI->newGUIEvent,this,&mainApp::guiEvent);
    
    guiW = 500;
    calibrationGUI = new ofxUICanvas(0, 0, guiW, ofGetHeight());     
	calibrationGUI->addWidgetDown(new ofxUILabel("RELIEF SERVER", OFX_UI_FONT_LARGE)); 
	calibrationGUI->setWidgetFontSize(OFX_UI_FONT_LARGE);
	calibrationGUI->addWidgetDown(new ofxUILabel("HOST", OFX_UI_FONT_MEDIUM));
	calibrationGUI->addTextInput("RELIEF_HOST", RELIEF_HOST, guiW - spacing * 2);
    
	calibrationGUI->addTextInput("RELIEF_PORT", ofToString(RELIEF_PORT), guiW - spacing * 2);    
    
    calibrationGUI->setDrawBack(true);
    calibrationGUI->setColorBack(ofColor(60, 60, 60, 100));
    calibrationGUI->setVisible(false);
	calibrationGUI->addToggle("RECEIVING", false, dim, dim);
	calibrationGUI->addWidgetDown(new ofxUILabel("", OFX_UI_FONT_LARGE)); 
	calibrationGUI->addWidgetDown(new ofxUILabel("", OFX_UI_FONT_LARGE)); 

    calibrationGUI->addSlider("REAL WORLD SCALE", realworldUnitToGlUnit * .33f, realworldUnitToGlUnit * 3, realworldUnitToGlUnit, guiW - spacing * 2, dim);
    
    #if (USE_ARTK)
    calibrationGUI->addSlider("VIDEO THRESH", 0, 255, artkController.videoThreshold, guiW - spacing * 2, dim);
    #if (USE_LIBDC)
    calibrationGUI->addSlider("VIDEO EXPOSURE", 0, 1, artkController.camera.getExposure(), guiW - spacing * 2, dim);
    calibrationGUI->addSlider("VIDEO GAIN", 0, 2, artkController.camera.getGain(), guiW - spacing * 2, dim);
    #endif
    #endif
    
	calibrationGUI->addWidgetDown(new ofxUILabel("", OFX_UI_FONT_LARGE));
	calibrationGUI->addWidgetDown(new ofxUILabel("", OFX_UI_FONT_LARGE));
    
    calibrationGUI->addSlider("GLOBAL SCALE", .1, 4, globalScale.x, guiW - spacing * 2, dim);
    calibrationGUI->addSlider("GLOBAL SCALE X", .1, 4, globalScale.x, guiW - spacing * 2, dim);
    calibrationGUI->addSlider("GLOBAL SCALE Y", .1, 4, globalScale.y, guiW - spacing * 2, dim);
    calibrationGUI->addSlider("RELIEF OFFSET X", -200, 200, reliefOffset.x, guiW - spacing * 2, dim);
    calibrationGUI->addSlider("RELIEF OFFSET Y", -200, 200, reliefOffset.y, guiW - spacing * 2, dim);
    calibrationGUI->addSlider("RELIEF OFFSET Z", -200, 200, reliefOffset.z, guiW - spacing * 2, dim);
	ofAddListener(calibrationGUI->newGUIEvent,this,&mainApp::guiEvent);
    
    resetCam();

    #if !(TARGET_OS_IPHONE)
    ofEnableSmoothing();    
    #endif

    mouseController.registerEvents(this);
    oscReceiverController.registerEvents(this);
    //oscReceiverController.verticalPan = true;
    leapController.registerEvents(this);

    #if !(TARGET_OS_IPHONE)
    keyboardController.registerEvents(this);
    #endif

    //post.init(ofGetWidth(), ofGetHeight());
    //post.createPass<BloomPass>()->setEnabled(true);

    cursorNotMovedSince = 0;
    
    int width = ofGetWidth();
    int height = ofGetHeight();
    
    glow.allocate(width, height);
    screenFbo.allocate(width, height);
    
}

void mainApp::onSwipe(GestureEventArgs & args) {
    if (args.state == args.STATE_STOP) {
        int dir = args.pos.x > args.startPos.x;
        ofLog() << "swiped "  << (dir == 1 ? "right" : "left") << " " << args.pos;

        int firstVisible = -1, setVisible = 0;
        for (int i = 0; i < featureLayers.size(); i++) {
            MapFeatureLayer *layer = featureLayers.at(i);
            if (layer->visible) {
                firstVisible = i;
                break;
            }
        }
        if (dir == 1) {
            setVisible = firstVisible < 0 ? 0 :
            firstVisible < featureLayers.size() - 1 ? firstVisible + 1 : 0;
        } else {
            setVisible = firstVisible < 0 ? 0 :
            firstVisible > 0 ? firstVisible - 1 : featureLayers.size() - 1;
        }
        ofLog() << " set visible: " << (dir == 1 ? " >> " : " << ") << setVisible;
        for (int i = 0; i < featureLayers.size(); i++) {
            MapFeatureLayer *layer = featureLayers.at(i);
            setFeatureLayerVisible(i, i == setVisible);
        }
    }
}

void mainApp::onCircle(GestureEventArgs & args) {
    ofLog() << "circled " << args.progress;
}

void mainApp::onTapDown(GestureEventArgs & args) {
    ofLog() << "tapped down " << args.pos;

    #define LEAP_OFFSET ofVec3f(0, 100, 0)
    
    MapWidget *widget = new MapWidget();
    ofVec3f mappedPos = (ofVec3f(args.pos.x, -args.pos.z, 1)
        + LEAP_OFFSET)
        * realworldUnitToTerrainUnit;
    ofLog() << mappedPos << "  " << realworldUnitToTerrainUnit;
    widget->setPosition(mapCenter + mappedPos);
    widget->setLifetime(20);
    mapWidgets.push_back(widget);
}

void mainApp::onTapScreen(GestureEventArgs & args) {
    ofLog() << "tapped screen " << args.pos;
}

void mainApp::onPan(const void* sender, ofVec3f & distance) {
    //cout << "onPan: " << distance << "\n";
    mapCenter += distance;
    updateVisibleMap(true);
    for (int i = terrainLayers.size() - 1; i >= 0; i--) {
        TerrainLayer* layer = terrainLayers.at(0);
        float deltaZ = mapCenter.z - layer->getPosition().z;
        if (deltaZ < 0) {
            layer->opacity = min(1.f, 1 / abs(deltaZ) * .05f);
        } else {
            layer->opacity = 1.f;
        }
    }
}

void mainApp::onZoom(const void* sender, float & factor) {
    cout << "onZoom: " << factor << "\n";
    updateVisibleMap(true);
}

void mainApp::onViewpointChange(const void* sender, MapWidget & viewpoint) {
    cout << "onViewPointChange" << endl;
    cam.setPosition(viewpoint.getPosition());
//    cam.lookAt(viewpoint.getLookAtDir());
    
    bool addNew = true;
    MapWidget *widget;
    for (int i = 0; i < mapWidgets.size(); i++) {
        widget = mapWidgets.at(i);
        if (widget->widgetName == viewpoint.widgetName && widget->widgetId == viewpoint.widgetId) {
            addNew = false;
            break;
        }
    }
    
    if (addNew) {
        widget = new MapWidget();
        mapWidgets.push_back(widget);
    }
    
    widget->setPosition(viewpoint.getLookAtDir()/realworldUnitToGlUnit);
    widget->setLifetime(50);
    widget->widgetId = viewpoint.widgetId;
    widget->widgetName = viewpoint.widgetName;
    
    
    
    
    //cout << "onViewpointChange: " << viewpoint.getOrientationEuler() << "\n";
}


void mainApp::resetCam()
{
    cam.reset();
    cam.setPosition(mapCenter + ofVec3f(0, 4, 2 / terrainUnitToGlUnit));
    cam.lookAt(mapCenter);
    
    
    //cam.update();
    //cam.disableMouseInput();
     
    update();
    updateVisibleMap(true);
}

void mainApp::setFeatureLayerVisible(int index, bool visible) {
    MapFeatureLayer *layer = featureLayers.at(index);
    layer->visible = visible;
    layersGUI->getWidget(layer->layerName)->setState(visible);
}

void mainApp::setTerrainLayerVisible(int index, bool visible) {
    TerrainLayer *layer = terrainLayers.at(index);
    layer->visible = visible;
    layersGUI->getWidget(layer->layerName)->setState(visible);
}

void mainApp::guiEvent(ofxUIEventArgs &e)
{
	string name = e.widget->getName(); 
	int kind = e.widget->getKind(); 
    
    if (name == "RESET CAMERA") {
        resetCam();
    }
    
    if (kind == OFX_UI_WIDGET_TOGGLE) {
        ofxUIToggle *toggle = (ofxUIToggle *) e.widget; 
        bool value = toggle->getValue(); 

        for (int i = 0; i < terrainLayers.size(); i++) {
            TerrainLayer *layer = terrainLayers.at(i);
            if (layer->layerName == name) {
                setTerrainLayerVisible(i, value);
                break;
            }
        }

        for (int i = 0; i < featureLayers.size(); i++) {
            MapFeatureLayer *layer = featureLayers.at(i);
            if (layer->layerName == name) {
                setFeatureLayerVisible(i, value);
                break;
            }
        }
        
        if (name == "FULLSCREEN") {
            fullscreenEnabled = value;
            ofSetFullscreen(fullscreenEnabled);
        }
        if (name == "DUALSCREEN") {
            dualscreenEnabled = value;
        }
        if (name == "LIGHTING") {
            lightingEnabled = value;
        }
        if (name == "ORTHOGONAL") {
            if (value) {
                cam.enableOrtho();
            } else {
                cam.disableOrtho();
            }
        }
        
        if (name == "TERRAIN") {
            drawTerrainEnabled = value;
        }
        if (name == "TEXTURES") {
            drawTexturesEnabled = value;
        }
        if (name == "WATER") {
            drawWaterEnabled = value;
            startTime = ofGetElapsedTimef();
        }
        if (name == "GRID") {
            drawTerrainGridEnabled = value;
        }
        if (name == "FEATURES") {
            drawMapFeaturesEnabled = value;
        }
        if (name == "MINIMAP") {
            drawMiniMapEnabled = value;
        }
        if (name == "VIDEO") {
            drawVideoEnabled = value;
        }
        if (name == "DEBUG") {
            drawDebugEnabled = value;
        }
        if (name == "WIREFRAMES") {
            drawWireframesEnabled = value;
        }
        
        if (name == "SEND TERRAIN") {
            if (value) {
                ofxUIToggle *other = (ofxUIToggle *)layersGUI->getWidget("SEND FEATURES");
                other->setValue(false);
                reliefSendMode = RELIEF_SEND_TERRAIN;
                updateVisibleMap(true);
            } else {
                reliefSendMode = RELIEF_SEND_OFF;
            }
        }
        if (name == "SEND FEATURES") {
            if (value) {
                ofxUIToggle *other = (ofxUIToggle *)layersGUI->getWidget("SEND TERRAIN");
                other->setValue(false);
                reliefSendMode = RELIEF_SEND_FEATURES;
                updateVisibleMap(true);
            } else {
                reliefSendMode = RELIEF_SEND_OFF;
            }
        }
    } else if (kind == OFX_UI_WIDGET_SLIDER_H) {
        ofxUISlider *slider = (ofxUISlider *) e.widget; 
        float value = slider->getScaledValue(); 
        if (name == "ATTENUATION") {
            lightAttenuation = value;
        }
        if (name == "ZOOM") {
            terrainUnitToGlUnit = 1 / value;
            updateVisibleMap(true);
        }
        if (name == "WATER LEVEL") {
            waterLevel = value; 
            ofxOscMessage message;
            message.setAddress("/relief/broadcast/waterlevel");
            message.addFloatArg(waterLevel);
            reliefMessageSend(message);
        }
        #if (USE_ARTK)
        if (name == "VIDEO THRESH") {
            artkController.videoThreshold = value;
        }
        #if (USE_LIBDC)
        if (name == "VIDEO EXPOSURE") {
            artkController.camera.setExposure(value);
        }
        if (name == "VIDEO GAIN") {
            artkController.camera.setGain(value);
        }
        #endif
        #endif
        if (name == "REAL WORLD SCALE") {
            realworldUnitToGlUnit = value;
            ofLog() << realworldUnitToGlUnit;
        }
        if (name == "GLOBAL SCALE") {
            globalScale = ofVec3f(value, value, value);
        }
        if (name == "GLOBAL SCALE X") {
            globalScale.x = value;
        }
        if (name == "GLOBAL SCALE Y") {
            globalScale.y = value;
        }
        if (name == "RELIEF OFFSET X") {
            reliefOffset.x = value; 
        }
        if (name == "RELIEF OFFSET Y") {
            reliefOffset.y = value; 
        }
        if (name == "RELIEF OFFSET Z") {
            reliefOffset.z = value; 
        }
    }
    
	cout << "got event from: " << name  << " " << kind << " " << OFX_UI_WIDGET_TOGGLE << endl; 	
}

void mainApp::update() 
{
    // ripple (from ofxFX)
    rip.begin();
    ofFill();
    ofSetColor(ofNoise( ofGetFrameNum() ) * 255 * 5, 255);
    ofEllipse(mouseX,mouseY, 10,10);
    rip.end();
    rip.update();
    
    
    fingerMovie.update();
    realworldUnitToTerrainUnit = realworldUnitToGlUnit / (1 / terrainUnitToGlUnit);
    
    for (int i = lights.size() - 1; i >= 0; i--) {
        ofLight* light = lights.at(i);
        if (animateLight == i) {
            float l = 4;
            float p = l * sin(ofGetElapsedTimef() - animateLightStart);
            p -= l / 2;
            light->setPosition(animateLightStartPos + ofVec3f(0, p, 0));
        }
    }

    for (int i = terrainLayers.size() - 1; i >= 0; i--) {
        TerrainLayer* layer = terrainLayers.at(i);
        if (animatePlate == i) {
            float l = 7;
            float p = l * cos(ofGetElapsedTimef() - animatePlateStart);
            float j = 0.0000000002;
            layer->setPosition(animatePlateStartPos + ofVec3f(0, p, 0) + ofVec3f(rand() * j, rand() * j, rand() * j));
        }
    }

    
    
    reliefUpdate();
    mouseController.update();

    #if !(TARGET_OS_IPHONE)
    keyboardController.update();
    #endif
    reliefUpdate();
    oscReceiverController.update();
    leapController.update();

    #if (USE_QCAR)
    ofxQCAR::getInstance()->update();
    #endif
    
    #if (USE_ARTK)
    if (artkEnabled) {
        artkController.update();
    }
    #endif
    
    cursorNotMovedSince++;
    if (!calibrationMode) {
        layersGUI->setVisible(cursorNotMovedSince < GUI_DISAPPEAR_FRAMES);
    }

    for (int i = 0; i < mapWidgets.size(); i++) {
        MapWidget *widget = mapWidgets.at(i);
        widget->update();
        if (widget->shouldRemove()) {
            mapWidgets.erase(mapWidgets.begin() + i);
            i--;
        }
    }
    
}

//--------------------------------------------------------------

void mainApp::drawWater(float waterLevel) {
    ofPushMatrix();
    ofTranslate(terrainSW + terrainExtents / 2);
    ofScale(terrainToHeightMapScale.x, terrainToHeightMapScale.y, terrainToHeightMapScale.z);
    
    ofSetColor(COLOR_WATER);
    
    terrainWaterMesh.draw();
    
    ofPopMatrix();
}

void mainApp::drawTerrain(bool wireframe) {
    if (lightingEnabled) {
        for (int i = lights.size() - 1; i >= 0; i--) {
            ofLight* light = lights.at(i);
            light->setAttenuation(lightAttenuation / globalScale.x);
            if (i == 0 || i == animateLight) {
                light->enable();
            } else {
                light->disable();
            }
            //ofLog() << 1 / terrainUnitToGlUnit / SCREEN_UNIT_TO_TERRAIN_UNIT_INITIAL;
        }
    }

    ofPushMatrix();
    ofTranslate(terrainSW + terrainExtents / 2);
    ofScale(terrainToHeightMapScale.x, terrainToHeightMapScale.y, terrainToHeightMapScale.z);
    int s = terrainLayers.size();

    ofEnableBlendMode(OF_BLENDMODE_ALPHA);
    
    if (drawDebugEnabled) {
        ofSetColor(0, 255, 255);
        ofSphere(mapCenter.x, mapCenter.y, mapCenter.z, 10);
    }
    
    for (int i = s - 1; i >= 0; i--) {
        TerrainLayer *layer = terrainLayers.at(i);
        if (layer->visible) {
            bool drawTexture = layer->drawTexture,
                visible = layer->visible;
            layer->drawTexture = drawTexture && drawTexturesEnabled && !wireframe;
            layer->visible = visible && layer->opacity > .1;
            layer->drawWireframe = wireframe;
            if (lightingEnabled && layer->lighting) {
                ofEnableLighting();
            } else {
                ofDisableLighting();
            }
            layer->draw();
            layer->drawTexture = drawTexture;
            layer->visible = visible;
        }
    }
    

    ofDisableBlendMode();
    ofPopMatrix();

    if (lightingEnabled) {
        ofDisableLighting();
    }
}

void mainApp::drawMapWidgets()
{
    for (int i = 0; i < mapWidgets.size(); i++) {
        MapWidget *widget = mapWidgets.at(i);
        widget->draw();
    }
}

void mainApp::drawMapFeatures()
{
    glLineWidth(LINE_WIDTH_MAP_FEATURES);
    ofEnableBlendMode(OF_BLENDMODE_ALPHA);
    ofSetColor(200, 250, 250, 150);
    
    for (int i = 0; i < featureLayers.size(); i++) {
        MapFeatureLayer *layer = featureLayers.at(i);
        if (layer->visible) {
            layer->draw();
        }
    }
}

void mainApp::drawLights() {
    float lightR = .25f;
    for (int i = lights.size() - 1; i >= 0; i--) {
        if (i == 0 || i == animateLight) {
            ofLight* light = lights.at(i);
            ofVec3f pos = light->getPosition();
            ofSetColor(light->getDiffuseColor());
    //        ofSphere(pos.x, pos.y, pos.z, lightR / 2);
            ofSetColor(light->getSpecularColor());
            ofLine(pos - ofVec3f(lightR, 0, 0), pos + ofVec3f(lightR, 0, 0));
            ofLine(pos - ofVec3f(0, lightR, 0), pos + ofVec3f(0, lightR, 0));
            ofLine(pos - ofVec3f(0, 0, lightR), pos + ofVec3f(0, 0, lightR));
            ofLine(pos - ofVec3f(lightR / 2, lightR / 2, 0), pos + ofVec3f(lightR / 2, lightR / 2, 0));
            ofLine(pos - ofVec3f(0, lightR / 2, lightR / 2), pos + ofVec3f(0, lightR / 2, lightR / 2));
        }
    
    }
    
}




void mainApp::draw() {
    ofSetColor(255);
    ofBackground(COLOR_BACKGROUND);

    if (drawAnimationEnabled) {
        fingerMovie.draw(-ofGetWidth()/2,-ofGetHeight()/2,ofGetWidth()*2,ofGetHeight()*2);
        fingerMovie.play();
        
    }

    int w = ofGetWidth();
    int h = ofGetHeight();
    if (dualscreenEnabled) {
        w /= 2;
        h = w * 3 / 4;
        drawWorld(false, w, 0, w, h);
    }
    drawWorld(USE_ARTK || USE_QCAR, 0, 0, w, h);

    if (!calibrationMode) {
        mainApp::drawGUI();
    }

    /*
    works ok -- but cam.begin() would prevent glow. look into that.
     
    ofEnableAlphaBlending();
    screenFbo.begin();
    ofClear(0, 0, 0, 0);
    ofTranslate(ofGetWidth()/2, ofGetHeight()/2);
    drawMapFeatures();
    screenFbo.end();
    
    glow.setRadius(sin( ofGetElapsedTimef() ) * 15);
    glow.setTexture(screenFbo.getTextureReference());
    glow.update();
    
    ofEnableBlendMode(OF_BLENDMODE_ADD);
    glow.draw(0, 0);
    ofDisableAlphaBlending();
    */
    
    // ripple (from ofxFX)
    ofSetColor(255,255);
    
    rip.draw(0,0);
    ofDrawBitmapString("ofxRipples ( damping = " + ofToString(rip.damping) + " )", 15,15);
    


}

void mainApp::drawWorld(bool useARMatrix, int viewportX, int viewportY, int viewportW, int viewportH)
{
    int markerID = -1;
    
    if (useARMatrix) {
        #if (USE_QCAR)
        ofxQCAR * qcar = ofxQCAR::getInstance();
        qcar->draw();
        
        if (qcar->hasFoundMarker()) {
            string markerName = qcar->getMarkerName();
            if (markerName == "MarkerQ") {
                reliefOffset = reliefToMarker1Offset;
            } else if (qcar->getMarkerName() == "MarkerC") {
                reliefOffset = reliefToMarker2Offset;
            } else {
                reliefOffset = ofVec3f(0, 0, 0);
            }
            modelViewMatrix = qcar->getProjectionMatrix();
            projectionMatrix = qcar->getModelViewMatrix();
            noMarkerSince = 0;
        }
        //useARMatrix = noMarkerSince > -NO_MARKER_TOLERANCE_FRAMES;
        #elif (USE_ARTK)
        if (artkEnabled) {
            artkController.draw(drawVideoEnabled, drawDebugEnabled || calibrationMode, false);
        }
        #endif
    }
    
    ofPushView();
        
        if (useARMatrix) {
            #if (USE_QCAR)
            if (useARMatrix) {
                glMatrixMode(GL_PROJECTION);
                glLoadMatrixf(modelViewMatrix.getPtr());
                
                glMatrixMode(GL_MODELVIEW );
                glLoadMatrixf(projectionMatrix.getPtr());
            }
            #elif (USE_ARTK)
            markerID = artkController.artk.getMarkerID(0);
            artkController.applyMatrix(0);
            #endif
        } else {
            cam.begin();

        }

        glViewport(viewportX, viewportY, viewportW, viewportH);

        ofPushMatrix();
        
            #if (!USE_QCAR)
            if (cam.getOrtho()) {
                //ofTranslate(ofGetWidth() / 2, ofGetHeight() / 2, 0);
            }
            #endif
            
            /*ofTranslate(reliefOffset);*/
            ofScale(globalScale.x, globalScale.y, globalScale.z);
            
            #if (IS_RELIEF_CEILING)
            #endif
            
            ofPushMatrix();
                // first, we scale by the inverse of the terrain over screen unit ratio, which enables
                // us to subsequently use terrain units (degrees lng, lat) when drawing
                ofScale(1 / terrainUnitToGlUnit, 1 / terrainUnitToGlUnit, 1 / terrainUnitToGlUnit);

                if (useARMatrix) {
                    #if (USE_ARTK)
                    vector<ofVec3f> markerOffsets;
                    //markerOffsets.push_back(ofVec3f(-9.25f, 7.25f, 0));
                    //markerOffsets.push_back(ofVec3f(9.25f, 7.25f, 0));
                    markerOffsets.push_back(ofVec3f(-10.f, 7.5f, 0));
                    markerOffsets.push_back(ofVec3f(10.f, 7.5f, 0));
                    if (markerID >= 0 && markerID < markerOffsets.size()) {
                        ofTranslate(-markerOffsets.at(markerID));
                    }
                    #endif
                }
    
                ofPushMatrix();
                    // second, we translate by negative mapCenter so that we are not looking at [zero-meridian, equator]
                    // but at our region of interest instead.
                    ofTranslate(-mapCenter);

                    if (drawTerrainEnabled && !calibrationMode) {
                        glEnable(GL_DEPTH_TEST);
                        drawTerrain(false);
                        glDisable(GL_DEPTH_TEST);
                    }
                    
                    if (drawTerrainEnabled && (drawWireframesEnabled || calibrationMode)) {
                        drawTerrain(true);
                    }

                    if (drawWaterEnabled && !calibrationMode) {
                        ofEnableBlendMode(OF_BLENDMODE_ALPHA);
                        //terrainWaterMesh = waterMeshFromImage(heightMap, 1, terrainPeakHeight, waterLevel, waterSW, waterNE, ofGetElapsedTimef(), startTime);
                        //drawWater(waterLevel);
                    }
    
                    if (drawMapFeaturesEnabled && !calibrationMode) {
                        ofEnableBlendMode(OF_BLENDMODE_ADD);
                        drawMapFeatures();
                        ofDisableBlendMode();
                    }
    
                    ofEnableBlendMode(OF_BLENDMODE_ADD);
                    drawMapWidgets();
                    ofDisableBlendMode();
    
                    if (drawTerrainGridEnabled || calibrationMode) {
                        drawTerrainGrid();
                    }
        
                    if (drawDebugEnabled && lightingEnabled) {
                        drawLights();
                    }
    
                ofPopMatrix();


    
                if (drawDebugEnabled || calibrationMode) {
                    drawIdentity();
                }
    
            ofPopMatrix();
    
            if ((drawDebugEnabled && reliefSendMode != RELIEF_SEND_OFF) || calibrationMode) {
                drawReliefGrid();
            }
            
            #if (IS_RELIEF_CEILING)
            drawReliefFrame();
            #endif
        
        ofPopMatrix();
    
    ofPopView();

    if (useARMatrix) {
        #if (USE_QCAR)
        if (qcar->hasFoundMarker() && (drawDebugEnabled || calibrationMode)) {
            ofSetColor(255);
            qcar->drawMarkerCenter();
        }
        #elif (USE_ARTK)
        if (calibrationMode) {
            ofPushMatrix();
            ofTranslate((1 - globalScale.x) * ofGetWidth() * .5f, (1 - globalScale.y) * ofGetHeight() * .5f);
            ofScale(globalScale.x, globalScale.y, globalScale.z);
            artkController.draw(false, false, true);
            ofPopMatrix();
        }
        #endif
    } else {
        cam.end();
    }    
}

void mainApp::drawGUI() 
{
    if (drawMiniMapEnabled) {
        ofEnableBlendMode(OF_BLENDMODE_ALPHA);
#if (TARGET_OS_IPHONE)
        switch (deviceOrientation) {
            case OFXIPHONE_ORIENTATION_LANDSCAPE_RIGHT:
            case OFXIPHONE_ORIENTATION_LANDSCAPE_LEFT:
                break;
        }
#endif
        glLineWidth(1);
        
        float miniMapW = MINI_MAP_W;
        float miniMapUnitsToHeightMapUnits = miniMapW / (float)focusLayer->heightMap.width;
        float miniMapH = miniMapUnitsToHeightMapUnits * focusLayer->heightMap.height;
        ofVec2f p = ofVec2f(ofGetWidth() - miniMapW - OFX_UI_GLOBAL_WIDGET_SPACING, OFX_UI_GLOBAL_WIDGET_SPACING);
        ofFill();
        ofSetColor(COLOR_WATER);
        ofRect(p, miniMapW, miniMapH);
        ofSetColor(255);
        
        focusLayer->textureImage.draw(p, miniMapW, miniMapH);
        if (drawMapFeaturesEnabled && featureMap.isAllocated()) {
            featureMap.draw(p, miniMapW, miniMapH);
        }
        
        ofPushMatrix();
        ofTranslate(p.x, p.y + miniMapH);
        ofScale(miniMapW / terrainExtents.x, -miniMapH / terrainExtents.y);
        ofTranslate(-terrainSW);
        
        if (drawTerrainGridEnabled) {
            ofNoFill();
            ofSetColor(60, 60, 60, 100);
            for(int y = terrainSW.y; y < terrainNE.y; y++) {
                for(int x = terrainSW.x; x < terrainNE.x; x++) {
                    ofVec3f pos = ofVec3f(x, y);
                    ofRect(pos, 1, 1);
                }
            }
        }
        
        ofPopMatrix();
        
        ofPushMatrix();
        ofTranslate(p);
        
        ofNoFill();
        ofSetColor(255, 255, 255, 240);
        
        float marqueeW = normalizedReliefSize.x * miniMapW;
        float marqueeH = normalizedReliefSize.y * miniMapH;
        ofVec2f mapCenterOnMiniMap = normalizedMapCenter * ofVec2f(miniMapW, miniMapH);
        
        ofRect(mapCenterOnMiniMap - ofVec2f(marqueeW / 2, marqueeH / 2), marqueeW, marqueeH);
        ofCircle(mapCenterOnMiniMap, 4);
        ofPopMatrix();
        
        ofSetColor(255);
        int imgH = miniMapW / terrainCrop.width * terrainCrop.height;
        p += ofVec2f(0, miniMapH + OFX_UI_GLOBAL_WIDGET_SPACING);
        ofFill();
        ofSetColor(COLOR_WATER);
        ofRect(p, miniMapW, imgH);
        ofSetColor(255);
        terrainCrop.draw(p, miniMapW, imgH);
        if (drawMapFeaturesEnabled && featureMapCrop.width) {
            featureMapCrop.draw(p, miniMapW, imgH);
        }
        
        if (reliefSendMode != RELIEF_SEND_OFF) {
            p += ofVec2f(0, imgH + OFX_UI_GLOBAL_WIDGET_SPACING);
            ofSetColor(ofColor(60, 60, 60, 150));
            ofRect(p, miniMapW, imgH);
            ofSetColor(255);
            sendMap.draw(p, miniMapW, imgH);
            
            if (drawDebugEnabled) {
                p += ofVec2f(0, imgH + OFX_UI_GLOBAL_WIDGET_SPACING);
                float w = miniMapW / RELIEF_SIZE_X;
                float h = imgH / RELIEF_SIZE_Y;
                ofFill();
                for (int x = RELIEF_SIZE_X - 1; x >= 0; x--) {
                    for (int y = 0; y < RELIEF_SIZE_Y; y++) {
                        float avg = sendMapResampledValues[x + y * RELIEF_SIZE_Y];
                        ofSetColor(avg);
                        ofRect(p.x + x * w, p.y + y * h, w, h);
                    }
                }
            }
        }
        ofDisableBlendMode();
    }
    
    if (calibrationMode) {
        ofEnableBlendMode(OF_BLENDMODE_ALPHA);
        ofFill();
        ofSetColor(20, 20, 20, 150);
        ofRect(0, 0, ofGetWidth(), ofGetHeight());
        ofDisableBlendMode();
    }
    
    if (drawDebugEnabled) {
        string msg = "fps: " + ofToString(ofGetFrameRate(), 2) + ", features: " + ofToString(mapFeatures.size());
        msg += "\nterrain scale: " + ofToString(terrainToHeightMapScale);
        if (false/*numLoading > 0*/) {
            msg += "\nloading data";
        }
        
#if (USE_QCAR)
        ofxQCAR * qcar = ofxQCAR::getInstance();  
        if (qcar->hasFoundMarker()) {
            //msg += "\n" + qcar->getMarkerName();
        }
#endif
        
        if (calibrationMode) {
            msg += "\n---CALIBRATION MODE---";
            msg += "\nrealworldUnitToGlUnit: " + ofToString(realworldUnitToGlUnit);
            msg += "\nreliefOffset: " + ofToString(reliefOffset);
        }    
        
        ofVec2f consolePos = ofVec2f(ofGetWidth() / 2, 20);
        /*ofSetColor(0);
         ofDrawBitmapString(msg, consolePos.x + 1, consolePos.y + 1);
         ofDrawBitmapString(msg, consolePos.x - 1, consolePos.y - 1);*/
        ofSetColor(255);
        ofDrawBitmapString(msg, consolePos.x, consolePos.y);
    }
}

void mainApp::drawGrid(ofVec2f sw, ofVec2f ne, int subdivisionsX, int subdivisionsY, ofColor line, ofColor background) {
    ofFill();
    ofSetColor(background);
    ofRect(sw.x, sw.y, ne.x - sw.x, ne.y - sw.y);
    drawGrid(sw, ne, subdivisionsX, subdivisionsY, line);
}

void mainApp::updateVisibleMap(bool updateServer)
{
    
    normalizedMapCenter = (mapCenter - terrainSW) / terrainExtents;
    normalizedMapCenter.y = 1 - normalizedMapCenter.y;
    normalizedReliefSize = ofVec2f(RELIEF_SIZE_X * realworldUnitToTerrainUnit / terrainExtents.x, RELIEF_SIZE_Y * realworldUnitToTerrainUnit / terrainExtents.y);
    
    terrainCrop.allocate(normalizedReliefSize.x * focusLayer->textureImage.width, normalizedReliefSize.y * focusLayer->textureImage.height, OF_IMAGE_COLOR);
    featureMapCrop.allocate(normalizedReliefSize.x * featureMap.width, normalizedReliefSize.y * featureMap.height, OF_IMAGE_COLOR_ALPHA);
    
    terrainCrop.cropFrom(focusLayer->textureImage, -terrainCrop.width / 2 + normalizedMapCenter.x * focusLayer->textureImage.width, -terrainCrop.height / 2 + normalizedMapCenter.y * focusLayer->textureImage.height, terrainCrop.width, terrainCrop.height);

    if (featureMap.isAllocated()) {
        featureMapCrop.cropFrom(featureMap, -featureMapCrop.width / 2 + normalizedMapCenter.x * featureMap.width, -featureMapCrop.height / 2 + normalizedMapCenter.y * featureMap.height, featureMapCrop.width, featureMapCrop.height);
    }
    
    if (reliefSendMode != RELIEF_SEND_OFF) {
        ofImage sendMapFrom;
        if (reliefSendMode == RELIEF_SEND_TERRAIN) {
            sendMapFrom = focusLayer->heightMap;
        } else if (reliefSendMode == RELIEF_SEND_FEATURES) {
            sendMapFrom = featureHeightMap;
        }
        
        int sendMapWidth = normalizedReliefSize.x * sendMapFrom.width;
        int sendMapHeight = normalizedReliefSize.y * sendMapFrom.height;
        sendMap.allocate(sendMapWidth, sendMapHeight, OF_IMAGE_COLOR);
        
        sendMap.cropFrom(sendMapFrom, -sendMap.width / 2 + normalizedMapCenter.x * sendMapFrom.width, -sendMap.height / 2 + normalizedMapCenter.y * sendMapFrom.height, sendMap.width, sendMap.height);
        
        ofxOscMessage message;
        message.setAddress("/relief/set");
        float stepY = sendMap.height / RELIEF_SIZE_Y;
        float stepX = sendMap.width / RELIEF_SIZE_X;
        
        for (int x = RELIEF_SIZE_X - 1; x >= 0; x--) {
            for (int y = 0; y < RELIEF_SIZE_Y; y++) {
                
                int samp = 0;
                int fromX = x * stepX;
                int fromY = y * stepY;
                int toX = fromX + stepX;
                int toY = fromY + stepY;
                
                for (int sy = fromY; sy < toY; sy++) {
                    for (int sx = fromX; sx < toX; sx++) {
                        ofColor c = sendMap.getColor(sx, sy);
                        if (c.a > 0) {
                            samp += c.r;
                        }
                    }
                }
                
                float avg = samp / (float)(stepX * stepY);
                sendMapResampledValues[x + y * RELIEF_SIZE_Y] = avg;
                message.addIntArg(avg / 255 * RELIEF_MAX_VALUE);
            }
        }
        
        if (updateServer) {
            if (reliefSendMode != RELIEF_SEND_OFF) {
                reliefMessageSend(message);
            }
        }
    }
    
#if !(IS_RELIEF_CEILING)
    if (updateServer) {
        ofxOscMessage m;
        m.setAddress("/relief/broadcast/map/position");
        m.addFloatArg(mapCenter.x);
        m.addFloatArg(mapCenter.y);
        m.addFloatArg(terrainUnitToGlUnit);
        //ofLog() << "broadcast new map position";
        reliefMessageSend(m);
    }
#endif
}

void mainApp::reliefMessageReceived(ofxOscMessage m) 
{
    ofxUIToggle *indicator = (ofxUIToggle *)calibrationGUI->getWidget("RECEIVING");
    indicator->setValue(!indicator->getValue());
 
    oscReceiverController.oscMessageReceived(m);
    
    if (m.getAddress() == "/relief/broadcast/map/position") {
        ofLog() << "reliefMessageReceived from " << m.getRemoteIp() << ": " << m.getAddress();
        mapCenter.x = m.getArgAsFloat(0);
        mapCenter.y = m.getArgAsFloat(1);
        terrainUnitToGlUnit = m.getArgAsFloat(2);
        
        ofxUISlider *slider = (ofxUISlider *)layersGUI->getWidget("ZOOM");
        slider->setValue(1 / terrainUnitToGlUnit);
        
        ofLog() << "position: " << mapCenter << ", terrainUnitToGlUnit: " << terrainUnitToGlUnit;
        updateVisibleMap(false);
    }
    if (m.getAddress() == "/relief/broadcast/waterlevel") {
        waterLevel = m.getArgAsFloat(0);
        ofxUISlider *slider = (ofxUISlider *)layersGUI->getWidget("WATER LEVEL");
        slider->setValue(waterLevel);
        updateVisibleMap(false);
    }
}



void mainApp::drawGrid(ofVec2f sw, ofVec2f ne, int subdivisionsX, int subdivisionsY, ofColor line) {
    int index = 0;
    float step = 1 / (subdivisionsX >= 1 ? (float)subdivisionsX : 1);
    for (float x = sw.x; x <= ne.x; x += step) {
        if (index % subdivisionsX == 0) {
            glLineWidth(LINE_WIDTH_GRID_WHOLE);
            ofSetColor(line.r, line.g, line.b, line.a);
        } else {
            glLineWidth(LINE_WIDTH_GRID_SUBDIV);
            ofSetColor(line.r, line.g, line.b, line.a / 2);
        }
        ofLine(ofVec3f(x, sw.y, 0), ofVec3f(x, ne.y, 0));
        index++;
    }
    index = 0;
    step = 1 / (subdivisionsY >= 1 ? (float)subdivisionsX : 1);
    for (float y = sw.y; y <= ne.y; y += step) {
        if (index % subdivisionsY == 0) {
            glLineWidth(LINE_WIDTH_GRID_WHOLE);
            ofSetColor(line.r, line.g, line.b, line.a);
        } else {
            glLineWidth(LINE_WIDTH_GRID_SUBDIV);
            ofSetColor(line.r, line.g, line.b, line.a / 2);
        }
        ofLine(ofVec3f(sw.x, y, 0), ofVec3f(ne.x, y, 0));
        index++;
    }
}

void mainApp::drawTerrainGrid() {
    drawGrid(terrainSW, terrainNE, GRID_SUBDIVISIONS, GRID_SUBDIVISIONS, COLOR_GRID);
}

void mainApp::drawReliefGrid() 
{
    ofPushMatrix();
    ofScale(realworldUnitToGlUnit, realworldUnitToGlUnit, realworldUnitToGlUnit);
    float reliefScreenW = RELIEF_SIZE_X;
    float reliefScreenH = RELIEF_SIZE_Y;
    ofEnableBlendMode(OF_BLENDMODE_ALPHA);
    drawGrid(ofVec2f(-reliefScreenW / 2, -reliefScreenH / 2), ofVec2f(reliefScreenW / 2, reliefScreenH / 2), 1, 1, ofColor(200, 200, 200, 200), ofColor(255, 0, 0, 100));
    ofDisableBlendMode();
            
    ofPopMatrix();
}

void mainApp::drawReliefFrame() 
{
    ofPushMatrix();
    ofScale(realworldUnitToGlUnit, realworldUnitToGlUnit, realworldUnitToGlUnit);
    float reliefScreenW = RELIEF_SIZE_X;
    float reliefScreenH = RELIEF_SIZE_Y;
    
    ofFill();
    ofSetColor(0);
    float frameW = RELIEF_SIZE_X * 6;
    float frameH = RELIEF_SIZE_Y * 6;
    ofRect(ofVec2f(-frameW, -reliefScreenH / 2), frameW * 2, -frameH);
    ofRect(ofVec2f(-frameW, reliefScreenH / 2), frameW * 2, frameH);
    ofRect(ofVec2f(-reliefScreenW / 2, -frameH), -frameW, frameH * 2);
    ofRect(ofVec2f(reliefScreenW / 2, -frameH), frameW, frameH * 2);
    
    ofPopMatrix();
}

void mainApp::drawIdentity() {
    glLineWidth(LINE_WIDTH_GRID_WHOLE);
    ofSetColor(255, 0, 0);
    ofLine(ofVec3f(0, 0, 0), ofVec3f(1, 0, 0));
    ofSetColor(0, 255, 0);
    ofLine(ofVec3f(0, 0, 0), ofVec3f(0, 1, 0));
    ofSetColor(0, 0, 255);
    ofLine(ofVec3f(0, 0, 0), ofVec3f(0, 0, 1));
}


TerrainLayer * mainApp::addTerrainLayer(string name, string heightmap, string texture, float peakHeight) {
    TerrainLayer *layer = new TerrainLayer();
    layer->layerName = name;
    layer->loadHeightMap(heightmap, peakHeight);
    layer->loadTexture(texture);
    layer->opacity = TERRAIN_OPACITY;
    terrainLayers.push_back(layer);
    if (terrainLayers.size() == 1) {
        focusLayer = layer;
    }
    return layer;
}


void mainApp::loadFeaturesFromGeoJSONFile(string filePath) {
	ofFile file(filePath);
	if(!file.exists()){
		ofLogError("The file " + filePath + " is missing");
	}
	ofBuffer buffer(file);
	
	//Read file line by line
    string jsonStr;
	while (!buffer.isLastLine()) {
		jsonStr += buffer.getNextLine();
    }
    
    MapFeatureLayer* layer = addFeatureLayerFromGeoJSONString(jsonStr);
    if (layer != nil) {
        layer->layerName = ofFilePath::getFileName(filePath);
    }
}

//Parses a json string into map features
MapFeatureLayer* mainApp::addFeatureLayerFromGeoJSONString(string jsonStr) {
    ofxJSONElement json;
    if (json.parse(jsonStr)) {
        MapFeatureLayer *layer = new MapFeatureLayer();
        layer->addMeshes(geoJSONFeatureCollectionToMeshes(json));
        featureLayers.push_back(layer);
        return layer;
    } else {
        ofLog() << "Error parsing JSON";
    }
}






//Loads json data from a file
void mainApp::loadFeaturesFromFile(string filePath) {
	ofFile file(filePath);
	if(!file.exists()){
		ofLogError("The file " + filePath + " is missing");
	}
	ofBuffer buffer(file);
	
	//Read file line by line
    string jsonStr;
	while (!buffer.isLastLine()) {
		jsonStr += buffer.getNextLine();
    }
    
    addItemsFromJSONString(jsonStr);
}

void mainApp::loadFeaturesFromURL(string url) {
    cout << url << "\n";
    numLoading++;
    ofLoadURLAsync(url);
}

void mainApp::urlResponse(ofHttpResponse & response) {
    numLoading--;
    addItemsFromJSONString(response.data);
}

//Parses a json string into map features
void mainApp::addItemsFromJSONString(string jsonStr) {
    ofxJSONElement json;
    int xIndex = 0; int zIndex = 1; 
    if (json.parse(jsonStr)) {
        int size = json["items"].size();
        gridSize = json["gridSize"].asDouble();
        ofLog() << "map features loaded: " << size;
        for (int i = 0; i < size; i++) {
            const Json::Value item = json["items"][i];
            MapFeature *feature = new MapFeature();
            float lng = item["loc"][xIndex].asDouble();
            float lat = item["loc"][zIndex].asDouble();
            if (lng >= terrainSW.x && lng <= terrainNE.x && lat >= terrainSW.y && lat <= terrainNE.y) {
                feature->setPosition(surfaceAt(ofVec2f(lng, lat)));
                feature->normVal = item["val"]["avg"].asDouble() / MAX_VAL;
                feature->height = min(featureHeight, featureHeight * feature->normVal);
                feature->width = gridSize *.9;
                feature->color = ofColor(min(feature->normVal * 190, 255.0f), 128 + min(feature->normVal * 128, 128.0f), 200, 20);
#if (IS_RELIEF_CEILING)
                feature->color.a = 255;
#endif
                mapFeatures.push_back(feature);
            }
        }
        mapFeaturesMesh = getMeshFromFeatures(mapFeatures);
        
        featureMap.allocate(terrainExtents.x / gridSize, terrainExtents.y / gridSize, OF_IMAGE_COLOR_ALPHA);
        featureHeightMap.allocate(focusLayer->heightMap.width, focusLayer->heightMap.height, OF_IMAGE_COLOR_ALPHA);
        for (int i = 0; i < mapFeatures.size(); i++) {
            ofVec2f normPos = (mapFeatures[i]->getPosition() - terrainSW) / terrainExtents;
            normPos.y = 1 - normPos.y;
            featureMap.setColor(normPos.x * featureMap.width, normPos.y * featureMap.height, ofColor(mapFeatures[i]->color.r, mapFeatures[i]->color.g, mapFeatures[i]->color.b, 255));
            featureHeightMap.setColor(normPos.x * featureHeightMap.width, normPos.y * featureHeightMap.height, ofColor(mapFeatures[i]->normVal * 255));
        }
        featureMap.reloadTexture();
        featureHeightMap.reloadTexture();
        updateVisibleMap(false);
    } else {
        cout << "Error parsing JSON";
    }
}

vector<ofVec3f> oftrianglesForRect(ofRectangle rect) {
    vector<ofVec3f> vertices;
    
    vertices.push_back(ofVec3f(rect.x, rect.y));
    
    return vertices;
}

ofMesh mainApp::getMeshFromFeatures(vector<MapFeature*> mapFeatures) {
    ofMesh mesh;
	mesh.setMode(OF_PRIMITIVE_TRIANGLES);
    for (int i = 0; i < mapFeatures.size(); i++) {
        
        ofColor c = mapFeatures[i]->color;
        float w = mapFeatures[i]->width;
        float h = mapFeatures[i]->height;
        ofVec3f sw = mapFeatures[i]->getPosition() - w / 2;
        vector<ofVec3f> verts;
        
        // south face
        mesh.addVertex(sw + ofVec3f(0, 0, 0));
        mesh.addVertex(sw + ofVec3f(w, 0, 0));
        mesh.addVertex(sw + ofVec3f(w, 0, h));        
        mesh.addVertex(sw + ofVec3f(0, 0, 0));
        mesh.addVertex(sw + ofVec3f(0, 0, h));
        mesh.addVertex(sw + ofVec3f(w, 0, h));
        
        // north
        mesh.addVertex(sw + ofVec3f(0, w, 0));
        mesh.addVertex(sw + ofVec3f(w, w, 0));
        mesh.addVertex(sw + ofVec3f(w, w, h));        
        mesh.addVertex(sw + ofVec3f(0, w, 0));
        mesh.addVertex(sw + ofVec3f(0, w, h));
        mesh.addVertex(sw + ofVec3f(w, w, h));
        
        // west
        mesh.addVertex(sw + ofVec3f(0, 0, 0));
        mesh.addVertex(sw + ofVec3f(0, w, 0));
        mesh.addVertex(sw + ofVec3f(0, w, h));        
        mesh.addVertex(sw + ofVec3f(0, 0, 0));
        mesh.addVertex(sw + ofVec3f(0, 0, h));
        mesh.addVertex(sw + ofVec3f(0, w, h));
        
        // east
        mesh.addVertex(sw + ofVec3f(w, 0, 0));
        mesh.addVertex(sw + ofVec3f(w, w, 0));
        mesh.addVertex(sw + ofVec3f(w, w, h));        
        mesh.addVertex(sw + ofVec3f(w, 0, 0));
        mesh.addVertex(sw + ofVec3f(w, 0, h));
        mesh.addVertex(sw + ofVec3f(w, w, h));
        
        // roof
        mesh.addVertex(sw + ofVec3f(0, 0, h));
        mesh.addVertex(sw + ofVec3f(w, 0, h));
        mesh.addVertex(sw + ofVec3f(w, w, h));        
        mesh.addVertex(sw + ofVec3f(0, 0, h));
        mesh.addVertex(sw + ofVec3f(0, w, h));
        mesh.addVertex(sw + ofVec3f(w, w, h));
        
        for (int j = 0; j < 30; j++) {
            mesh.addColor(c);
        }
        
    }
    return mesh;
}

void mainApp::setCalibrationMode(bool state) 
{
    calibrationMode = state;
    calibrationGUI->setVisible(calibrationMode);
    layersGUI->setVisible(!calibrationMode);
}


//--------------------------------------------------------------
void mainApp::exit(){
#if (USE_QCAR)
    ofxQCAR::getInstance()->exit();
#endif
}

#if !(TARGET_OS_IPHONE)

//--------------------------------------------------------------
void mainApp::keyPressed  (int key){

    MapWidget *widget = new MapWidget();
    widget->setPosition(mapCenter);
    mapWidgets.push_back(widget);
    
    
    ofLog() << "KEY " << key;
    bool guiVisible;
    time_t rawtime;
    struct tm * timeinfo;
    time ( &rawtime );
    timeinfo = localtime ( &rawtime );
    char filename[40];
    strftime(filename, 40, "%Y-%m-%d %H-%M-%S", timeinfo );
    std::stringstream ss;
    
    switch (key) {
        case 99:
        case 67:
            setCalibrationMode(!calibrationMode);
            break;
            
        case 112:
            guiVisible = layersGUI->isVisible();
            layersGUI->setVisible(false);
            draw();
            ss.str("");
            ss << "screenshot" << filename << ".png";
            ofSaveScreen(ss.str());
            layersGUI->setVisible(guiVisible);
            break;
        /*
        case OF_KEY_UP:
            mapCenter += ofVec3f(0, PAN_POS_INC, 0);
            break;
        case OF_KEY_DOWN:
            mapCenter -= ofVec3f(0, PAN_POS_INC, 0);
            break;
        case OF_KEY_RIGHT:
            mapCenter += ofVec3f(PAN_POS_INC, 0, 0);
            break;
        case OF_KEY_LEFT:
            mapCenter -= ofVec3f(PAN_POS_INC, 0, 0);
            break;
         */

        // WSAD
        case 119:
            lights.at(0)->move(ofVec3f(0, KEYBOARD_INC, 0));
            break;
        case 115:
            lights.at(0)->move(-ofVec3f(0, KEYBOARD_INC, 0));
            break;
        case 97:
            lights.at(0)->move(-ofVec3f(KEYBOARD_INC, 0, 0));
            break;
        case 100:
            lights.at(0)->move(ofVec3f(KEYBOARD_INC, 0, 0));
            break;

            // IK
        case 105:
            lights.at(0)->move(ofVec3f(0, 0, KEYBOARD_INC));
            break;
        case 107:
            lights.at(0)->move(-ofVec3f(0, 0, KEYBOARD_INC));
            break;
            
            
        // WSAD
/*        case 119:
            waterSW += ofVec3f(0, WATER_POS_INC, 0);
            break;
        case 115:
            waterSW -= ofVec3f(0, WATER_POS_INC, 0);
            break;
        case 97:
            waterSW -= ofVec3f(WATER_POS_INC, 0, 0);
            break;
        case 100:
            waterSW += ofVec3f(WATER_POS_INC, 0, 0);
            break;
            
        // IKJL
        case 105:
            waterNE += ofVec3f(0, WATER_POS_INC, 0);
            break;
        case 107:
            waterNE -= ofVec3f(0, WATER_POS_INC, 0);
            break;
        case 106:
            waterNE -= ofVec3f(WATER_POS_INC, 0, 0);
            break;
        case 108:
            waterNE += ofVec3f(WATER_POS_INC, 0, 0);
            break;*/
            
        case 118:
            if (animateLight < 0) {
                animateLight = 1;
                animateLightStart = ofGetElapsedTimef();
                animateLightStartPos = lights.at(animateLight)->getPosition();
            } else {
                animateLight = -1;
            }
            break;
        case 98:
            if (animatePlate < 0) {
                animatePlate = 2;
                animatePlateStart = ofGetElapsedTimef();
                animatePlateStartPos = terrainLayers.at(animatePlate)->getPosition();
            } else {
                animatePlate = -1;
            }
            break;
        case 110:
            drawAnimationEnabled = true;
            break;
            
        #if (USE_ARTK)
        // t
        case 116:
            artkEnabled = !artkEnabled;
            break;
        #endif

    }
}

//--------------------------------------------------------------
void mainApp::keyReleased(int key){
    
}

//--------------------------------------------------------------
void mainApp::mouseMoved(int x, int y ){
    cursorNotMovedSince = 0;
}

//--------------------------------------------------------------
void mainApp::mouseDragged(int x, int y, int button){
    rip.damping = ofMap(y, 0, ofGetHeight(), 0.9, 1.0, true);
}

//--------------------------------------------------------------
void mainApp::mousePressed(int x, int y, int button){
    cursorNotMovedSince = 0;
}

//--------------------------------------------------------------
void mainApp::mouseReleased(int x, int y, int button){
}

//--------------------------------------------------------------
void mainApp::windowResized(int w, int h){
    
}

//--------------------------------------------------------------
void mainApp::gotMessage(ofMessage msg){
    
}

//--------------------------------------------------------------
void mainApp::dragEvent(ofDragInfo dragInfo){ 
    
}

//--------------------------------------------------------------
void mainApp::moved() {
    cout << "got to moved" << endl;
}

#else

void mainApp::handlePinch(ofPinchEventArgs &e) {
    /*
     float scale = e.scale * .01;
     if (e.scale > 1) {
     terrainUnitToGlUnit += (terrainUnitToGlUnit * scale);
     } else {
     terrainUnitToGlUnit -= (terrainUnitToGlUnit * scale);
     }
     */
}

//--------------------------------------------------------------
void mainApp::touchDown(ofTouchEventArgs & touch) {
    cursorNotMovedSince = 0;
    isPanning = (touch.x > ofGetWidth() * .3 || touch.y > ofGetHeight() * .5);
    touchPoint = ofVec2f(touch.x, touch.y);
}

//--------------------------------------------------------------
void mainApp::touchMoved(ofTouchEventArgs & touch)
{
    /*cursorNotMovedSince = 0;
    ofVec2f lastTouchPoint = ofVec2f(touch.x, touch.y);
    ofVec2f delta = lastTouchPoint - touchPoint;
    
    switch (deviceOrientation) {
        case OFXIPHONE_ORIENTATION_PORTRAIT:
            delta.x *= -1;
            break;
        case OFXIPHONE_ORIENTATION_UPSIDEDOWN:
            delta.y *= -1;
            break;
        case OFXIPHONE_ORIENTATION_LANDSCAPE_RIGHT:
            delta = ofVec2f(delta.y, delta.x);
            break;
        case OFXIPHONE_ORIENTATION_LANDSCAPE_LEFT:
            delta = ofVec2f(-delta.y, -delta.x);
            break;
    }
    touchPoint = lastTouchPoint;
    
    if (isPanning) {
        mapCenter += delta * terrainUnitToGlUnit;      
        updateVisibleMap(true);
    }*/
}

//--------------------------------------------------------------
void mainApp::touchUp(ofTouchEventArgs & touch){
    //isPanning = false;
}

//--------------------------------------------------------------
void mainApp::touchDoubleTap(ofTouchEventArgs & touch) {
    updateVisibleMap(false);
    setCalibrationMode(!calibrationMode);
}

//--------------------------------------------------------------
void mainApp::touchCancelled(ofTouchEventArgs & touch){
    
}

//--------------------------------------------------------------
void mainApp::lostFocus(){
    
}

//--------------------------------------------------------------
void mainApp::gotFocus(){
    
}

//--------------------------------------------------------------
void mainApp::gotMemoryWarning(){
    
}

//--------------------------------------------------------------
void mainApp::deviceOrientationChanged(int newOrientation){
    deviceOrientation = newOrientation;
    
}

#endif
