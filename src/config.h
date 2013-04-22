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
#define LINE_WIDTH_MAP_FEATURES 6

#define COLOR_WATER ofColor(0, 100, 120, 175)

#else

#define IS_RELIEF_CEILING false
#define IS_DESK_CEILING true

#define LINE_WIDTH_GRID_SUBDIV 1
#define LINE_WIDTH_GRID_WHOLE 2
#define LINE_WIDTH_MAP_FEATURES 1

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
#define COLOR_LABEL ofColor(250)
#define COLOR_LABEL_SHADOW ofColor(30, 30, 30, 80)
#define GUI_DISAPPEAR_FRAMES 30

#define OVERLAY_OPACITY .2
#define FEATURE_OPACITY .7
#define FEATURE_POINT_RADIUS .25

#endif


#define VIDEO_WIDTH 1024
#define VIDEO_HEIGHT 768


#define VIDEO_EXPOSURE 1.0f
#define VIDEO_GAIN .8f

#define LIGHT_ATTENUATION .175f

#define GL_UNIT_TO_TERRAIN_UNIT_INITIAL 20.f


#define ARTK_THRESHOLD 80


#define EARTHQUAKE_START_YEAR 1973
#define EARTHQUAKE_END_YEAR 2011

#define TIMELINE_VISIBLE_RANGE .25


#define TIMELINE_CIRCLE_STEP .003


#define RIPPLE_UPDATE_INTERVAL 2


#define WINDOW_W 1280
#define WINDOW_H 1024
#define MULTI_WINDOWS false
#define ENABLE_FULLSCREEN true

#define VIEWPORT_SELECTOR_W 20