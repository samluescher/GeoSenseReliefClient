#include "mainApp.h"
#include "ofEvents.h"
#include "util.h"
#include "ofxOpenCv.h"

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


vector<ofEasyCam> cameras;

class AppViewport: public ofxFensterListener {

    public:
        ofRectangle rect, selectRect;
        bool drawTerrainEnabled, drawOverlaysEnabled, drawTexturesEnabled, drawTerrainGridEnabled, drawWireframesEnabled, drawMapFeaturesEnabled, drawMiniMapEnabled, drawWaterEnabled, tetherWaterEnabled, drawVideoEnabled, lightingEnabled, fullscreenEnabled;
        float lightAttenuation;
        int viewportIndex;
        ofVec2f globalScale;
        ofVec2f globalOffset;
        map<string, bool> featureLayerVisible;
        map<string, bool> terrainLayerVisible;
        map<string, bool> terrainOverlayVisible;
        mainApp * app;
    
    void draw() {
        app->drawWorld(viewportIndex, (USE_ARTK || USE_QCAR));
    }
    
    ofEasyCam& getCamera() {
        return cameras.at(viewportIndex);
    }
};

vector<AppViewport> viewports;

AppViewport& addViewport(mainApp * app, ofRectangle rect) {
    AppViewport viewport;
    int index = viewports.size();
    viewports.push_back(viewport);
    AppViewport& v = viewports.at(index);
    
    v.drawWireframesEnabled = false;
    v.rect = rect;
    v.drawTerrainEnabled = true;
    v.drawOverlaysEnabled = true;
    v.drawTexturesEnabled = true;
    v.drawVideoEnabled = false;
    v.drawTerrainGridEnabled = false;
    v.drawMapFeaturesEnabled = true;
    v.drawMiniMapEnabled = false;
    v.lightingEnabled = true;
    v.lightAttenuation = LIGHT_ATTENUATION;
    v.app = app;
    v.viewportIndex = index;
    v.fullscreenEnabled = ENABLE_FULLSCREEN;
    v.globalScale = ofVec2f(1, 1);
    v.selectRect = ofRectangle(v.rect.x + v.rect.width - 1 - VIEWPORT_SELECTOR_W, v.rect.y, VIEWPORT_SELECTOR_W, VIEWPORT_SELECTOR_W);

    ofEasyCam cam;
    cameras.push_back(cam);
    
    for (int i = 0; i < app->terrainLayers.size(); i++) {
        TerrainLayer* layer = app->terrainLayers.at(i);
        v.terrainLayerVisible[layer->title] = layer->visible;
    }
    
    for (int i = 0; i < app->featureLayers.size(); i++) {
        MapFeatureLayer* layer = app->featureLayers.at(i);
        v.featureLayerVisible[layer->title] = layer->visible;
    }

    for (int i = 0; i < app->terrainOverlays.size(); i++) {
        TerrainLayerCollection* overlay = app->terrainOverlays.at(i);
        v.terrainOverlayVisible[overlay->title] = overlay->visible;
    }

    return v;

}

void logCam(ofCamera& cam) {
    ofLog() << "CAMERA " << cam.getPosition() << " ==> " << cam.getLookAtDir();
    
}


//--------------------------------------------------------------
void mainApp::setup()
{
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
 

    calibrationMode = false;
    drawDebugEnabled = true;
    
    

    reliefSendMode = RELIEF_SEND_OFF;

    animateLight = -1;
    animatePlate = -1;
    timeline.width = ofGetWidth() / 2;
    timeline.setPosition(ofVec2f(ofGetWidth() / 2, 50));
    
    
    
    
    terrainSW = ofVec2f(128, 28);
    terrainNE = ofVec2f(150, 46);
    terrainSE = ofVec2f(terrainNE.x, terrainSW.y);
    terrainNW = ofVec2f(terrainNW.x, terrainNW.y);
    waterSW = ofVec2f(20, 10);
    waterNE = ofVec2f(40, 40);
    terrainExtents = ofVec2f(terrainNE.x - terrainSW.x, terrainNE.y - terrainSW.y);
    ofLog() << "terrainExtents: " << terrainExtents.x << "," << terrainExtents.y;
    ofVec2f center = terrainSW + terrainExtents / 2;
    terrainCenterOffset = ofVec3f(center.x, center.y, 0); 
    mapCenter = fukushima - ofVec3f(2.75, 0, 0); // initially center on off-shore Fukushima
    
    terrainUnitToGlUnit = 1 / GL_UNIT_TO_TERRAIN_UNIT_INITIAL;
    realworldUnitToGlUnit = 3.5f;
    
    loadSettings();
    setupLayers();
    setupViewports();
    loadSettings();
    
    
    ofSetSmoothLighting(true);
    
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
    
    // ripple (from ofxFX)
    ofImage waterImage;
    waterImage.loadImage("maps/water.png");
    TerrainLayer* waterLayer = terrainLayers.at(0);
    int ripW = waterLayer->textureImage.getWidth() * .1,
        ripH = waterLayer->textureImage.getHeight() * .1;
    rip.allocate(ripW, ripH);
    rip.damping = .95;
    bounce.allocate(ripW, ripH);
    bounce.setTexture(waterImage.getTextureReference(), 1);
    
    #if !(TARGET_OS_IPHONE)
    ofEnableSmoothing();
    #endif
    
    
    #if (TARGET_OS_IPHONE)
    EAGLView *view = ofxiPhoneGetGLView();  
    pinchRecognizer = [[ofPinchGestureRecognizer alloc] initWithView:view];
    ofAddListener(pinchRecognizer->ofPinchEvent,this, &mainApp::handlePinch);
    #endif

    mouseController.registerEvents(this);
    oscReceiverController.registerEvents(this);
    //oscReceiverController.verticalPan = true;
    leapController.registerEvents(this);

    #if !(TARGET_OS_IPHONE)
    keyboardController.registerEvents(this);
    #endif

    setupGUI();
}

