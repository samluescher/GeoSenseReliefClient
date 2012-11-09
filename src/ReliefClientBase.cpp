#include "ReliefClientBase.h"

//--------------------------------------------------------------
void ReliefClientBase::reliefSetup(string host, int port) {
	reliefSender.setup(host, port);
    reliefReceiver.setup(port);
}

ReliefClientBase::~ReliefClientBase() {
    ofxOscMessage m;
    m.setAddress("/relief/disconnect");
    reliefMessageSend(m);
}

ReliefClientBase::ReliefClientBase() {
    reliefSetup(RELIEF_HOST, RELIEF_PORT);
}

//--------------------------------------------------------------
void ReliefClientBase::reliefUpdate() {
    while (reliefReceiver.hasWaitingMessages()) {
        ofxOscMessage m;
        reliefReceiver.getNextMessage(&m);
        reliefMessageReceived(m);
    }
    if (ofGetElapsedTimef() > lastHearbeat + 2.f) {
        ofxOscMessage m;
        m.setAddress("/relief/heartbeat");
        reliefMessageSend(m);
    }
}

void ReliefClientBase::reliefMessageReceived(ofxOscMessage m) {
    cout << "received an OSC message, but reliefMessageReceived is not implemented.";
}

//--------------------------------------------------------------
void ReliefClientBase::reliefMessageSend(ofxOscMessage m) {
    reliefSender.sendMessage(m);
}