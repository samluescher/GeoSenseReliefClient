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
#define TERRAIN_OPACITY 200

#define KEYBOARD_INC .2f


#define MIN_ZOOM 50 //300
#define MAX_ZOOM 1600

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
    mapCenter = ofVec3f(141, 37.4, 0); // initially center on Fukushima
    
    terrainUnitToScreenUnit = 1 / 400.0f;    
    reliefUnitToScreenUnit = 40.0f;
    globalScale = .25f;
    
    // offset of physical Relief to physical marker
    reliefOffset = ofVec3f(0, 0, 0);
    reliefToMarker1Offset = ofVec3f(0, 265, 0);
    reliefToMarker2Offset = ofVec3f(-275, 0, 0);

    #if (IS_TOP_DOWN_CLIENT)
    reliefOffset.x = -30.5;
    reliefOffset.y = 94.25;
    globalScale = 1.27;
    #endif
    
    ofEnableNormalizedTexCoords();
    
    float s = terrainExtents.x / 880; //heightMap.width;
    terrainToHeightMapScale = ofVec3f(s, s, 1);
    terrainToHeightMapScale.z = (terrainToHeightMapScale.x + terrainToHeightMapScale.y) / 2;
    ofLog() << "terrainToHeightMapScale: " << terrainToHeightMapScale;

    terrainPeakHeight = terrainToHeightMapScale.z * 350.0f;
    featureHeight = .5f;

    
    ofLog() << " *** Creating terrain layers";
    float seaFloorPeakHeight = terrainPeakHeight * 10;
    TerrainLayer *layer;
    
    layer = addTerrainLayer("CRUST", "maps/heightmap.ASTGTM2_128,28,149,45-1600.png", "maps/srtm.ASTGTM2_128,28,149,45-14400.png", terrainPeakHeight);
    layer->setScale(1);

    layer = addTerrainLayer("PLATES", "maps/bathymetry_128,28,149,45-1600.png", "maps/ocean.blue_128,28,149,45-1600.png", seaFloorPeakHeight);
    layer->move(ofVec3f(0, 0, -(seaFloorPeakHeight + terrainPeakHeight * .1)));
    layer->setScale(ofVec3f(focusLayer->heightMap.getWidth() / layer->heightMap.getWidth(), focusLayer->heightMap.getHeight() / layer->heightMap.getHeight(), 1));
    
    layer = addTerrainLayer("MANTLE", "maps/heightmap.mantle.png", "maps/mantle.png", terrainPeakHeight);
    layer->move(ofVec3f(0, 0, -(terrainPeakHeight + seaFloorPeakHeight + terrainPeakHeight * .1)));
    layer->setScale(ofVec3f(focusLayer->heightMap.getWidth() / layer->heightMap.getWidth(), focusLayer->heightMap.getHeight() / layer->heightMap.getHeight(), 1));
    layer->lighting = false;
 
    
    ofSetSmoothLighting(true);
    ofDisableArbTex();
	pointLight.setPointLight();
    pointLight.setPosition(mapCenter + ofVec3f(3, 1, 5));
    pointLight.setDiffuseColor( ofColor(255.f, 255.f, 255.f));
	pointLight.setSpecularColor( ofColor(255.f, 255.f, 255.f));
    
    numLoading = 0;
    ofRegisterURLNotification(this);  
    //loadFeaturesFromURL("http://map.safecast.org/api/mappoints/4ff47bc60aea6a01ec00000f?b=&"+ofToString(terrainSW.x)+"b="+ofToString(terrainSW.y)+"&b="+ofToString(terrainNE.x)+"&b="+ofToString(terrainNE.y)+"&z=8");
    
    //loadFeaturesFromFile("json/safecast.8.json");
    //loadFeaturesFromFile("json/earthquakes.json");
    
    //loadFeaturesFromGeoJSONFile("json/tsunamiinundationmerge_jpf.json");
    
