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
    videoGrabber.setDeviceID(1);
	videoGrabber.initGrabber(VIDEO_WIDTH, VIDEO_HEIGHT);
    videoWidth = videoGrabber.getWidth();
    videoHeight = videoGrabber.getHeight();
    ofLog() << "Initialized videoGrabber at " << videoWidth << "x" << videoHeight;
	videoImage.allocate(videoWidth, videoHeight);
	//grayImage.allocate(videoWidth, videoHeight);
	//grayThres.allocate(videoWidth, videoHeight);
	artkThreshold = 85;
    artk.setup(videoWidth, videoHeight);
	artk.setThreshold(artkThreshold);
}

void ARTKController::update() {
    videoScale = max(ofGetWidth() / (1.0f * videoWidth), ofGetHeight() / (1.0f * videoHeight));
    videoX = 0;
    videoY = 0;
    
    videoGrabber.update();
    if (videoGrabber.isFrameNew()) {
		videoImage.setFromPixels(videoGrabber.getPixels(), videoWidth, videoHeight);
        videoImage.mirror(true, true);
        grayVideoImage = videoImage;
		// Pass in the new image pixels to artk
        artk.update(grayVideoImage.getPixels());
    }
}

void ARTKController::applyMatrix() {
    //ofTranslate(videoX, videoY);
    //ofScale(videoScale, videoScale);
    artk.applyProjectionMatrix(videoWidth * videoScale, videoHeight * videoScale);
    artk.applyModelMatrix(0);
    
    ofSphere(0, 0, 0, 1);
}

void ARTKController::draw(bool drawDebugEnabled) {
    ofPushMatrix();
    ofTranslate(videoX, videoY);
    ofScale(videoScale, videoScale);
    
    if (drawDebugEnabled) {
        grayVideoImage.threshold(artkThreshold);
        grayVideoImage.draw(0, 0, videoWidth, videoHeight);
    } else {
        videoImage.draw(0, 0, videoWidth, videoHeight);
    }
    
    artk.draw(0, 0);
    ofPopMatrix();
}
