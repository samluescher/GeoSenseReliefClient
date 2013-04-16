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
    float buffer_size = 75.f;
    
    float w = 360.f + buffer_size;
    float h = 227.f + buffer_size;
    
    //    0 ---- 1
    //   /        \
    //  /          \
    // 3 ---------- 2
    
    p0 = ofVec3f(-w/2.0, -buffer_size, 0);
    p1 = ofVec3f( w/2.0, -buffer_size, 0);
    p2 = ofVec3f( w/2.0, -buffer_size - h, 0);
    p3 = ofVec3f(-w/2.0, -buffer_size - h, 0);
    
    center = p0 + ofVec3f(w/2.0,-h/2.0,0);
    
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
            viewpoint.setOrientation(dir);
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
