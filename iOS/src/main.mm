

#include "ofMain.h"
#include "mainApp.h"

int main() {
    ofAppiPhoneWindow *window = new ofAppiPhoneWindow();
    window->enableDepthBuffer();
    window->enableRetinaSupport();
    
    ofSetupOpenGL( ofPtr<ofAppBaseWindow>( window ), 1024,768, OF_FULLSCREEN );
    //window->startAppWithDelegate( "MyAppDelegate" );
    
	ofRunApp(new mainApp);
}