void mainApp::setupLayers() {
    ofEnableNormalizedTexCoords();
    
    float s = terrainExtents.x / 880; //heightMap.width;
    terrainToHeightMapScale = ofVec3f(s, s, 1);
    terrainToHeightMapScale.z = (terrainToHeightMapScale.x + terrainToHeightMapScale.y) / 2;
    ofLog() << "terrainToHeightMapScale: " << terrainToHeightMapScale;
    
    terrainPeakHeight = terrainToHeightMapScale.z * 350.0f;
    featureHeight = .5f;
    
    
    ofLog() << " *** Creating terrain layers";
    float seaFloorPeakHeight = terrainPeakHeight * 13;
    TerrainLayer *layer;
    
    //layer = addTerrainLayer("CRUST", "maps/heightmap.ASTGTM2_128,28,149,45-1600-with-water.png", "maps/srtm.ASTGTM2_128,28,149,45-14400-with-water.png", terrainPeakHeight);
    layer = addTerrainLayerFromHeightMap("Crust", "maps/heightmap.ASTGTM2_128,28,149,45-1600.png", "maps/srtm.ASTGTM2_128,28,149,45-14400.png", terrainPeakHeight);
    layer->setScale(1);
    
    layer = addTerrainLayerFromHeightMap("Ocean", "maps/heightmap.mantle.png", "maps/water.png", terrainPeakHeight);
    layer->setScale(ofVec3f(focusLayer->heightMap.getWidth() / layer->heightMap.getWidth(), focusLayer->heightMap.getHeight() / layer->heightMap.getHeight(), 1));
    layer->move(ofVec3f(0, 0, -terrainPeakHeight * .2));
    
    
    layer = addTerrainLayerFromHeightMap("Plates", "maps/heightmap.ETOPO1_128,28,149,45-downsampled-blur.png", "maps/greenblue.ETOPO1_128,28,149,45.png", seaFloorPeakHeight);
    layer->move(ofVec3f(0, 0, -(seaFloorPeakHeight + terrainPeakHeight * .4)));
    layer->setScale(ofVec3f(focusLayer->heightMap.getWidth() / layer->heightMap.getWidth(), focusLayer->heightMap.getHeight() / layer->heightMap.getHeight(), 1));
    
    /*
     layer = addTerrainLayerFromHeightMap("J PLATE", "maps/bathymetry_128,28,149,45-1600-j-plate.png", "maps/ocean.blue_128,28,149,45-1600.png", seaFloorPeakHeight);
     layer->move(ofVec3f(0, 0, -(seaFloorPeakHeight + terrainPeakHeight * .2)));
     layer->setScale(ofVec3f(focusLayer->heightMap.getWidth() / layer->heightMap.getWidth(), focusLayer->heightMap.getHeight() / layer->heightMap.getHeight(), 1));
     
     layer = addTerrainLayerFromHeightMap("P PLATE", "maps/bathymetry_128,28,149,45-1600-p-plate.png", "maps/ocean.blue_128,28,149,45-1600.png", seaFloorPeakHeight);
     layer->move(ofVec3f(0, 0, -(seaFloorPeakHeight + terrainPeakHeight * .2)));
     layer->setScale(ofVec3f(focusLayer->heightMap.getWidth() / layer->heightMap.getWidth(), focusLayer->heightMap.getHeight() / layer->heightMap.getHeight(), 1));*/
    
    layer = addTerrainLayerFromHeightMap("Mantle", "maps/heightmap.mantle.png", "maps/mantle.png", terrainPeakHeight);
    layer->move(ofVec3f(0, 0, -(terrainPeakHeight + seaFloorPeakHeight + terrainPeakHeight * .2)));
    layer->setScale(ofVec3f(focusLayer->heightMap.getWidth() / layer->heightMap.getWidth(), focusLayer->heightMap.getHeight() / layer->heightMap.getHeight(), 1));
    layer->lighting = false;

    loadFeaturesFromGeoJSONFile("json/japan-prefectures.json", "Prefectures");
    loadFeaturesFromGeoJSONFile("json/plateboundaries-japan.json", "Plate boundaries")->pointRadius = 0;
    loadFeaturesFromGeoJSONFile("json/convergence.json", "Convergence");
    loadFeaturesFromGeoJSONFile("json/japan-flood.json", "Inundation zone")->pointRadius = .2;
    loadFeaturesFromGeoJSONFile("json/tohoku-earthquake.json", "Tohoku earthquake");
    MapFeatureCollection* cuts = loadFeaturesFromGeoJSONFile("json/vertical-cut-lines.json", "Vertical Cuts");
    
    
    stringstream ss;
    ss << "" << "&b=" << terrainSW.x - 2 << "&b=" << terrainSW.y - 1 << "&b=" << terrainNE.x + 1 << "&b=" << terrainNE.y + 1;
    string strBounds = ss.str();
    
    ss.str("");
    ss << "http://localhost:3000/api/map/stratarium/layer/51706f7e1b84fc58e900001f/features?z=7" << strBounds;
    MapFeatureLayer* earthquakes = addMapFeaturelayer("Earthquakes");
    
    for (int year = EARTHQUAKE_START_YEAR; year <= EARTHQUAKE_END_YEAR; year++) {
        ss.str("");
        ss << "" "http://localhost:3000/api/map/stratarium/layer/51706f7e1b84fc58e900001f/features?z=7&t=yearly&d=" << year << strBounds;
        stringstream ssName;
        ssName << "Earthquakes " << year;
        MapFeatureCollection *coll = loadFeaturesFromGeoJSONURL(ss.str(), ssName.str(), earthquakes);
        coll->timelinePos = (year - EARTHQUAKE_START_YEAR) / float(EARTHQUAKE_END_YEAR - EARTHQUAKE_START_YEAR);
        ofLog() << coll->title << " " << coll->timelinePos;
    }
    
    
    for (int i = 0; i < featureLayers.size(); i++) {
        MapFeatureLayer *layer = featureLayers.at(i);
        layer->visible = i == 0;
    }

    
    TerrainLayerCollection* cutOverlays = addTerrainOverlay("Section cuts");
    for (int i = 0; i < cuts->features.size(); i++) {
        ofMesh mesh = cuts->features.at(i).mesh;
        stringstream ss;
        ss.str("");
        ss << "cuts/" << (i + 1) << ".png";
        TerrainLayer* layer = createTerrainOverlayItem(ss.str(), mesh.getVertex(1), mesh.getVertex(0), 7, ss.str());
        //layer->opacity *= 1 / float(cuts->features.size() * (cuts->features.size() - i));
        cutOverlays->addLayer(layer);
    }
    
}


void mainApp::setupViewports() {
    ofLog() << "addViewport ******************" << terrainLayers.size();

    AppViewport& v1 = addViewport(this, ofRectangle(0, 0, WINDOW_W, WINDOW_H));
    v1.lightAttenuation = 3;
    ofCamera& cam1 = v1.getCamera();
    cam1.setPosition(mapCenter + ofVec3f(0, 0, 1000));
    cam1.lookAt(mapCenter);
    
    AppViewport& v2 = addViewport(this, ofRectangle(WINDOW_W, 0, WINDOW_W, WINDOW_H));
    v2.drawOverlaysEnabled = false;
    v2.lightAttenuation = 3;
    ofCamera& cam2 = v2.getCamera();
    cam2.setPosition(mapCenter + ofVec3f(0, 0, 1000));
    cam2.lookAt(mapCenter);
    
    if (MULTI_WINDOWS) {
        for (int i = 0; i < viewports.size(); i++) {
            AppViewport& v = viewports.at(i);
        }
        // open additional displays on second display
        ofxDisplayList displays = ofxDisplayManager::get()->getDisplays();
        ofxDisplay* disp = displays[0];
        if (displays.size() > 1) {
            disp = displays[1];
        }
        ofxFensterManager::get()->setActiveDisplay(disp);
        
        for (int i = 1; i < viewports.size(); i++) {
            ofxFenster* win = ofxFensterManager::get()->createFenster(
                                                                      (i - (displays.size() > 1 ? 1 : 0)) * WINDOW_W, 0,
                                                                      WINDOW_W, WINDOW_H, viewports.at(i).fullscreenEnabled ? OF_FULLSCREEN : OF_WINDOW);
            win->addListener(&viewports.at(i));
        }
        
    } else {
        ofSetFullscreen(true);
    }
    
    for (int i = 1; i < viewports.size(); i++) {
        logCam(viewports.at(i).getCamera());
    }
}

