/* AppController */

#import <Cocoa/Cocoa.h>
#import "HelpWindowController.h"
#import "VolumeView.h"
#import "VolumeViewController.h"

#include "AudioDeviceList.h"
#include "AudioThruEngine.h"
#include "SFAudioDevice.h"

#define NUM_DEVICES 2

@interface AppController : NSObject <NSApplicationDelegate> {
	NSStatusItem	*mSbItem;
	NSMenu			*_rootMenu;
	
	AudioDeviceList *mOutputDeviceList;
	
    int _AD_count;
    AudioDeviceList::Device audioDeviceIDs[64];
	
	IBOutlet HelpWindowController *mAboutController;
    //IBOutlet VolumeView *mVolumeView;
    
    SFAudioDevice *_2chDevice;
    SFAudioDevice *_16chDevice;
    NSArray <SFAudioDevice *> *_allDevices;
    
    NSInteger _crntDeviceIndex;
    VolumeViewController *_volumeViewController;
}

- (IBAction)suspend;
- (IBAction)resume;

- (IBAction)srChanged2ch;
- (IBAction)srChanged16ch;
- (IBAction)srChanged2chOutput;
- (IBAction)srChanged16chOutput;
- (IBAction)checkNchnls;
- (IBAction)volChanged2ch;

- (IBAction)refreshDevices;

- (IBAction)selectOutputDevice:(id)sender;
- (IBAction)bufferSizeChanged2ch:(id)sender;
- (IBAction)bufferSizeChanged16ch:(id)sender;
- (IBAction)routingChanged2ch:(id)sender;
- (IBAction)routingChanged16ch:(id)sender;

- (void)buildDeviceList;
- (void)buildMenu;

- (void)InstallListeners;
- (void)RemoveListeners;

- (void)readGlobalPrefs;
- (void)writeGlobalPrefs;

- (void)readDevicePrefs:(SFAudioDevice *)device;
- (void)writeDevicePrefs:(SFAudioDevice *)device;

//- (IBAction)inputLoadChanged:(id)sender;
//- (IBAction)outputLoadChanged:(id)sender;
//- (IBAction)extraLatencyChanged:(id)sender;
//- (IBAction)toggleThru:(id)sender;
//- (IBAction)inputDeviceSelected:(id)sender;
//- (IBAction)inputSourceSelected:(id)sender;
//- (IBAction)outputSourceSelected:(id)sender;
//- (void)updateActualLatency:(NSTimer *)timer;

@end