#if (TARGET_OS_IPHONE)
    EAGLView *view = ofxiPhoneGetGLView();  
    pinchRecognizer = [[ofPinchGestureRecognizer alloc] initWithView:view];
    ofAddListener(pinchRecognizer->ofPinchEvent,this, &mainApp::handlePinch);
#endif
    
    drawDebugEnabled = true;
    drawWireframesEnabled = false;
    calibrationMode = false;
    drawTerrainEnabled = true;
    drawTexturesEnabled = true;
    drawTerrainGridEnabled = false;
    drawMapFeaturesEnabled = false;
    drawMiniMapEnabled = false;
    drawWaterEnabled = false;
    tetherWaterEnabled = false;
    waterLevel = 0.3;
    prevWaterLevel = 0.0;
    reliefSendMode = RELIEF_SEND_OFF;
    fullscreenEnabled = false;
    lightingEnabled = false;
    ofSetFullscreen(fullscreenEnabled);

#if (IS_TOP_DOWN_CLIENT)
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
    
#if (IS_TOP_DOWN_CLIENT)
    cam.enableOrtho();
#endif
    
    layersGUI = new ofxUICanvas(spacing, spacing, guiW, ofGetHeight() * .6);     
    for (int i = 0; i < terrainLayers.size(); i++) {
        TerrainLayer *layer = terrainLayers.at(i);
        layersGUI->addToggle(layer->layerName, true, dim, dim);
    }
	layersGUI->addWidgetDown(new ofxUILabel("", OFX_UI_FONT_LARGE));

#if !(TARGET_OS_IPHONE)
	layersGUI->addToggle("FULLSCREEN", fullscreenEnabled, dim, dim);
	layersGUI->addToggle("ORTHOGONAL", cam.getOrtho(), dim, dim);
    //    layersGUI->addButton("RESET CAMERA", false, dim, dim);
#endif
    layersGUI->addToggle("LIGHTING", lightingEnabled, dim, dim);
	layersGUI->addWidgetDown(new ofxUILabel("", OFX_UI_FONT_LARGE));
    layersGUI->addSlider("ZOOM", MIN_ZOOM, MAX_ZOOM, 1 / terrainUnitToScreenUnit, guiW - spacing * 2, dim);
    layersGUI->addSlider("GLOBAL SCALE", .1, 4, globalScale, guiW - spacing * 2, dim);
	layersGUI->addWidgetDown(new ofxUILabel("", OFX_UI_FONT_LARGE));
	layersGUI->addWidgetDown(new ofxUILabel("", OFX_UI_FONT_LARGE)); 
	layersGUI->addToggle("TERRAIN", drawTerrainEnabled, dim, dim);
	layersGUI->addToggle("TEXTURES", drawTexturesEnabled, dim, dim);
	layersGUI->addToggle("GRID", drawTerrainGridEnabled, dim, dim);
	layersGUI->addToggle("FEATURES", drawMapFeaturesEnabled, dim, dim);
	layersGUI->addToggle("MINIMAP", drawMiniMapEnabled, dim, dim);
	layersGUI->addToggle("WATER", drawWaterEnabled, dim, dim);
    layersGUI->addSlider("WATER LEVEL", 0, 5.0, waterLevel, guiW - spacing * 2, dim);
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
    calibrationGUI->addSlider("GLOBAL SCALE", .1, 4, globalScale, guiW - spacing * 2, dim);
    calibrationGUI->addSlider("RELIEF OFFSET X", -200, 200, reliefOffset.x, guiW - spacing * 2, dim);
    calibrationGUI->addSlider("RELIEF OFFSET Y", -200, 200, reliefOffset.y, guiW - spacing * 2, dim);
    calibrationGUI->addSlider("RELIEF OFFSET Z", -200, 200, reliefOffset.z, guiW - spacing * 2, dim);
	ofAddListener(calibrationGUI->newGUIEvent,this,&mainApp::guiEvent);
    
    resetCam();

    #if !(TARGET_OS_IPHONE)
    ofEnableSmoothing();
    #endif

    mouseController.registerEvents(this);

    #if !(TARGET_OS_IPHONE)
    keyboardController.registerEvents(this);
    #endif
    
    cursorNotMovedSince = 0;
}