void mainApp::loadSettings()
{
    ofxXmlSettings settings;
	if (settings.loadFile("settings.xml")) {
        settings.addTag("settings");
        settings.pushTag("settings");
        
        realworldUnitToGlUnit = settings.getValue("realworldUnitToGlUnit", realworldUnitToGlUnit);
        
        settings.pushTag("viewports");
        int numViewports = settings.getNumTags("viewport");
        for (int i = 0; i < viewports.size(); i++){
            AppViewport& v = viewports.at(i); // tmp
            settings.pushTag("viewport", i);
            
            v.drawTerrainEnabled = settings.getValue("drawTerrainEnabled", v.drawTerrainEnabled);
            v.globalScale.x = settings.getValue("globalScale:x", v.globalScale.x);
            v.globalScale.y = settings.getValue("globalScale:y", v.globalScale.y);
            v.globalOffset.x = settings.getValue("globalOffset:x", v.globalOffset.x);
            v.globalOffset.y = settings.getValue("globalOffset:y", v.globalOffset.y);
            v.drawTerrainEnabled = settings.getValue("drawTerrainEnabled", v.drawTerrainEnabled);
            v.drawMapFeaturesEnabled = settings.getValue("drawMapFeaturesEnabled", v.drawMapFeaturesEnabled);
            v.drawOverlaysEnabled = settings.getValue("drawOverlaysEnabled", v.drawOverlaysEnabled);
            v.drawMiniMapEnabled = settings.getValue("drawMiniMapEnabled", v.drawMiniMapEnabled);
            v.drawTerrainGridEnabled = settings.getValue("drawTerrainGridEnabled", v.drawTerrainGridEnabled);
            v.lightingEnabled = settings.getValue("lightingEnabled", v.lightingEnabled);
            v.drawTexturesEnabled = settings.getValue("drawTexturesEnabled", v.drawTexturesEnabled);
            v.fullscreenEnabled = settings.getValue("fullscreenEnabled", v.fullscreenEnabled);
            v.lightAttenuation = settings.getValue("lightAttenuation", v.lightAttenuation);

            if (settings.getValue("camera:ortho", v.getCamera().getOrtho())) {
                v.getCamera().enableOrtho();
            } else {
                v.getCamera().disableOrtho();
            }
            ofVec3f position = v.getCamera().getPosition();
            position.x = settings.getValue("camera:position:x", position.x);
            position.y = settings.getValue("camera:position:y", position.y);
            position.y = settings.getValue("camera:position:z", position.z);
            ofVec3f lookAtDir = v.getCamera().getLookAtDir();
            lookAtDir.x = settings.getValue("camera:lookAtDir:x", lookAtDir.x);
            lookAtDir.y = settings.getValue("camera:lookAtDir:y", lookAtDir.y);
            lookAtDir.y = settings.getValue("camera:lookAtDir:z", lookAtDir.z);
            
            settings.pushTag("terrainLayerVisible");
            for (int i = 0; i < terrainLayers.size(); i++) {
                TerrainLayer *layer = terrainLayers.at(i);
                string name = settings.getAttribute("layer", "name", layer->title, i);
                v.terrainLayerVisible[name] = settings.getAttribute("layer", "visible", v.terrainLayerVisible[name], i);
            }
            settings.popTag();
            
            settings.pushTag("featureLayerVisible");
            for (int i = 0; i < featureLayers.size(); i++) {
                MapFeatureLayer *layer = featureLayers.at(i);
                string name = settings.getAttribute("layer", "name", layer->title, i);
                v.featureLayerVisible[name] = settings.getAttribute("layer", "visible", v.featureLayerVisible[name], i);
            }
            settings.popTag();
            
            settings.pushTag("terrainOverlayVisible");
            for (int i = 0; i < terrainOverlays.size(); i++) {
                TerrainLayerCollection *layer = terrainOverlays.at(i);
                string name = settings.getAttribute("layer", "name", layer->title, i);
                v.terrainOverlayVisible[name] = settings.getAttribute("layer", "visible", v.terrainOverlayVisible[name], i);
            }
            settings.popTag();
            
            settings.popTag();
        }
        settings.popTag();
        settings.popTag(); 
    }
}

void mainApp::saveSettings()
{
    ofxXmlSettings settings;
    settings.addTag("settings");
    settings.pushTag("settings");

    settings.setValue("realworldUnitToGlUnit", realworldUnitToGlUnit);
    
    settings.addTag("viewports");
    settings.pushTag("viewports");
    for (int i = 0; i < viewports.size(); i++){
        AppViewport& v = viewports.at(i);
        settings.addTag("viewport");
        settings.pushTag("viewport", i);
        
        settings.setValue("drawTerrainEnabled", v.drawTerrainEnabled);
        settings.setValue("globalScale:x", v.globalScale.x);
        settings.setValue("globalScale:y", v.globalScale.y);
        settings.setValue("globalOffset:x", v.globalOffset.x);
        settings.setValue("globalOffset:y", v.globalOffset.y);
        settings.setValue("drawTerrainEnabled", v.drawTerrainEnabled);
        settings.setValue("drawMapFeaturesEnabled", v.drawMapFeaturesEnabled);
        settings.setValue("drawOverlaysEnabled", v.drawOverlaysEnabled);
        settings.setValue("drawMiniMapEnabled", v.drawMiniMapEnabled);
        settings.setValue("drawTerrainGridEnabled", v.drawTerrainGridEnabled);
        settings.setValue("lightingEnabled", v.lightingEnabled);
        settings.setValue("drawTexturesEnabled", v.drawTexturesEnabled);
        settings.setValue("fullscreenEnabled", v.fullscreenEnabled);
        settings.setValue("lightAttenuation", v.lightAttenuation);
        settings.setValue("camera:ortho", v.getCamera().getOrtho());
        settings.setValue("camera:position:x", v.getCamera().getPosition().x);
        settings.setValue("camera:position:y", v.getCamera().getPosition().y);
        settings.setValue("camera:position:z", v.getCamera().getPosition().z);
        settings.setValue("camera:lookAtDir:x", v.getCamera().getLookAtDir().x);
        settings.setValue("camera:lookAtDir:y", v.getCamera().getLookAtDir().y);
        settings.setValue("camera:lookAtDir:z", v.getCamera().getLookAtDir().z);

        settings.addTag("terrainLayerVisible");
        settings.pushTag("terrainLayerVisible");
        for (int i = 0; i < terrainLayers.size(); i++) {
            TerrainLayer *layer = terrainLayers.at(i);
            settings.addTag("layer");
            settings.setAttribute("layer", "name", layer->title, i);
            settings.setAttribute("layer", "visible", v.terrainLayerVisible[layer->title], i);
        }
        settings.popTag();

        settings.addTag("featureLayerVisible");
        settings.pushTag("featureLayerVisible");
        for (int i = 0; i < featureLayers.size(); i++) {
            MapFeatureLayer *layer = featureLayers.at(i);
            settings.addTag("layer");
            settings.setAttribute("layer", "name", layer->title, i);
            settings.setAttribute("layer", "visible", v.featureLayerVisible[layer->title], i);
        }
        settings.popTag();

        settings.addTag("terrainOverlayVisible");
        settings.pushTag("terrainOverlayVisible");
        for (int i = 0; i < terrainOverlays.size(); i++) {
            TerrainLayerCollection *layer = terrainOverlays.at(i);
            settings.addTag("layer");
            settings.setAttribute("layer", "name", layer->title, i);
            settings.setAttribute("layer", "visible", v.terrainOverlayVisible[layer->title], i);
        }
        settings.popTag();
       
        settings.popTag();
    }
    settings.popTag();
    settings.popTag(); 
    settings.saveFile("settings.xml");
}

