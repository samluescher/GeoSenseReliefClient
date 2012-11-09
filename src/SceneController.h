#pragma once

#include "ofMain.h"

//--------------------------------------------------------
class SceneController{
    public:
        virtual void update(ofCamera* camera) {cout << "Update not overridden" << endl;};
};

