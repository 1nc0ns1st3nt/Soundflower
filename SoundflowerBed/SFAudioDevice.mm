//
//  SFDevice.m
//  Soundflowerbed
//
//  Created by blackcap on 12/10/2019.
//

#import "SFAudioDevice.h"
#import "VolumeView.h"

void updateVolumeView(SFAudioDevice *self, VolumeViewController *vvc) {
    AudioDevice outDevice(self.deviceID, false);
    VolumeView *volumeView = (VolumeView *)[vvc view];
    if (outDevice.IsVolumeAvailableForMaster() || outDevice.IsVolumeAvailableForChannels()){
        [volumeView setEnabled:true];
        float scalar = outDevice.GetVolumeScalar();
        float db = outDevice.GetVolumeDB();
        [volumeView setScalar:scalar];
        [volumeView setDB:db];
    }
}

@implementation SFAudioDevice

- (SFAudioDevice *)init {
    self = [super init];
    if (self) {
        self.selectedDeviceTag = -1;
    }
    return self;
}
- (SFAudioDevice *)initWithNumOfChannels:(int)num {
    self = [super init];
    if (self) {
        self.numOfchannels = num;
    }
    return self;
}

- (BOOL)initThruEngine {
    if (self.thruEngine == nil && self.deviceID) {
        self.thruEngine = new AudioThruEngine;
        self.thruEngine->SetInputDevice(self.deviceID);
        return true;
    }
    return false;
}

- (void)deleteThruEngine {
    if (self.thruEngine) {
        delete self.thruEngine;
//        self.thruEngine = nil;
    }
}

- (void)dealloc {
    [super dealloc];
    [self.mainMenu release];
    [self.mainMenu dealloc];
}
@end
