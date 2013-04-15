//
//  OscReceiverController.cpp
//  GeoSenseReliefClientOSX
//
//  Created by Samuel Luescher on 3/28/13.
//
//

#include "OscReceiverController.h"

//--------------------------------------------------------------
OscReceiverController::OscReceiverController() {
    
    // arbitrary for now, will fix later
    center = ofVec3f(0,0,0);
    float w = 360;
    float h = 227;
    
    // p0 ---- p1
    //  |       |
    //  |       |
    // p3 ---- p2
    
    p0 = center - ofVec3f(-w/2.0, -75.f, 0);
    p1 = center - ofVec3f( w/2.0, -75.f, 0);
    p2 = center - ofVec3f( w/2.0, -75.f - h, 0);
    p3 = center - ofVec3f(-w/2.0, -75.f - h, 0);
    
    n = (p3 - p0).cross(p1 - p0);
}

//--------------------------------------------------------------
void OscReceiverController::oscMessageReceived(ofxOscMessage m) {
    //ofLog() << "osc message: " << m.getAddress();
    
    if (m.getAddress() == "viewport/update") {
        ofVec3f pos = ofVec3f(m.getArgAsFloat(0),m.getArgAsFloat(1),m.getArgAsFloat(2));
        ofVec3f dir = ofVec3f(m.getArgAsFloat(3),m.getArgAsFloat(4),m.getArgAsFloat(5));
        int _id = m.getArgAsInt32(6);
        
        // get intersection point with screen plane
        float t = (n.dot(pos-center))/(n.dot(dir));
        ofVec3f intersectionPoint = ofVec3f(t*dir[0]+pos[0],
                                            t*dir[1]+pos[1],
                                            t*dir[2]+pos[2]);
        
        ofVec3f c = p0;
        ofVec3f v1 = p3 - p0;
        ofVec3f v2 = p1 - p0;
        ofVec3f v = intersectionPoint - p0;
        
        float dot_vv1 = v.dot(v1);
        float dot_v1v1 = v1.dot(v1);
        float dot_vv2 = v.dot(v2);
        float dot_v2v2 = v2.dot(v2);
        
        // is point within screen?
        if( (0<= dot_vv1) && (dot_vv1 <= dot_v1v1) && (0<= dot_vv2) && (dot_vv2 <= dot_v2v2) )
        {
            MapWidget viewpoint;
            viewpoint.setPosition(pos);
            viewpoint.lookAt(intersectionPoint);
            viewpoint.widgetName = "viewpoint";
            viewpoint.widgetId = _id;        
            cout << intersectionPoint << endl;
            
            ofNotifyEvent(onViewpointChange, viewpoint, this);
        }
        else {
            cout << "doesn't intersect" << endl;
        }
        
        
    }
    else if (m.getAddress() == "viewport/add") {
        
    }
    else if (m.getAddress() == "viewport/remove") {
        
    }
}
