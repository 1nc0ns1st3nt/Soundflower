//
//  SFDevice.h
//  Soundflowerbed
//
//  Created by blackcap on 12/10/2019.
//

#import <Foundation/Foundation.h>
#import "VolumeViewController.h"
#include "AudioDeviceList.h"
#include "AudioThruEngine.h"

NS_ASSUME_NONNULL_BEGIN

struct SFAudioDevice_ {
    int numOfChannels;
    int selectedBufferSize;
    
    AudioDeviceID allDeviceIds[64];
    AudioDeviceID deviceID;
    AudioDeviceID suspendedDeviceID;
    AudioThruEngine *thruEngine;
    
    NSMenuItem *mainMenu;
    NSArray *bufferSizes;
    NSMenu *bufferMenu;
    NSMenuItem *selectedDeviceItem;
    VolumeViewController *volumeViewController;
    
    SEL menuSelector;
};

@interface SFAudioDevice : NSObject
@property int numOfchannels;
@property int selectedBufferSize;
@property int selectedDeviceTag;

//@property AudioDeviceID mMenuID[64];

@property AudioDeviceID deviceID;
@property AudioDeviceID suspendedDeviceID;
@property AudioThruEngine *thruEngine;

@property (retain) NSMenuItem *mainMenu;
@property (retain) NSArray *bufferSizes;
@property (retain) NSMenu *bufferMenu;
//@property (retain, nonatomic) VolumeViewController *volumeViewController;

- (SFAudioDevice *)initWithNumOfChannels:(int)num;
- (BOOL)initThruEngine;
- (void)deleteThruEngine;
@end

void updateVolumeView(SFAudioDevice *self, VolumeViewController *vvc);

NS_ASSUME_NONNULL_END
