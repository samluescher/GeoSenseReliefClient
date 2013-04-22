#include "mainApp.h"
#include "ofAppGlutWindow.h"
#include "ofxFensterManager.h"
#include "ofAppGlutWindow.h"
#include "config.h"

//--------------------------------------------------------------
int main() {
    
    if (MULTI_WINDOWS) {
        ofSetupOpenGL(ofxFensterManager::get(), WINDOW_W, WINDOW_H, OF_WINDOW);			// <-------- setup the GL context
        ofRunFensterApp(new mainApp());
    } else {
        ofAppGlutWindow window; // create a window
        // set width, height, mode (OF_WINDOW or OF_FULLSCREEN)
        ofSetupOpenGL(&window, WINDOW_W, WINDOW_H, OF_WINDOW);
        ofRunApp(new mainApp()); // start the app*/
    }

 
}