void mainApp::updateGUI() {
    AppViewport& v = viewports.at(selectedViewport);

    ((ofxUISlider *)calibrationGUI->getWidget("REAL WORLD SCALE"))->setValue(realworldUnitToGlUnit);
    ((ofxUISlider *)calibrationGUI->getWidget("GLOBAL SCALE"))->setValue(v.globalScale.x);
    ((ofxUISlider *)calibrationGUI->getWidget("GLOBAL SCALE X"))->setValue(v.globalScale.x);
    ((ofxUISlider *)calibrationGUI->getWidget("GLOBAL SCALE Y"))->setValue(v.globalScale.y);
    ((ofxUISlider *)calibrationGUI->getWidget("GLOBAL OFFSET X"))->setValue(v.globalOffset.x);
    ((ofxUISlider *)calibrationGUI->getWidget("GLOBAL OFFSET Y"))->setValue(v.globalOffset.y);
    //((ofxUISlider *)calibrationGUI->getWidget("GLOBAL OFFSET Z"))->setValue(v.globalOffset.z);

    ((ofxUIToggle *)layersGUI->getWidget("TERRAIN"))->setValue(v.drawTerrainEnabled);
    ((ofxUIToggle *)layersGUI->getWidget("FEATURES"))->setValue(v.drawMapFeaturesEnabled);
    ((ofxUIToggle *)layersGUI->getWidget("OVERLAYS"))->setValue(v.drawOverlaysEnabled);
    ((ofxUIToggle *)layersGUI->getWidget("MINIMAP"))->setValue(v.drawMiniMapEnabled);
    ((ofxUIToggle *)layersGUI->getWidget("GRID"))->setValue(v.drawTerrainGridEnabled);
    ((ofxUIToggle *)layersGUI->getWidget("LIGHTING"))->setValue(v.lightingEnabled);
    ((ofxUIToggle *)layersGUI->getWidget("TEXTURES"))->setValue(v.drawTexturesEnabled);
    ((ofxUIToggle *)layersGUI->getWidget("ORTHOGONAL"))->setValue(v.getCamera().getOrtho());
    ((ofxUIToggle *)layersGUI->getWidget("FULLSCREEN"))->setValue(v.fullscreenEnabled);

    ((ofxUISlider *)layersGUI->getWidget("ATTENUATION"))->setValue(v.lightAttenuation);

    for (int i = 0; i < terrainLayers.size(); i++) {
        TerrainLayer *layer = terrainLayers.at(i);
        ((ofxUIToggle *)layersGUI->getWidget(layer->title))->setValue(v.terrainLayerVisible[layer->title]);
    }
    
    for (int i = 0; i < featureLayers.size(); i++) {
        MapFeatureLayer *layer = featureLayers.at(i);
        ((ofxUIToggle *)layersGUI->getWidget(layer->title))->setValue(v.featureLayerVisible[layer->title]);
    }

    for (int i = 0; i < terrainOverlays.size(); i++) {
        TerrainLayerCollection *overlay = terrainOverlays.at(i);
        ((ofxUIToggle *)layersGUI->getWidget(overlay->title))->setValue(v.terrainOverlayVisible[overlay->title]);
    }
}


void mainApp::setupGUI() {
    AppViewport& v1 = viewports.at(selectedViewport);
    cursorNotMovedSince = 0;
    
    float guiW = 350;
    float spacing = OFX_UI_GLOBAL_WIDGET_SPACING;
    #if (TARGET_OS_IPHONE)
    float dim = 100; // Retina resolution
	layersGUI->setWidgetFontSize(OFX_UI_FONT_LARGE);
    #else
    float dim = 16;
    #endif
    
    layersGUI = new ofxUICanvas(spacing, spacing, guiW, ofGetHeight());

    layersGUI->addToggle("TERRAIN", v1.drawTerrainEnabled, dim, dim);
    for (int i = 0; i < terrainLayers.size(); i++) {
        TerrainLayer *layer = terrainLayers.at(i);
        layersGUI->addToggle(layer->title, layer->visible, dim, dim);
    }
	
	layersGUI->addWidgetDown(new ofxUILabel("", OFX_UI_FONT_LARGE));
	layersGUI->addWidgetDown(new ofxUILabel("", OFX_UI_FONT_LARGE));
	layersGUI->addToggle("FEATURES", v1.drawMapFeaturesEnabled, dim, dim);
    for (int i = 0; i < featureLayers.size(); i++) {
        MapFeatureLayer *layer = featureLayers.at(i);
        layersGUI->addToggle(layer->title, layer->visible, dim, dim);
    }

	layersGUI->addWidgetDown(new ofxUILabel("", OFX_UI_FONT_LARGE));
	layersGUI->addWidgetDown(new ofxUILabel("", OFX_UI_FONT_LARGE));
	layersGUI->addToggle("OVERLAYS", v1.drawOverlaysEnabled, dim, dim);
    for (int i = 0; i < terrainOverlays.size(); i++) {
        TerrainLayerCollection* overlay = terrainOverlays.at(i);
        layersGUI->addToggle(overlay->title, overlay->visible, dim, dim);
    }

	layersGUI->addWidgetDown(new ofxUILabel("", OFX_UI_FONT_LARGE));
	layersGUI->addWidgetDown(new ofxUILabel("", OFX_UI_FONT_LARGE));
	layersGUI->addToggle("MINIMAP", v1.drawMiniMapEnabled, dim, dim);
	layersGUI->addToggle("GRID", v1.drawTerrainGridEnabled, dim, dim);
    
	layersGUI->addWidgetDown(new ofxUILabel("", OFX_UI_FONT_LARGE));
	layersGUI->addWidgetDown(new ofxUILabel("", OFX_UI_FONT_LARGE));
    layersGUI->addToggle("LIGHTING", v1.lightingEnabled, dim, dim);
    layersGUI->addSlider("ATTENUATION", 0, 4, v1.lightAttenuation, guiW - spacing * 2, dim);
	layersGUI->addWidgetDown(new ofxUILabel("", OFX_UI_FONT_LARGE));
    layersGUI->addSlider("ZOOM", MIN_ZOOM, MAX_ZOOM, 1 / terrainUnitToGlUnit, guiW - spacing * 2, dim);
	layersGUI->addWidgetDown(new ofxUILabel("", OFX_UI_FONT_LARGE));
	layersGUI->addWidgetDown(new ofxUILabel("", OFX_UI_FONT_LARGE));
	layersGUI->addToggle("TEXTURES", v1.drawTexturesEnabled, dim, dim);

	layersGUI->addWidgetDown(new ofxUILabel("", OFX_UI_FONT_LARGE));
	layersGUI->addWidgetDown(new ofxUILabel("", OFX_UI_FONT_LARGE));
    #if !(TARGET_OS_IPHONE)
	layersGUI->addToggle("FULLSCREEN", v1.fullscreenEnabled, dim, dim);
	/*layersGUI->addToggle("DUALSCREEN", dualscreenEnabled, dim, dim);*/
	layersGUI->addToggle("ORTHOGONAL", v1.getCamera().getOrtho(), dim, dim);
    //    layersGUI->addButton("RESET CAMERA", false, dim, dim);
    #endif
	layersGUI->addToggle("WIREFRAMES", v1.drawWireframesEnabled, dim, dim);
    
    layersGUI->setDrawBack(true);
    layersGUI->setColorBack(ofColor(60, 60, 60, 100));
	ofAddListener(layersGUI->newGUIEvent,this,&mainApp::guiEvent);

    
    guiW = 500;
    calibrationGUI = new ofxUICanvas(0, 0, guiW, ofGetHeight());
    
    #if (USE_QCAR || USE_ARTK)
	calibrationGUI->addToggle("DEBUG", drawDebugEnabled, dim, dim);
	calibrationGUI->addToggle("VIDEO", drawVideoEnabled, dim, dim);
    #endif
    
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
    calibrationGUI->addWidgetDown(new ofxUILabel("RELIEF SERVER", OFX_UI_FONT_LARGE));
	calibrationGUI->addToggle("SEND TERRAIN", reliefSendMode == RELIEF_SEND_TERRAIN, dim, dim);
	calibrationGUI->addToggle("SEND FEATURES", reliefSendMode == RELIEF_SEND_FEATURES, dim, dim);
    
    #if (USE_ARTK)
	calibrationGUI->addWidgetDown(new ofxUILabel("", OFX_UI_FONT_LARGE));
	calibrationGUI->addWidgetDown(new ofxUILabel("", OFX_UI_FONT_LARGE));
    calibrationGUI->addSlider("VIDEO THRESH", 0, 255, artkController.videoThreshold, guiW - spacing * 2, dim);
    #if (USE_LIBDC)
    calibrationGUI->addSlider("VIDEO EXPOSURE", 0, 1, artkController.camera.getExposure(), guiW - spacing * 2, dim);
    calibrationGUI->addSlider("VIDEO GAIN", 0, 2, artkController.camera.getGain(), guiW - spacing * 2, dim);
    #endif
    #endif

	calibrationGUI->addWidgetDown(new ofxUILabel("", OFX_UI_FONT_LARGE));
	calibrationGUI->addWidgetDown(new ofxUILabel("", OFX_UI_FONT_LARGE));
    calibrationGUI->addSlider("REAL WORLD SCALE", realworldUnitToGlUnit * .33f, realworldUnitToGlUnit * 3, realworldUnitToGlUnit, guiW - spacing * 2, dim);
    
	calibrationGUI->addWidgetDown(new ofxUILabel("", OFX_UI_FONT_LARGE));
	calibrationGUI->addWidgetDown(new ofxUILabel("", OFX_UI_FONT_LARGE));
    calibrationGUI->addSlider("GLOBAL SCALE", .1, 4, v1.globalScale.x, guiW - spacing * 2, dim);
    calibrationGUI->addSlider("GLOBAL SCALE X", .1, 4, v1.globalScale.x, guiW - spacing * 2, dim);
    calibrationGUI->addSlider("GLOBAL SCALE Y", .1, 4, v1.globalScale.y, guiW - spacing * 2, dim);
    calibrationGUI->addSlider("GLOBAL OFFSET X", -400, 400, v1.globalOffset.x, guiW - spacing * 2, dim);
    calibrationGUI->addSlider("GLOBAL OFFSET Y", -400, 400, v1.globalOffset.y, guiW - spacing * 2, dim);
    //calibrationGUI->addSlider("GLOBAL OFFSET Z", -400, 400, v1.globalOffset.z, guiW - spacing * 2, dim);

	ofAddListener(calibrationGUI->newGUIEvent, this, &mainApp::guiEvent);
    updateGUI();
}

