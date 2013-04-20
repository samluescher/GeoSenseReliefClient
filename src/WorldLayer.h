#pragma once

#include "ofMain.h"

class WorldLayer: public ofNode {
    public:
        WorldLayer();
        string title;
        float opacity;
        bool visible, lighting;
};
