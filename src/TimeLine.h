//
//  TimeLine.h
//  GeoSenseReliefClientOSX
//
//  Created by Samuel Luescher on 18.04.13.
//
//

#pragma once
#ifndef __GeoSenseReliefClientOSX__TimeLine__
#define __GeoSenseReliefClientOSX__TimeLine__

#include "MapWidget.h"

class Timeline: public MapWidget {
    
private:
    float cursorPos;
    
public:
    Timeline();
    void customDraw();
    void setCursorPos(float pos);
    float getCursorPos();
};

#endif /* defined(__GeoSenseReliefClientOSX__TimeLine__) */
