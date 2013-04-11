//
//  config.h
//  emptyExample
//
//  Created by Samuel Luescher on 9/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#ifndef emptyExample_config_h
#define emptyExample_config_h

#include "TargetConditionals.h"

#if (TARGET_OS_IPHONE)

#define IS_RELIEF_CEILING false
#define IS_DESK_CEILING false

#define LINE_WIDTH_GRID_SUBDIV 2
#define LINE_WIDTH_GRID_WHOLE 4
#define COLOR_WATER ofColor(0, 100, 120, 175)

#else

#define IS_RELIEF_CEILING false
#define IS_DESK_CEILING true

#define LINE_WIDTH_GRID_SUBDIV 1
#define LINE_WIDTH_GRID_WHOLE 2

#if (IS_RELIEF_CEILING)
#define COLOR_WATER ofColor(0, 100, 120, 255)
#else
#define COLOR_WATER ofColor(0, 100, 120, 127)
#endif


#endif

#define USE_LIBDC true



#define COLOR_GRID ofColor(100, 100, 100, 70)
#define COLOR_BACKGROUND ofColor(0)
#define COLOR_MAP_WIDGET ofColor(255, 255, 230, 128)
#define GUI_DISAPPEAR_FRAMES 1400

#endif

#define VIDEO_WIDTH 800
#define VIDEO_HEIGHT 600

#define VIDEO_EXPOSURE 1.0f
#define VIDEO_GAIN 1.2f


#define GL_UNIT_TO_TERRAIN_UNIT_INITIAL 100.f

#define LIGHT_ATTENUATION .175f

#define ARTK_THRESHOLD 80