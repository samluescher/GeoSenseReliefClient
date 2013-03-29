#pragma once

#include "ofMain.h"

class WorldLayer: public ofNode {
    public:
        WorldLayer();
        string layerName;
        float opacity;
        bool visible, lighting;
};
