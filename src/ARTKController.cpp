//
//  ARtoolkitController.cpp
//  GeoSenseReliefClientOSX
//
//  Created by Samuel Luescher on 3/27/13.
//
//

#include "ARTKController.h"

ARTKController::ARTKController() {
    
    ofLog() << "*** Initializing ARTK";

    #if !(USE_LIBDC)
    //videoGrabber.setDeviceID(1);
	videoGrabber.initGrabber(VIDEO_WIDTH, VIDEO_HEIGHT);
    videoWidth = videoGrabber.getWidth();
    videoHeight = videoGrabber.getHeight();
    #else
    camera.setSize(VIDEO_WIDTH, VIDEO_HEIGHT);
	camera.setup();
    camera.setExposure(VIDEO_EXPOSURE);
    camera.setGain(VIDEO_GAIN);
    ofLog() << "exposure " << camera.getExposure() << "  gain " << camera.getGain();
    videoWidth = camera.getWidth();
    videoHeight = camera.getHeight();
    #endif
    
    ofLog() << "Initialized camera at " << videoWidth << "x" << videoHeight;
    #if !(USE_LIBDC)
	videoImage.allocate(videoWidth, videoHeight);
    #endif

	videoThreshold = ARTK_THRESHOLD;
    artk.setup(videoWidth, videoHeight);
}

void ARTKController::update() {
	artk.setThreshold(videoThreshold);
    videoScale = max(ofGetWidth() / (1.0f * videoWidth), ofGetHeight() / (1.0f * videoHeight));
    videoX = 0;
    videoY = 0;
    
    bool artkUpdate;
    
    #if !(USE_LIBDC)
    videoGrabber.update();
    artkUpdate = videoGrabber.isFrameNew();
    if (artkUpdate) {
		videoImage.setFromPixels(videoGrabber.getPixels(), videoWidth, videoHeight);
        //videoImage.mirror(true, true);
    }
    #else
    artkUpdate = camera.isReady();
    if (camera.grabVideo(cameraImage)) {
		cameraImage.update();
        videoImage.setFromPixels(cameraImage.getPixels(), videoWidth, videoHeight);
        //videoImage.mirror(true, true);
	}
    #endif

    if (artkUpdate) {
		// Pass in the new image pixels to artk
        grayVideoImage = videoImage;
        artk.update(grayVideoImage.getPixels());
    }
}

void ARTKController::applyMatrix(int markerIndex) {
    
    ofTranslate(videoX, videoY);
    ofScale(videoScale, videoScale);
    artk.applyProjectionMatrix(videoWidth * videoScale, videoHeight * videoScale);
    artk.applyModelMatrix(markerIndex);
    

    /*
    ofVec3f translation;
    ofMatrix4x4 orientation;
    artk.getTranslationAndOrientation(markerIndex, translation, orientation);
    float angle;
    ofVec3f vec;
    orientation.getRotate().getRotate(angle, vec);
    ofLog() << angle;

    ofTranslate(ofGetWidth() / 2, ofGetHeight() / 2);
    ofTranslate(translation.x, translation.y);
    ofLog() << translation;
    ofRotate(angle, vec.x, vec.y, vec.z);*/
   
//    ofSphere(0, 0, 0, 1);
}

void ARTKController::draw(bool drawVideo, bool drawThresh, bool drawFullSize) {
    ofPushMatrix();
    if (drawFullSize) {
        ofTranslate(videoX, videoY);
        ofScale(videoScale, videoScale);
    } else {
        float s = .5;
        ofTranslate(ofGetWidth() - videoWidth * s, 0);
        ofScale(s, s);
    }
    
    if (drawVideo) {
        ofSetColor(255);
        videoImage.draw(0, 0, videoWidth, videoHeight);
        if (drawThresh) {
            grayVideoImage.threshold(videoThreshold);
            grayVideoImage.draw(0, videoHeight, videoWidth, videoHeight);
        }
    }
    
    artk.draw(0, 0);
    ofPopMatrix();
}
