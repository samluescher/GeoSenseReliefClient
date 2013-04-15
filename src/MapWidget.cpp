//
//  MapWidget.cpp
//  GeoSenseReliefClientOSX
//
//  Created by Samuel Luescher on 4/11/13.
//
//

#include "MapWidget.h"
#include "config.h"

MapWidget::MapWidget() {
    lifetime = -1;
    widgetId = -1;
    baseColor = COLOR_MAP_WIDGET;
}

void MapWidget::customDraw() {
    ofColor c = baseColor;
    if (lifetime > 0) {
        c.a = lifetime / (float)initialLifetime * c.a;
    }
    ofSetColor(c);
    ofSphere(0, 0, 0, 1);
}

void MapWidget::update()
{
    if (lifetime > 0) {
        lifetime--;
    }
}

void MapWidget::setBaseColor(ofColor color) {
    baseColor = color;
}

void MapWidget::setLifetime(int frames) {
    initialLifetime = lifetime = frames;
}

bool MapWidget::shouldRemove() {
    return lifetime == 0;
}