void mainApp::onPan(const void* sender, ofVec3f & distance) {
    //cout << "onPan: " << distance << "\n";
    mapCenter += distance;
    updateVisibleMap(true);
}

void mainApp::onZoom(const void* sender, float & factor) {
    cout << "onZoom: " << factor << "\n";
    updateVisibleMap(true);
}

void mainApp::onViewpointChange(const void* sender, ofNode & viewpoint) {
    //cout << "onViewpointChange: " << viewpoint.getOrientationEuler() << "\n";
}


void mainApp::resetCam()
{
    //cam.setNearClip(1);
    //cam.setFarClip(100000);
    
    cam.setPosition(mapCenter + ofVec3f(0, 0, 1 / terrainUnitToScreenUnit));
    cam.lookAt(mapCenter);
    //cam.disableMouseInput();
    
//    cam.setDistance(2000); // tmp -- for light debugging
    updateVisibleMap(true);
//    cam.setNearClip(5);
//    cam.disableMouseInput();
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

        if (name == "CRUST" || name == "PLATES" || name == "MANTLE") {
            for (int i = 0; i < terrainLayers.size(); i++) {
                TerrainLayer *layer = terrainLayers.at(i);
                if (layer->layerName == name) {
                    layer->visible = value;
                    break;
                }
            }
        }
        
        if (name == "FULLSCREEN") {
            fullscreenEnabled = value;
            ofSetFullscreen(fullscreenEnabled);
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
        if (name == "ZOOM") {
            terrainUnitToScreenUnit = 1 / value;
            updateVisibleMap(true);
        }
        if (name == "WATER LEVEL") {
            waterLevel = value; 
            ofxOscMessage message;
            message.setAddress("/relief/broadcast/waterlevel");
            message.addFloatArg(waterLevel);
            reliefMessageSend(message);
        }
        if (name == "GLOBAL SCALE") {
            globalScale = value; 
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
    reliefUpdate();
    mouseController.update();

    #if !(TARGET_OS_IPHONE)
    keyboardController.update();
    #endif
    reliefUpdate();
    oscReceiverController.update();

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
    ofPushMatrix();
    ofTranslate(terrainSW + terrainExtents / 2);
    ofScale(terrainToHeightMapScale.x, terrainToHeightMapScale.y, terrainToHeightMapScale.z); 
    int s = terrainLayers.size();
    
    ofEnableBlendMode(OF_BLENDMODE_ALPHA);
    
    if (lightingEnabled) {
        ofEnableLighting();
        pointLight.enable();
    }

    if (drawDebugEnabled) {
        ofSetColor(255, 255, 0);
        ofSphere(mapCenter.x, mapCenter.y, 0, 10);
    }
    
    for (int i = s - 1; i >= 0; i--) {
        TerrainLayer *layer = terrainLayers.at(i);
        if (layer->visible) {
            bool drawTexture = layer->drawTexture;
            layer->drawTexture = drawTexture && drawTexturesEnabled && !wireframe;
            layer->drawWireframe = wireframe;
            layer->draw();
            layer->drawTexture = drawTexture;
        }
    }
    
    if (lightingEnabled) {
        pointLight.disable();
        ofDisableLighting();
    }

    ofDisableBlendMode();
    
    ofPopMatrix();
}

void mainApp::drawMapFeatures()
{
    glLineWidth(LINE_WIDTH_GRID_WHOLE);
    ofEnableBlendMode(OF_BLENDMODE_ALPHA);
    ofSetColor(200, 250, 250, 150);
    
    for (int i = 0; i < featureLayers.size(); i++) {
        MapFeatureLayer *layer = featureLayers.at(i);
        layer->draw();
    }
}


void mainApp::draw()
{
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
    
    bool useARMatrix = noMarkerSince > -NO_MARKER_TOLERANCE_FRAMES;
    #else
    bool useARMatrix = false;
    ofBackground(COLOR_BACKGROUND);
    #endif
    
    #if (USE_ARTK)
    if (artkEnabled) {
        artkController.draw(drawDebugEnabled);
    }
    #endif
    
    ofPushView();
        
        #if (USE_QCAR)
        if (useARMatrix) {
            glMatrixMode(GL_PROJECTION);
            glLoadMatrixf(modelViewMatrix.getPtr());
            
            glMatrixMode(GL_MODELVIEW );
            glLoadMatrixf(projectionMatrix.getPtr());
        }
        #elif (USE_ARTK)
        artkController.applyMatrix();
        #else
        cam.begin();
        #endif
    
        ofPushMatrix();
        
            #if (!USE_QCAR)
            if (cam.getOrtho()) {
                ofTranslate(ofGetWidth() / 2, ofGetHeight() / 2, 0);
            }
            #endif
            
            ofTranslate(reliefOffset);
            ofScale(globalScale, globalScale, globalScale);
            
            #if (IS_TOP_DOWN_CLIENT)
            #endif
            
            ofPushMatrix();
                ofScale(1 / terrainUnitToScreenUnit, 1 / terrainUnitToScreenUnit, 1 / terrainUnitToScreenUnit);
                
                ofPushMatrix();
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
                    
                    if (drawTerrainGridEnabled || calibrationMode) {
                        drawTerrainGrid();
                    }
        
                    if (drawDebugEnabled) {
                        // draw sun
                        ofVec3f pos = pointLight.getPosition();
                        ofSetColor(255, 255, 0);
                        ofSphere(pos.x, pos.y, pos.z, .25);
                    }
    
                ofPopMatrix();


    
                if (drawDebugEnabled || calibrationMode) {
                    drawIdentity();
                }
    
            ofPopMatrix();
    
            if ((drawDebugEnabled && reliefSendMode != RELIEF_SEND_OFF) || calibrationMode) {
                drawReliefGrid();
            }
            
            #if (IS_TOP_DOWN_CLIENT)
            drawReliefFrame();
            #endif
        
        ofPopMatrix();
    
    ofPopView();
    
    #if (USE_QCAR)
    if (qcar->hasFoundMarker() && (drawDebugEnabled || calibrationMode)) {
        ofSetColor(255);
        qcar->drawMarkerCenter();
    }
    #elif (USE_ARTK)
    #else
    cam.end();
    #endif
    
    
    if (!calibrationMode) {
        mainApp::drawGUI();
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
            msg += "\nreliefUnitToScreenUnit: " + ofToString(reliefUnitToScreenUnit);
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
    reliefUnitToTerrainUnit = reliefUnitToScreenUnit / (1 / terrainUnitToScreenUnit);
    
    normalizedMapCenter = (mapCenter - terrainSW) / terrainExtents;    
    normalizedMapCenter.y = 1 - normalizedMapCenter.y;
    normalizedReliefSize = ofVec2f(RELIEF_SIZE_X * reliefUnitToTerrainUnit / terrainExtents.x, RELIEF_SIZE_Y * reliefUnitToTerrainUnit / terrainExtents.y);
    
    terrainCrop.allocate(normalizedReliefSize.x * focusLayer->textureImage.width, normalizedReliefSize.y * focusLayer->textureImage.height, OF_IMAGE_COLOR);
    featureMapCrop.allocate(normalizedReliefSize.x * featureMap.width, normalizedReliefSize.y * featureMap.height, OF_IMAGE_COLOR_ALPHA);
    
    terrainCrop.cropFrom(focusLayer->textureImage, -terrainCrop.width / 2 + normalizedMapCenter.x * focusLayer->textureImage.width, -terrainCrop.height / 2 + normalizedMapCenter.y * focusLayer->textureImage.height, terrainCrop.width, terrainCrop.height);
    featureMapCrop.cropFrom(featureMap, -featureMapCrop.width / 2 + normalizedMapCenter.x * featureMap.width, -featureMapCrop.height / 2 + normalizedMapCenter.y * featureMap.height, featureMapCrop.width, featureMapCrop.height);
    
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
    
#if !(IS_TOP_DOWN_CLIENT)
    if (updateServer) {
        ofxOscMessage m;
        m.setAddress("/relief/broadcast/map/position");
        m.addFloatArg(mapCenter.x);
        m.addFloatArg(mapCenter.y);
        m.addFloatArg(terrainUnitToScreenUnit);
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
        terrainUnitToScreenUnit = m.getArgAsFloat(2);
        
        ofxUISlider *slider = (ofxUISlider *)layersGUI->getWidget("ZOOM");
        slider->setValue(1 / terrainUnitToScreenUnit);
        
        ofLog() << "position: " << mapCenter << ", terrainUnitToScreenUnit: " << terrainUnitToScreenUnit;
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
    ofScale(reliefUnitToScreenUnit, reliefUnitToScreenUnit, reliefUnitToScreenUnit);
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
    ofScale(reliefUnitToScreenUnit, reliefUnitToScreenUnit, reliefUnitToScreenUnit);
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
    
    addFeatureLayerFromGeoJSONString(jsonStr);
}

//Parses a json string into map features
void mainApp::addFeatureLayerFromGeoJSONString(string jsonStr) {
    ofxJSONElement json;
    if (json.parse(jsonStr)) {
        MapFeatureLayer *layer = new MapFeatureLayer();
        layer->addMeshes(geoJSONFeatureCollectionToMeshes(json));
        featureLayers.push_back(layer);
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
#if (IS_TOP_DOWN_CLIENT)
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
            pointLight.setPosition(pointLight.getPosition() + ofVec3f(0, KEYBOARD_INC, 0));
            break;
        case 115:
            pointLight.setPosition(pointLight.getPosition() - ofVec3f(0, KEYBOARD_INC, 0));
            break;
        case 97:
            pointLight.setPosition(pointLight.getPosition() - ofVec3f(KEYBOARD_INC, 0, 0));
            break;
        case 100:
            pointLight.setPosition(pointLight.getPosition() + ofVec3f(KEYBOARD_INC, 0, 0));
            break;

            // IK
        case 105:
            pointLight.setPosition(pointLight.getPosition() + ofVec3f(0, 0, KEYBOARD_INC));
            break;
        case 107:
            pointLight.setPosition(pointLight.getPosition() - ofVec3f(0, 0, KEYBOARD_INC));
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
            
        #if (USE_ARTK)
        // t
        case 116:
            artkEnabled = !artkEnabled;
            break;
        #endif

        /*case OF_KEY_UP:
            pointLight.setPosition(pointLight.getPosition() + ofVec3f(0, LIGHT_POS_INC, 0));
            break;
        case OF_KEY_DOWN:
            pointLight.setPosition(pointLight.getPosition() - ofVec3f(0, LIGHT_POS_INC, 0));
            break;
        case OF_KEY_RIGHT:
            pointLight.setPosition(pointLight.getPosition() + ofVec3f(LIGHT_POS_INC, 0, 0));
            break;
        case OF_KEY_LEFT:
            pointLight.setPosition(pointLight.getPosition() - ofVec3f(LIGHT_POS_INC, 0, 0));
            break;*/
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
     terrainUnitToScreenUnit += (terrainUnitToScreenUnit * scale);
     } else {
     terrainUnitToScreenUnit -= (terrainUnitToScreenUnit * scale);
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
        mapCenter += delta * terrainUnitToScreenUnit;      
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
