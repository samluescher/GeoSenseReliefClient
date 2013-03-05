//
//  ofPinchGestureRecognizer.h
//  xmlSettingsExample
//
//  Created by base on 30/09/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>  
#include "ofMain.h"

class ofPinchEventArgs : ofEventArgs {	
    public:
        ofPinchEventArgs(float sc, float vel):scale(sc), velocity(vel) {   
        }  
        
        float scale;    
        float velocity; 
};

@interface ofPinchGestureRecognizer : NSObject {

	UIPinchGestureRecognizer *pinchGestureRecognizer;  

    @public ofEvent<ofPinchEventArgs> ofPinchEvent;
}

-(id)initWithView:(UIView*)view; 
- (void)handleGesture:(UIPinchGestureRecognizer *)gestureRecognizer;

@end
