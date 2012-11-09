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

#define IS_TOP_DOWN_CLIENT false

#define LINE_WIDTH_GRID_SUBDIV 2
#define LINE_WIDTH_GRID_WHOLE 4
#define COLOR_WATER ofColor(0, 100, 120, 175)

#else

#define IS_TOP_DOWN_CLIENT false

#define LINE_WIDTH_GRID_SUBDIV 1
#define LINE_WIDTH_GRID_WHOLE 2
#define COLOR_WATER ofColor(0, 160, 200, 255)

#endif

#define COLOR_GRID ofColor(100, 100, 100, 70)
#define GUI_DISAPPEAR_FRAMES 1400

#endif