void mainApp::onSwipe(GestureEventArgs & args) {
    return;
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
    int dir = args.normal.z > 0 ? -1 : 1;
    timeline.setCursorPos(timeline.getCursorPos() + TIMELINE_CIRCLE_STEP * args.progress * dir);
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
    //mapCenter += distance;
    
    ofCamera& cam = viewports.at(selectedViewport).getCamera();
    cam.move(distance);
    cam.lookAt(mapCenter);
    
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

void mainApp::onLook(const void* sender, ofVec3f & distance) {
    mapCenter += distance * .5;
    ofCamera& cam = viewports.at(selectedViewport).getCamera();
    cam.lookAt(mapCenter);
    
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
    viewports.at(selectedViewport).getCamera().setPosition(viewpoint.getPosition());
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


void mainApp::resetCam(ofCamera& cam)
{
    //cam.reset();
    cam.setPosition(ofVec3f(ofVec3f(terrainSW.x + terrainExtents.x / 2, terrainSW.y, 10)));
    cam.lookAt(mapCenter);
    
    
    //cam.update();
    //cam.disableMouseInput();
     
    update();
    updateVisibleMap(true);
}

void mainApp::setFeatureLayerVisible(int index, bool visible) {
    AppViewport& v = viewports.at(selectedViewport);
    MapFeatureLayer *layer = featureLayers.at(index);
    v.featureLayerVisible[layer->title] = visible;
    updateGUI();
}

void mainApp::setTerrainLayerVisible(int index, bool visible) {
    AppViewport& v = viewports.at(selectedViewport);
    TerrainLayer *layer = terrainLayers.at(index);
    v.terrainLayerVisible[layer->title] = visible;
    updateGUI();
}

void mainApp::setTerrainOverlayVisible(int index, bool visible) {
    AppViewport& v = viewports.at(selectedViewport);
    TerrainLayerCollection *overlay = terrainOverlays.at(index);
    v.terrainOverlayVisible[overlay->title] = visible;
    updateGUI();
}


void mainApp::guiEvent(ofxUIEventArgs &e)
{
	string name = e.widget->getName(); 
	int kind = e.widget->getKind(); 
    
    if (name == "RESET CAMERA") {
        resetCam(viewports.at(0).getCamera());
    }
    
    AppViewport& v = viewports.at(selectedViewport);
    
    if (kind == OFX_UI_WIDGET_TOGGLE) {
        ofxUIToggle *toggle = (ofxUIToggle *) e.widget; 
        bool value = toggle->getValue(); 

        for (int i = 0; i < terrainLayers.size(); i++) {
            TerrainLayer *layer = terrainLayers.at(i);
            if (layer->title == name) {
                setTerrainLayerVisible(i, value);
                break;
            }
        }

        for (int i = 0; i < featureLayers.size(); i++) {
            MapFeatureLayer *layer = featureLayers.at(i);
            if (layer->title == name) {
                setFeatureLayerVisible(i, value);
                break;
            }
        }

        for (int i = 0; i < terrainOverlays.size(); i++) {
            TerrainLayerCollection *overlay = terrainOverlays.at(i);
            if (overlay->title == name) {
                setTerrainOverlayVisible(i, value);
                break;
            }
        }
        
        if (name == "FULLSCREEN") {
            if (MULTI_WINDOWS) {
                v.fullscreenEnabled = value;
            } else {
                for (int i = 0; i < viewports.size(); i++) {
                    viewports.at(i).fullscreenEnabled = value;
                }
            }
            ofSetFullscreen(value);
        }
        /*if (name == "DUALSCREEN") {
            dualscreenEnabled = value;
        }*/
        if (name == "LIGHTING") {
            v.lightingEnabled = value;
        }
        if (name == "ORTHOGONAL") {
            if (value) {
                v.getCamera().enableOrtho();
            } else {
                v.getCamera().disableOrtho();
            }
        }
        
        if (name == "TERRAIN") {
            v.drawTerrainEnabled = value;
        }
        if (name == "OVERLAYS") {
            v.drawOverlaysEnabled = value;
        }
        if (name == "TEXTURES") {
            v.drawTexturesEnabled = value;
        }
        if (name == "GRID") {
            v.drawTerrainGridEnabled = value;
        }
        if (name == "FEATURES") {
            v.drawMapFeaturesEnabled = value;
        }
        if (name == "MINIMAP") {
            v.drawMiniMapEnabled = value;
        }
        if (name == "VIDEO") {
            v.drawVideoEnabled = value;
        }
        if (name == "DEBUG") {
            drawDebugEnabled = value;
        }
        if (name == "WIREFRAMES") {
            v.drawWireframesEnabled = value;
        }
        
        if (name == "SEND TERRAIN") {
            if (value) {
                ofxUIToggle *other = (ofxUIToggle *)calibrationGUI->getWidget("SEND FEATURES");
                other->setValue(false);
                reliefSendMode = RELIEF_SEND_TERRAIN;
                updateVisibleMap(true);
            } else {
                reliefSendMode = RELIEF_SEND_OFF;
            }
        }
        if (name == "SEND FEATURES") {
            if (value) {
                ofxUIToggle *other = (ofxUIToggle *)calibrationGUI->getWidget("SEND TERRAIN");
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
            v.lightAttenuation = value;
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
            v.globalScale = ofVec2f(value, value);
            ((ofxUISlider *)calibrationGUI->getWidget("GLOBAL SCALE X"))->setValue(value);
            ((ofxUISlider *)calibrationGUI->getWidget("GLOBAL SCALE Y"))->setValue(value);
        }
        if (name == "GLOBAL SCALE X") {
            v.globalScale.x = value;
        }
        if (name == "GLOBAL SCALE Y") {
            v.globalScale.y = value;
        }
        if (name == "GLOBAL OFFSET X") {
            v.globalOffset.x = value;
        }
        if (name == "GLOBAL OFFSET Y") {
            v.globalOffset.y = value;
        }
        /*
        if (name == "GLOBAL OFFSET Z") {
            v.globalOffset.z = value;
        }
         */
    }
    
	cout << "got event from: " << name  << " " << kind << " " << OFX_UI_WIDGET_TOGGLE << endl; 	
}

void mainApp::update() 
{
    SetSystemUIMode(kUIModeAllHidden, kUIOptionAutoShowMenuBar);
    // ripple (from ofxFX)
    rip.begin();
    ofFill();
    ofSetColor(ofNoise( ofGetFrameNum() ) * 255 * 5, 255);
    ofEllipse(mouseX,mouseY, 10, 10);
    rip.end();
    if (ofGetFrameNum() % RIPPLE_UPDATE_INTERVAL == 0) {
        rip.update();
        bounce << rip;
        bounce.update();
        terrainLayers.at(1)->setTextureReference(bounce.getTextureReference());
    }

   
    realworldUnitToTerrainUnit = realworldUnitToGlUnit / (1 / terrainUnitToGlUnit);
    
    for (int i = lights.size() - 1; i >= 0; i--) {
        ofLight* light = lights.at(i);
        if (animateLight == i) {
            float r = 16;
            float x = r * cos(ofGetElapsedTimef() - animateLightStart);
            float y = r * sin(ofGetElapsedTimef() - animateLightStart);
            x -= r / 2;
            y -= r / 2;
            light->setPosition(animateLightStartPos + ofVec3f(x, y, 3));
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

void mainApp::drawTerrain(int viewport) {
    AppViewport v = viewports.at(viewport);
    
    if (v.lightingEnabled) {
        for (int i = lights.size() - 1; i >= 0; i--) {
            ofLight* light = lights.at(i);
            light->setAttenuation(v.lightAttenuation / v.globalScale.x);
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
    
    for (int i = s - 1; i >= 0; i--) {
        TerrainLayer *layer = terrainLayers.at(i);
        bool visible = layer->visible;
        layer->visible = v.terrainLayerVisible[layer->title];
        if (layer->visible) {
            bool drawTexture = layer->drawTexture,
                visible = layer->visible;
            
            layer->drawTexture = drawTexture && v.drawTexturesEnabled;
            layer->visible = visible && layer->opacity > .1;
            if (v.lightingEnabled && layer->lighting) {
                ofEnableLighting();
            } else {
                ofDisableLighting();
            }
            layer->draw();
            layer->drawTexture = drawTexture;
            layer->visible = visible;
        }
        layer->visible = visible;
    }
    
    ofDisableBlendMode();
    ofPopMatrix();

    if (v.lightingEnabled) {
        ofDisableLighting();
    }
}

void mainApp::drawTerrainOverlays(int viewport) {
    AppViewport v = viewports.at(viewport);

    ofPushMatrix();
//    ofTranslate(terrainSW + terrainExtents / 2);
//    ofScale(terrainToHeightMapScale.x, terrainToHeightMapScale.y, terrainToHeightMapScale.z);
    int s = terrainOverlays.size();

    ofEnableBlendMode(OF_BLENDMODE_ALPHA);
    ofEnableBlendMode(OF_BLENDMODE_ADD);
    
    ofSetColor(255, 255, 0, 128);
    
    for (int i = s - 1; i >= 0; i--) {
        TerrainLayerCollection *overlay = terrainOverlays.at(i);
        bool overlayVisible = overlay->visible;
        overlay->visible = v.terrainOverlayVisible[overlay->title];
        if (overlay->visible) {
            for (int j = overlay->terrainLayers.size() - 1; j >= 0; j--) {
                TerrainLayer* layer = overlay->terrainLayers.at(j);
                bool drawTexture = layer->drawTexture,
                    visible = layer->visible;
                float opacity = layer->opacity;
                layer->drawTexture = drawTexture && v.drawTexturesEnabled;
                layer->visible = visible && layer->opacity > .1;
                layer->draw();
                layer->drawTexture = drawTexture;
                layer->visible = visible;
                layer->opacity = opacity;
            }
        }
        overlay->visible = overlayVisible;
    }
    
    ofDisableBlendMode();
    ofPopMatrix();
}

void mainApp::drawMapWidgets(int viewport)
{
    for (int i = 0; i < mapWidgets.size(); i++) {
        MapWidget *widget = mapWidgets.at(i);
        //widget->draw();
    }
}

void mainApp::drawMapFeatures(int viewport)
{
    AppViewport v = viewports.at(viewport);

    ofEnableBlendMode(OF_BLENDMODE_ADD);
    ofEnableBlendMode(OF_BLENDMODE_ALPHA);

    for (int i = 0; i < featureLayers.size(); i++) {
        MapFeatureLayer *layer = featureLayers.at(i);
        
        bool visible = layer->visible;
        layer->visible = v.featureLayerVisible[layer->title];
        if (layer->visible) {
            vector<float> opacities;
            for (int j = 0; j < layer->featureCollections.size(); j++) {
                MapFeatureCollection *coll = layer->featureCollections.at(j);
                float p = timeline.getCursorPos(),
                opacity = coll->opacity;
                opacities.push_back(opacity);
                if (/*p > 0 && p < 1 &&*/ coll->timelinePos >= 0) {
                    float delta = abs(p - coll->timelinePos);
                    coll->opacity = opacity * fmax(0, 1 - delta * 1 / TIMELINE_VISIBLE_RANGE);
                }
            }
            layer->draw();
            for (int j = 0; j < layer->featureCollections.size(); j++) {
                MapFeatureCollection *coll = layer->featureCollections.at(j);
                coll->opacity = opacities.at(j);
            }
        }
        layer->visible = visible;
    }

    ofDisableBlendMode();
}

void mainApp::drawLights(int viewport) {
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
    ofBackground(COLOR_BACKGROUND);
    for (int i = 0; i < viewports.size(); i++) {
        AppViewport& v = viewports.at(i);
        //v.getCamera().update();
        if (!MULTI_WINDOWS || i == 0) {
            v.draw();
        }
        if (drawDebugEnabled || calibrationMode) {
            ofSetLineWidth(1);
            if (i == selectedViewport) {
                ofSetColor(255, 0, 0);
            } else {
                ofSetColor(255);
            }
            ofFill();
            ofRect(v.selectRect);
            ofNoFill();
            ofRect(v.rect);
        }
    }
    
    //ofLog() << "VIEWPORT " << i << "  " << v.position << "  " << v.width << "x" << v.height;

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
    if (drawDebugEnabled) {
        ofSetColor(255,255);
        bounce.draw(0,0);
        //ofDrawBitmapString("ofxRipples ( damping = " + ofToString(rip.damping) + " )", 15,15);
    }



}

void mainApp::drawWorld(int viewport, bool useARMatrix)
{
    int markerID = -1;
    AppViewport v = viewports.at(viewport);
    
    if (useARMatrix) {
        #if (USE_QCAR)
        ofxQCAR * qcar = ofxQCAR::getInstance();
        qcar->draw();
        
        if (qcar->hasFoundMarker()) {
            string markerName = qcar->getMarkerName();
            if (markerName == "MarkerQ") {
                globalOffset = reliefToMarker1Offset;
            } else if (qcar->getMarkerName() == "MarkerC") {
                globalOffset = reliefToMarker2Offset;
            } else {
                globalOffset = ofVec3f(0, 0, 0);
            }
            modelViewMatrix = qcar->getProjectionMatrix();
            projectionMatrix = qcar->getModelViewMatrix();
            noMarkerSince = 0;
        }
        //useARMatrix = noMarkerSince > -NO_MARKER_TOLERANCE_FRAMES;
        #elif (USE_ARTK)
        if (artkEnabled) {
            artkController.draw(drawVideoEnabled || calibrationMode, drawDebugEnabled || calibrationMode, drawVideoEnabled && !calibrationMode);
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
            if (MULTI_WINDOWS) {
                v.getCamera().begin();
            } else {
                v.getCamera().begin(v.rect);
            }
            //logCam(cam);
        }

        ofPushMatrix();
        
            #if (!USE_QCAR)
            if (v.getCamera().getOrtho()) {
                //ofTranslate(ofGetWidth() / 2, ofGetHeight() / 2, 0);
            }
            #endif
            
            ofTranslate(v.globalOffset);
            ofScale(v.globalScale.x, v.globalScale.y);
    
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
                    //ofTranslate(-mapCenter);
    
                    //!! tmp
    if (v.viewportIndex == 0) {
                    ofTranslate(-terrainSW);
    } else {
        ofTranslate(-mapCenter);
        
    }
    
    
    

                    if (v.drawTerrainEnabled && !calibrationMode) {
                        glEnable(GL_DEPTH_TEST);
                        drawTerrain(viewport);
                        glDisable(GL_DEPTH_TEST);
                    }

                    if (v.drawOverlaysEnabled && !calibrationMode) {
                        //glEnable(GL_DEPTH_TEST);
                        drawTerrainOverlays(viewport);
                        //glDisable(GL_DEPTH_TEST);
                    }

                    if (v.drawMapFeaturesEnabled) {
                        drawMapFeatures(viewport);
                    }
    
                    ofEnableBlendMode(OF_BLENDMODE_ADD);
                    drawMapWidgets(viewport);
                    ofDisableBlendMode();
    
                    if (v.drawTerrainGridEnabled || calibrationMode) {
                        drawTerrainGrid(viewport);
                    }
        
                    if (drawDebugEnabled && v.lightingEnabled) {
                        drawLights(viewport);
                    }
    
                ofPopMatrix();


    
                if (drawDebugEnabled || calibrationMode) {
                    drawIdentity(viewport);
                }
    
            ofPopMatrix();
    
            if ((drawDebugEnabled && reliefSendMode != RELIEF_SEND_OFF) || calibrationMode) {
                drawReliefGrid(viewport);
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
        v.getCamera().end();
    }
    

}

void mainApp::drawGUI()
{
    AppViewport& v = viewports.at(0);
    
    if (v.drawMiniMapEnabled) {
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
        ofNoFill();
        
        focusLayer->textureImage.draw(p, miniMapW, miniMapH);
        if (v.drawMapFeaturesEnabled && featureMap.isAllocated()) {
            featureMap.draw(p, miniMapW, miniMapH);
        }
        
        ofPushMatrix();
        ofTranslate(p.x, p.y + miniMapH);
        ofScale(miniMapW / terrainExtents.x, -miniMapH / terrainExtents.y);
        ofTranslate(-terrainSW);
        
        if (v.drawTerrainGridEnabled) {
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
        ofNoFill();
        ofSetColor(255);
        terrainCrop.draw(p, miniMapW, imgH);
        if (v.drawMapFeaturesEnabled && featureMapCrop.width) {
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
                ofNoFill();
            }
        }
        ofDisableBlendMode();
    }
    
    if (calibrationMode) {
        ofEnableBlendMode(OF_BLENDMODE_ALPHA);
        ofFill();
        ofSetColor(20, 20, 20, 150);
        ofRect(0, 0, ofGetWidth(), ofGetHeight());
        ofNoFill();
        ofDisableBlendMode();
    }
    
    if (drawDebugEnabled) {
        string msg = "fps: " + ofToString(ofGetFrameRate(), 2);
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
        }    
        
        ofVec2f consolePos = ofVec2f(ofGetWidth() / 2, 20);
        /*ofSetColor(0);
         ofDrawBitmapString(msg, consolePos.x + 1, consolePos.y + 1);
         ofDrawBitmapString(msg, consolePos.x - 1, consolePos.y - 1);*/
        ofSetColor(255);
        ofDrawBitmapString(msg, consolePos.x, consolePos.y);
    }
    
    
    int x = 40, y = 40;
    ofSetColor(255);
    ofNoFill();
    
//    timeline.draw();
    
}

void mainApp::drawGrid(int viewport, ofVec2f sw, ofVec2f ne, int subdivisionsX, int subdivisionsY, ofColor line, ofColor background) {
    ofFill();
    ofSetColor(background);
    ofRect(sw.x, sw.y, ne.x - sw.x, ne.y - sw.y);
    ofNoFill();
    drawGrid(0, sw, ne, subdivisionsX, subdivisionsY, line);
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



void mainApp::drawGrid(int viewport, ofVec2f sw, ofVec2f ne, int subdivisionsX, int subdivisionsY, ofColor line) {
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

void mainApp::drawTerrainGrid(int viewport) {
    drawGrid(viewport, terrainSW, terrainNE, GRID_SUBDIVISIONS, GRID_SUBDIVISIONS, COLOR_GRID);
}

void mainApp::drawReliefGrid(int viewport)
{
    ofPushMatrix();
    ofScale(realworldUnitToGlUnit, realworldUnitToGlUnit, realworldUnitToGlUnit);
    float reliefScreenW = RELIEF_SIZE_X;
    float reliefScreenH = RELIEF_SIZE_Y;
    ofEnableBlendMode(OF_BLENDMODE_ALPHA);
    drawGrid(viewport, ofVec2f(-reliefScreenW / 2, -reliefScreenH / 2), ofVec2f(reliefScreenW / 2, reliefScreenH / 2), 1, 1, ofColor(200, 200, 200, 200), ofColor(255, 0, 0, 100));
    ofDisableBlendMode();
            
    ofPopMatrix();
}

void mainApp::drawReliefFrame(int viewport)
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

void mainApp::drawIdentity(int viewport) {
    glLineWidth(LINE_WIDTH_GRID_WHOLE);
    ofSetColor(255, 0, 0);
    ofLine(ofVec3f(0, 0, 0), ofVec3f(1, 0, 0));
    ofSetColor(0, 255, 0);
    ofLine(ofVec3f(0, 0, 0), ofVec3f(0, 1, 0));
    ofSetColor(0, 0, 255);
    ofLine(ofVec3f(0, 0, 0), ofVec3f(0, 0, 1));
}


TerrainLayer * mainApp::addTerrainLayerFromHeightMap(string name, string heightmap, string texture, float peakHeight) {
    TerrainLayer *layer = addTerrainLayer(name);
    layer->loadTexture(texture);
    layer->loadHeightMap(heightmap, peakHeight);
    return layer;
}

TerrainLayer * mainApp::addTerrainLayer(string name) {
    TerrainLayer *layer = new TerrainLayer();
    layer->title = name;
    layer->opacity = TERRAIN_OPACITY;
    terrainLayers.push_back(layer);
    if (terrainLayers.size() == 1) {
        focusLayer = layer;
    }
    return layer;
}

TerrainLayerCollection * mainApp::addTerrainOverlay(string name) {
    TerrainLayerCollection *overlay = new TerrainLayerCollection();
    overlay->title = name;
    terrainOverlays.push_back(overlay);
    return overlay;
}

TerrainLayer * mainApp::createTerrainOverlayItem(string name, ofVec3f p1, ofVec3f p2, float depth, string texture) {
    TerrainLayer *layer = new TerrainLayer();
    layer->title = name;
    layer->opacity = OVERLAY_OPACITY;
    
    ofMesh mesh;
    mesh.addVertex(p1 - ofVec3f(0, 0, depth));
    mesh.addVertex(p2 - ofVec3f(0, 0, depth));
    mesh.addVertex(p2);
    mesh.addVertex(p1 - ofVec3f(0, 0, depth));
    mesh.addVertex(p1);
    mesh.addVertex(p2);
    
    mesh.addTexCoord(ofVec2f(0, 1));
    mesh.addTexCoord(ofVec2f(1, 1));
    mesh.addTexCoord(ofVec2f(1, 0));
    mesh.addTexCoord(ofVec2f(0, 1));
    mesh.addTexCoord(ofVec2f(0, 0));
    mesh.addTexCoord(ofVec2f(1, 0));
  
    layer->setMesh(mesh);
    layer->loadTexture(texture);
    
    /*ofxCvColorImage blurImage;
    ofImage* img = &layer->textureImage;
    blurImage.setFromPixels(img->getPixels(), img->getWidth(), img->getHeight());
    blurImage.blur(1);
    img->setFromPixels(blurImage.getPixels(), img->getWidth(), img->getHeight(), OF_IMAGE_COLOR);*/
    
    return layer;
}

MapFeatureLayer* mainApp::addMapFeaturelayer(string title) {
    MapFeatureLayer* layer = new MapFeatureLayer();
    layer->title = title;
    featureLayers.push_back(layer);
    return layer;
}


MapFeatureCollection* mainApp::loadFeaturesFromGeoJSONFile(string filePath, string title) {
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
    
    MapFeatureLayer *layer = addMapFeaturelayer(title);
    MapFeatureCollection* coll = new MapFeatureCollection();
    addFeaturesFromGeoJSONString(jsonStr, coll);

    layer->addFeatureCollection(coll);
    
    return coll;
}

MapFeatureCollection* mainApp::loadFeaturesFromGeoJSONURL(string url, string title) {
    MapFeatureLayer *layer = addMapFeaturelayer(title);
    return loadFeaturesFromGeoJSONURL(url, title, layer);
}

MapFeatureCollection* mainApp::loadFeaturesFromGeoJSONURL(string url, string title, MapFeatureLayer* layer) {
    int layerIndex = 0;
    for (int i = 0; i < featureLayers.size(); i++) {
        if (layer == featureLayers.at(i)) {
            layerIndex = i;
            break;
        }
    }
    
    MapFeatureCollection* coll = new MapFeatureCollection();
    coll->title = title;
    urlToMapFeatureCollectionIndex.insert(make_pair(url, coll));
    layer->addFeatureCollection(coll);
    ofLog() << "Loading "<< url << "\n";
    numLoading++;
    ofLoadURLAsync(url);

    return coll;
}


void mainApp::urlResponse(ofHttpResponse & response) {
    numLoading--;
    addFeaturesFromGeoJSONString(response.data, urlToMapFeatureCollectionIndex[response.request.url]);
}

//Parses a json string into map features
MapFeatureCollection* mainApp::addFeaturesFromGeoJSONString(string jsonStr, MapFeatureCollection *coll) {
    ofxJSONElement json;
    if (json.parse(jsonStr)) {
        coll->addFeaturesFromGeoJSON(json);
    } else {
        ofLog() << "Error parsing JSON";
    }
    return coll;
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

/*void mainApp::loadFeaturesFromURL(string url) {
    cout << url << "\n";
    numLoading++;
    ofLoadURLAsync(url);
}

void mainApp::urlResponse(ofHttpResponse & response) {
    numLoading--;
    addItemsFromJSONString(response.data);
}*/

//Parses a json string into map features
/*void mainApp::addItemsFromJSONString(string jsonStr) {
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
}*/


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
    ofCamera& cam = viewports.at(0).getCamera();
    
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
/*        case 119:
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
            break;*/
        case 119:
            mapCenter.y += 1;
            cam.lookAt(cam.getLookAtDir() + ofVec3f(0, 1, 0));
            break;
        case 115:
            break;
        case 97:
            break;
        case 100:
            break;

            // IK
        case 105:
            lights.at(0)->move(ofVec3f(0, 0, KEYBOARD_INC));
            break;
        case 107:
            lights.at(0)->move(-ofVec3f(0, 0, KEYBOARD_INC));
            break;
            
        // X
        case 120:
            saveSettings();
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
}

//--------------------------------------------------------------
void mainApp::mousePressed(int x, int y, int button){
    cursorNotMovedSince = 0;
    for (int i = 0; i < viewports.size(); i++) {
        if (viewports.at(i).selectRect.intersects(ofRectangle(x, y, 1, 1))) {
            selectedViewport = i;
            updateGUI();
        }
    }
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
