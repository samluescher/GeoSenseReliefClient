#pragma once

#include "ofMain.h"
class mainApp;
//#include "mainApp.h"

//--------------------------------------------------------
class SceneController{
    public:
        virtual void update(ofCamera & camera) {cout << "Update not overridden" << endl;};
//        virtual void update(mainApp *main) {cout << "Update not overridden" << endl;};
};

