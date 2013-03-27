#pragma once

#include "config.h"
#include "ofMain.h"
#include "ofEvents.h"
#include "SceneController.h"
#include "ofxOpenCv.h"
#include "ofxARToolkitPlus.h"

//--------------------------------------------------------
class ARTKController : public SceneController{
public:
    ARTKController();
    virtual void update();
    void applyMatrix();
    void draw(bool drawDebugEnabled);

    ofVideoGrabber videoGrabber;
    ofxARToolkitPlus artk;
    int artkThreshold;
    float videoScale, videoX, videoY, videoWidth, videoHeight;
	
    /* OpenCV images */
    ofxCvColorImage videoImage;
    ofxCvGrayscaleImage grayVideoImage;
    ofMatrix4x4 artkHomoMatrix;

};

