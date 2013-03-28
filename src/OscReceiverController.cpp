//
//  OscReceiverController.cpp
//  GeoSenseReliefClientOSX
//
//  Created by Samuel Luescher on 3/28/13.
//
//

#include "OscReceiverController.h"

void OscReceiverController::oscMessageReceived(ofxOscMessage m) {
    ofLog() << "osc message: " << m.getAddress();
}
