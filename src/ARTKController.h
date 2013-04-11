#pragma once

#include "config.h"
#include "ofMain.h"
#include "ofEvents.h"
#include "SceneController.h"
#include "ofxOpenCv.h"
#include "ofxARToolkitPlus.h"
#include "ofxLibdc.h"

//--------------------------------------------------------
class ARTKController : public SceneController{
public:
    ARTKController();
    virtual void update();
    void applyMatrix();
    void draw(bool drawVideo, bool drawThresh, bool drawFullSize);

    #if !(USE_LIBDC)
    ofVideoGrabber videoGrabber;
    ofxCvColorImage videoImage;
    #else
    ofxLibdc::Camera camera;
    ofxCvGrayscaleImage videoImage;
    ofImage cameraImage;
    #endif
    
    ofxARToolkitPlus artk;
    int videoThreshold;
    float videoScale, videoX, videoY, videoWidth, videoHeight;
	
    /* OpenCV images */
    ofxCvGrayscaleImage grayVideoImage;
    ofMatrix4x4 artkHomoMatrix;

};

