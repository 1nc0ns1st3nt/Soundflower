/*	
*/

#import "AppController.h"


#include <CoreServices/CoreServices.h>
#include <CoreAudio/CoreAudio.h>

/* verify_noerr was deprecated and removed in OS X High Sierra */
#ifndef verify_noerr
#define verify_noerr __Verify_noErr
#endif


#define NONE_DEVICE_TAG 1

@implementation AppController

void CheckErr(OSStatus err) {
	if (err) {
		printf("error %-4.4s %i\n", (char *)&err, (int)err);
		throw 1;
	}
}

OSStatus HardwareListenerProc(AudioHardwarePropertyID  inPropertyID,
                                                void* inClientData)
{
	AppController *app = (AppController *)inClientData;
    printf("HardwareListenerProc\n");
    
    switch(inPropertyID)
    { 
        case kAudioHardwarePropertyDevices:
//			printf("kAudioHardwarePropertyDevices\n");
			
       		// An audio device has been added or removed to the system, so lets just start over
            //[NSThread detachNewThreadSelector:@selector(refreshDevices) toTarget:app withObject:nil];
            [app refreshDevices];
            break;
			
        case kAudioHardwarePropertyIsInitingOrExiting:
            printf("kAudioHardwarePropertyIsInitingOrExiting\n");
                       // A UInt32 whose value will be non-zero if the HAL is either in the midst of
                        //initializing or in the midst of exiting the process.
            break;
			
        case kAudioHardwarePropertySleepingIsAllowed:
            printf("kAudioHardwarePropertySleepingIsAllowed\n");
                    //    A UInt32 where 1 means that the process will allow the CPU to idle sleep
                    //    even if there is audio IO in progress. A 0 means that the CPU will not be
                    //    allowed to idle sleep. Note that this property won't affect when the CPU is
                    //    forced to sleep.
            break;
			
        case kAudioHardwarePropertyUnloadingIsAllowed:
            printf("kAudioHardwarePropertyUnloadingIsAllowed\n");
                     //   A UInt32 where 1 means that this process wants the HAL to unload itself
                     //   after a period of inactivity where there are no IOProcs and no listeners
                     //   registered with any AudioObject.
			break;

    }
    
    return (noErr);
}

OSStatus DeviceListenerProc(AudioDeviceID           inDevice,
                            UInt32                  inChannel,
                            Boolean                 isInput,
                            AudioDevicePropertyID   inPropertyID,
                            void*                   inClientData)
{
	AppController *app = (AppController *)inClientData;
	
    switch(inPropertyID)
    {		
        case kAudioDevicePropertyNominalSampleRate:
			//printf("kAudioDevicePropertyNominalSampleRate\n");	
			if (isInput) {
				//printf("soundflower device potential sample rate change\n");	
				if (app->_2chDevice.thruEngine->IsRunning() &&
                    app->_2chDevice.thruEngine->GetInputDevice() == inDevice){
					//[NSThread detachNewThreadSelector:@selector(srChanged2ch) toTarget:app withObject:nil];
                    [app srChanged2ch];
                }
                else if (app->_16chDevice.thruEngine->IsRunning() &&
                         app->_16chDevice.thruEngine->GetInputDevice() == inDevice){
					//[NSThread detachNewThreadSelector:@selector(srChanged16ch) toTarget:app withObject:nil];
                    [app srChanged16ch];
                }
			}
			else {
				if (inChannel == 0) {
					//printf("non-soundflower device potential sample rate change\n");
					if (app->_2chDevice.thruEngine->IsRunning() &&
                        app->_2chDevice.thruEngine->GetOutputDevice() == inDevice){
						//[NSThread detachNewThreadSelector:@selector(srChanged2chOutput) toTarget:app withObject:nil];
                        [app srChanged2chOutput];
                    }else if (app->_16chDevice.thruEngine->IsRunning() && app->_16chDevice.thruEngine->GetOutputDevice() == inDevice){
                        //[NSThread detachNewThreadSelector:@selector(srChanged16chOutput) toTarget:app withObject:nil];
                        [app srChanged16chOutput];
                    
                    }
				}
			}
			break;
	
		case kAudioDevicePropertyDeviceIsAlive:
//			printf("kAudioDevicePropertyDeviceIsAlive\n");	
			break;
				
		case kAudioDevicePropertyDeviceHasChanged:
//			printf("kAudioDevicePropertyDeviceHasChanged\n");	
			break;
				
		case kAudioDevicePropertyDataSource:
			// printf("DeviceListenerProc : HEADPHONES! \n");
			if (app->_2chDevice.thruEngine->IsRunning() && app->_2chDevice.thruEngine->GetOutputDevice() == inDevice){
				//[NSThread detachNewThreadSelector:@selector(srChanged2chOutput) toTarget:app withObject:nil];
                [app srChanged2chOutput];
            }else if (app->_16chDevice.thruEngine->IsRunning() && app->_16chDevice.thruEngine->GetOutputDevice() == inDevice){
				//[NSThread detachNewThreadSelector:@selector(srChanged16chOutput) toTarget:app withObject:nil];
                [app srChanged16chOutput];
            }
			break;
            
        case kAudioDevicePropertyVolumeScalar:
            NSLog(@"kAudioDevicePropertyVolumeScalar");
            if (app->_2chDevice.thruEngine->GetOutputDevice() == inDevice){
                [app volChanged2ch];
            }
            break;
			
		case kAudioDevicePropertyDeviceIsRunning:
//			printf("kAudioDevicePropertyDeviceIsRunning\n");	
			break;
				
		case kAudioDeviceProcessorOverload:
//			printf("kAudioDeviceProcessorOverload\n");	
			break;
			
		case kAudioDevicePropertyAvailableNominalSampleRates:
			//printf("kAudioDevicePropertyAvailableNominalSampleRates\n");	
			break;
			
		case kAudioStreamPropertyPhysicalFormat:
			//printf("kAudioStreamPropertyPhysicalFormat\n");	
			break;
		case kAudioDevicePropertyStreamFormat:
			//printf("kAudioDevicePropertyStreamFormat\n");	
			break;
			
		case kAudioDevicePropertyStreams:
			//printf("kAudioDevicePropertyStreams\n");
		case kAudioDevicePropertyStreamConfiguration:
			//printf("kAudioDevicePropertyStreamConfiguration\n");
			if (!isInput) {
				if (inChannel == 0) {
					if (app->_2chDevice.thruEngine->GetOutputDevice() == inDevice || app->_16chDevice.thruEngine->GetOutputDevice() == inDevice) {
						//printf("non-soundflower device potential # of chnls change\n");
						//[NSThread detachNewThreadSelector:@selector(checkNchnls) toTarget:app withObject:nil];
                        [app checkNchnls];
					}
					else{ // this could be an aggregate device in the middle of constructing, going from/to 0 chans & we need to add/remove to menu
						//[NSThread detachNewThreadSelector:@selector(refreshDevices) toTarget:app withObject:nil];
                        [app refreshDevices];
                    }
				}
			}
			break;
		
		default:
			//printf("unsupported notification:%s\n", (char*)inPropertyID);	
			break;
	}
	
	return noErr;
}

#include <mach/mach_port.h>
#include <mach/mach_interface.h>
#include <mach/mach_init.h>

#include <IOKit/pwr_mgt/IOPMLib.h>
#include <IOKit/IOMessage.h>

io_connect_t  root_port;

void
MySleepCallBack(void * x, io_service_t y, natural_t messageType, void * messageArgument)
{  
	AppController *app = (AppController *)x;

    switch ( messageType ) {
        case kIOMessageSystemWillSleep:
		    //printf("kIOMessageSystemWillSleep\n");

            [app suspend];
            IOAllowPowerChange(root_port, (long)messageArgument);
            break;
			
		case kIOMessageSystemWillNotSleep:
			//printf("kIOMessageSystemWillNotSleep\n");
			break;
			
        case kIOMessageCanSystemSleep:
			 //printf("kIOMessageCanSystemSleep\n");
            /* Idle sleep is about to kick in, but applications have a chance to prevent sleep
            by calling IOCancelPowerChange.  Most applications should not do this. */

            //IOCancelPowerChange(root_port, (long)messageArgument);

            /*  Power Manager waits for your reply via one of these functions for up
            to 30 seconds. If you don't acknowledge the power change by calling
            IOAllowPowerChange(), you'll delay sleep by 30 seconds. */

            IOAllowPowerChange(root_port, (long)messageArgument);
            break;

        case kIOMessageSystemHasPoweredOn:
			//printf("kIOMessageSystemHasPoweredOn\n");
            [NSTimer scheduledTimerWithTimeInterval:1.0 target:app selector:@selector(resume) userInfo:nil repeats:NO];
		
			break;
			
		default:
			 //printf("iomessage: %08lx\n", messageType);//"kIOMessageSystemWillPowerOn\n");
			break;
    }
}

- (IBAction)suspend
{
    //printf("begin suspend\n");
    
    for (SFAudioDevice *device in _allDevices) {
        device.suspendedDeviceID = device.thruEngine->GetOutputDevice();
    }
    [self selectOutputDevice:[_rootMenu itemWithTag:-1]];
//    _2chDevice.suspendedDeviceID = _2chDevice.thruEngine->GetOutputDevice();
//    //_2chDevice.thruEngine->SetOutputDevice(kAudioDeviceUnknown);
//    [self outputDeviceSelected:[mMenu itemAtIndex:m2StartIndex]];
//
//    _16chDevice.suspendedDeviceID = _16chDevice.thruEngine->GetOutputDevice();
//    //_16chDevice.thruEngine->SetOutputDevice(kAudioDeviceUnknown);
//    [self outputDeviceSelected:[mMenu itemAtIndex:m16StartIndex]];
    //printf("return suspend\n");
}

int findIndexInArray(AudioDeviceList::Device deviceIds[64],
                     AudioDeviceID theID) {
    int i;
    for (i = -1 ; i < 64 ; i++){
        if (deviceIds[i].mID == theID){
            break;
        }
    }
    return i;
}

- (IBAction)resume
{
    //printf("resume\n");
    
//    if (_2chDevice.suspendedDeviceID == kAudioDeviceUnknown &&
//        _16chDevice.suspendedDeviceID == kAudioDeviceUnknown){
//        return;
//    }
//
    [self refreshDevices];
    
    for (SFAudioDevice *device in _allDevices) {
        if (device.suspendedDeviceID != kAudioDeviceUnknown) {
            int index = findIndexInArray(audioDeviceIDs, _2chDevice.suspendedDeviceID);
            if (index < 0) {
                printf("device for disconnected while sleep");
            } else {
                NSMenuItem *item = [_rootMenu itemWithTag:NONE_DEVICE_TAG + index + 1];
                [self selectOutputDevice:item];
            }
        }
    }
}

- (NSMenuItem *)getNoneOutputDeviceMenuItem {
    return [_rootMenu itemWithTag:NONE_DEVICE_TAG];
}

- (IBAction)srChanged2ch
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
	_2chDevice.thruEngine->Mute();
	OSStatus err = _2chDevice.thruEngine->MatchSampleRate(true);
			
	NSInteger tag = _2chDevice.selectedDeviceTag;
    [self selectOutputDevice:[_rootMenu itemWithTag:NONE_DEVICE_TAG]];
	if (err == kAudioHardwareNoError) {
		//usleep(1000);
        [self audioDevice:_2chDevice selectOutputDevice:tag];
	}
	
	_2chDevice.thruEngine->Mute(false);
	
	[pool release];
}


- (IBAction)srChanged16ch
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	_16chDevice.thruEngine->Mute();
	OSStatus err = _16chDevice.thruEngine->MatchSampleRate(true);

    NSInteger tag = _16chDevice.selectedDeviceTag;
	[self selectOutputDevice:[_rootMenu itemWithTag:NONE_DEVICE_TAG]];
	if (err == kAudioHardwareNoError) {
		//usleep(1000);
		[self audioDevice:_16chDevice selectOutputDevice:tag];
	}
	_16chDevice.thruEngine->Mute(false);
	
	[pool release];
}

- (IBAction)srChanged2chOutput
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	_2chDevice.thruEngine->Mute();
	OSStatus err = _2chDevice.thruEngine->MatchSampleRate(false);
			
	// restart devices
	if (err == kAudioHardwareNoError) {
		//usleep(1000);
        [self audioDevice:_2chDevice selectOutputDevice:_2chDevice.selectedDeviceTag];
    } else {
        [self selectOutputDevice:[_rootMenu itemWithTag:NONE_DEVICE_TAG]];
    }
	_2chDevice.thruEngine->Mute(false);
	
	[pool release];
}

- (IBAction)srChanged16chOutput
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	_16chDevice.thruEngine->Mute();
	OSStatus err = _16chDevice.thruEngine->MatchSampleRate(false);
			
	// restart devices
	if (err == kAudioHardwareNoError) {
		//usleep(1000);
        [self audioDevice:_16chDevice selectOutputDevice:_16chDevice.selectedDeviceTag];
    } else {
        [self selectOutputDevice:[_rootMenu itemWithTag:NONE_DEVICE_TAG]];
    }
	_16chDevice.thruEngine->Mute(false);
	
	[pool release];
}


- (IBAction)checkNchnls
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    for (SFAudioDevice *device in _allDevices) {
        if (device.numOfchannels != device.thruEngine->GetOutputNchnls())
        {
            NSInteger tag = device.selectedDeviceTag;
            [self selectOutputDevice:[_rootMenu itemWithTag:NONE_DEVICE_TAG]];
            //usleep(1000);
            [self audioDevice:device selectOutputDevice:tag];
        }
    }
    
	[pool release];
}


- (IBAction)refreshDevices
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[self buildDeviceList];
    [mSbItem setMenu:nil];
	//[mMenu dealloc];
    [_rootMenu release];
	
	[self buildMenu];
	
	// make sure that one of our current device's was not removed!
    bool idFound[_allDevices.count];
    AudioDeviceID audioIds[_allDevices.count];
    for (int i = 0; i < _allDevices.count; i ++) {
        SFAudioDevice *device = _allDevices[i];
        audioIds[i] = device.thruEngine->GetOutputDevice();
    }
    
	AudioDeviceList::DeviceList &thelist = mOutputDeviceList->GetList();
	AudioDeviceList::DeviceList::iterator i;
	for (i = thelist.begin(); i != thelist.end(); ++i){
        for (int idx = 0; idx < _allDevices.count; idx ++) {
            if (!idFound[idx]) {
                if (i->mID == audioIds[idx])
                    idFound[idx] = true;
            }
        }
    }
    
    for (int idx = 0; idx < _allDevices.count; idx ++) {
        SFAudioDevice *device = _allDevices[idx];
        if (idFound[idx]) {
            
            int index = findIndexInArray(audioDeviceIDs, audioIds[idx]);
            // NONE has -1 tag so, it works
            device.selectedDeviceTag = NONE_DEVICE_TAG + index + 1;
            [_rootMenu itemWithTag:index].state = NSOnState;
            
            updateVolumeView(device, _volumeViewController);
            [self buildRoutingMenu:device menuAction:@selector(routingChanged2ch:)];
            [self buildRoutingMenu:_16chDevice menuAction:@selector(routingChanged16ch:)];
            
        } else {
            [self audioDevice:device selectOutputDevice:NONE_DEVICE_TAG];
        }
    }

	[pool release];
}


- (void)InstallListeners;
{	
	// add listeners for all devices, including soundflowers
	AudioDeviceList::DeviceList &thelist = mOutputDeviceList->GetList();
	int index = 0;
	for (AudioDeviceList::DeviceList::iterator i = thelist.begin(); i != thelist.end(); ++i, ++index) {
		if (0 == strncmp("Soundflower", i->mName, strlen("Soundflower"))) {
			//verify_noerr (AudioDeviceAddPropertyListener(i->mID, 0, true, kAudioStreamPropertyPhysicalFormat, DeviceListenerProc, self));
			//verify_noerr (AudioDeviceAddPropertyListener(i->mID, 0, true, kAudioDevicePropertyStreamFormat, DeviceListenerProc, self));
			verify_noerr (AudioDeviceAddPropertyListener(i->mID, 0, true, kAudioDevicePropertyNominalSampleRate, DeviceListenerProc, self));
			//verify_noerr (AudioDeviceAddPropertyListener(i->mID, 0, true, kAudioDevicePropertyLatency, DeviceListenerProc, self));
			//verify_noerr (AudioDeviceAddPropertyListener(i->mID, 0, true, kAudioDevicePropertySafetyOffset, DeviceListenerProc, self));
			verify_noerr (AudioDeviceAddPropertyListener(i->mID, 0, true, kAudioDevicePropertyStreamConfiguration, DeviceListenerProc, self));
			//verify_noerr (AudioDeviceAddPropertyListener(i->mID, 0, true, kAudioDevicePropertyAvailableNominalSampleRates, DeviceListenerProc, self));
			
			verify_noerr (AudioDeviceAddPropertyListener(i->mID, 0, true, kAudioDevicePropertyDeviceIsAlive, DeviceListenerProc, self));
			verify_noerr (AudioDeviceAddPropertyListener(i->mID, 0, true, kAudioDevicePropertyDeviceHasChanged, DeviceListenerProc, self));
			verify_noerr (AudioDeviceAddPropertyListener(i->mID, 0, true, kAudioDevicePropertyDeviceIsRunning, DeviceListenerProc, self));
			verify_noerr (AudioDeviceAddPropertyListener(i->mID, 0, true, kAudioDeviceProcessorOverload, DeviceListenerProc, self));
		}
		else {
			//verify_noerr (AudioDeviceAddPropertyListener(i->mID, 0, false, kAudioStreamPropertyPhysicalFormat, DeviceListenerProc, self));
			//verify_noerr (AudioDeviceAddPropertyListener(i->mID, 0, false, kAudioDevicePropertyStreamFormat, DeviceListenerProc, self));
			verify_noerr (AudioDeviceAddPropertyListener(i->mID, 0, false, kAudioDevicePropertyNominalSampleRate, DeviceListenerProc, self));
			//verify_noerr (AudioDeviceAddPropertyListener(i->mID, 0, false, kAudioDevicePropertyLatency, DeviceListenerProc, self));
			//verify_noerr (AudioDeviceAddPropertyListener(i->mID, 0, false, kAudioDevicePropertySafetyOffset, DeviceListenerProc, self));
			verify_noerr (AudioDeviceAddPropertyListener(i->mID, 0, false, kAudioDevicePropertyStreamConfiguration, DeviceListenerProc, self));
			verify_noerr (AudioDeviceAddPropertyListener(i->mID, 0, false, kAudioDevicePropertyStreams, DeviceListenerProc, self));
			//verify_noerr (AudioDeviceAddPropertyListener(i->mID, 0, false, kAudioDevicePropertyAvailableNominalSampleRates, DeviceListenerProc, self));

			// this provides us, for example, with notification when the headphones are plugged/unplugged during playback
			verify_noerr (AudioDeviceAddPropertyListener(i->mID, 0, false, kAudioDevicePropertyDataSource, DeviceListenerProc, self));

			verify_noerr (AudioDeviceAddPropertyListener(i->mID, 1, false, kAudioDevicePropertyVolumeScalar, DeviceListenerProc, self));
		}
	}
		
	// check for added/removed devices
   verify_noerr (AudioHardwareAddPropertyListener(kAudioHardwarePropertyDevices, HardwareListenerProc, self));
   
	verify_noerr (AudioHardwareAddPropertyListener(kAudioHardwarePropertyIsInitingOrExiting, HardwareListenerProc, self));
	verify_noerr (AudioHardwareAddPropertyListener(kAudioHardwarePropertySleepingIsAllowed, HardwareListenerProc, self));
	verify_noerr (AudioHardwareAddPropertyListener(kAudioHardwarePropertyUnloadingIsAllowed, HardwareListenerProc, self));
	
/*	UInt32 val, size = sizeof(UInt32);
	AudioHardwareGetProperty(kAudioHardwarePropertySleepingIsAllowed, &size, &val);
	printf("Sleep is %s\n", (val ? "allowed" : "not allowed"));
	AudioHardwareGetProperty(kAudioHardwarePropertyUnloadingIsAllowed, &size, &val);
	printf("Unloading is %s\n", (val ? "allowed" : "not allowed"));
*/
}	

- (void)RemoveListeners
{
	AudioDeviceList::DeviceList &thelist = mOutputDeviceList->GetList();
    AudioDeviceList::DeviceList::iterator i;
	int index = 0;
	for (i = thelist.begin(); i != thelist.end(); ++i, ++index) {
		if (0 == strncmp("Soundflower", i->mName, strlen("Soundflower"))) {
			verify_noerr (AudioDeviceRemovePropertyListener(i->mID, 0, true, kAudioDevicePropertyNominalSampleRate, DeviceListenerProc));
			verify_noerr (AudioDeviceRemovePropertyListener(i->mID, 0, true, kAudioDevicePropertyStreamConfiguration, DeviceListenerProc));
		}
		else {
			verify_noerr (AudioDeviceRemovePropertyListener(i->mID, 0, false, kAudioDevicePropertyNominalSampleRate, DeviceListenerProc));
			verify_noerr (AudioDeviceRemovePropertyListener(i->mID, 0, false, kAudioDevicePropertyStreamConfiguration, DeviceListenerProc));
			verify_noerr (AudioDeviceRemovePropertyListener(i->mID, 0, false, kAudioDevicePropertyStreams, DeviceListenerProc));
			verify_noerr (AudioDeviceRemovePropertyListener(i->mID, 0, false, kAudioDevicePropertyDataSource, DeviceListenerProc));
		}
	}

	 verify_noerr (AudioHardwareRemovePropertyListener(kAudioHardwarePropertyDevices, HardwareListenerProc));
}

- (id)init
{
	mOutputDeviceList = NULL;
    
    _2chDevice = [[SFAudioDevice.alloc initWithNumOfChannels:2] retain];
    _2chDevice.bufferSizes = @[@64, @128, @256, @512, @1024, @2048];
    _2chDevice.selectedBufferSize = 512;
    
    _16chDevice = [[SFAudioDevice.alloc initWithNumOfChannels:16] retain];
    _16chDevice.bufferSizes = @[@64, @128, @256, @512, @1024, @2048];
	
    _crntDeviceIndex = -1;
    _allDevices = [@[_2chDevice, _16chDevice] retain];
    
	return self;
}

- (void)dealloc
{
	[self RemoveListeners];
	delete mOutputDeviceList;
		
	[super dealloc];
}

NSMenuItem *addMenuItem(NSMenu *menu, NSString *title, id target, SEL action) {
    NSMenuItem *item = [menu addItemWithTitle:title action:action keyEquivalent:@""];
    item.target = target;
    return item;
}

/*- (void)updateThruLatency
{
	[mTotalLatencyText setIntValue:gThruEngine->GetThruLatency()];
}
*/
- (void)buildRoutingMenu:(SFAudioDevice *)audioDevice
              menuAction:(SEL)menuAction
{
    NSMenuItem *hostMenu = audioDevice.mainMenu;
    AudioThruEngine *thruEngine = audioDevice.thruEngine;
    AudioDeviceID outDev = thruEngine->GetOutputDevice();
    
    AudioDeviceList::DeviceList &thelist = mOutputDeviceList->GetList();
    AudioDeviceList::DeviceList::iterator i;
    char *name = 0;
    for (i = thelist.begin(); i != thelist.end(); ++i) {
        if (i->mID == outDev) {
            name = i->mName;
            break;
        }
    }
    int nchnls = thruEngine->GetOutputNchnls();
    NSLog(@"build routing menu for %@ %d", audioDevice, nchnls);
    
    for (int chnlNum = 1; chnlNum <= nchnls; chnlNum++) {
        
        NSMenuItem *parentItem = [[hostMenu submenu] itemWithTag:chnlNum];
        
        NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Output Device Channel"];
        
        
        NSMenuItem *item;
        item = [menu addItemWithTitle:@"None" action:menuAction keyEquivalent:@""];
        item.target = self;
        [item setState:NSOnState];
        
        int base = thruEngine->GetChannelMap(chnlNum);
        for (UInt32 c = 1; c <= nchnls; ++c) {
            NSString *title = [NSString stringWithFormat:@"%s [%d]", name, c];
            item = addMenuItem(menu, title, self, menuAction);
            
            // set check marks according to route map
            if (c == 1 + base) {
                [[menu itemAtIndex:0] setState:NSOffState];
                [item setState:NSOnState];
            }
        }
        [parentItem setSubmenu:menu];
    }
}

- (void)buildMenuFor:(SFAudioDevice *)audioDevice onTo:(NSMenu *)mMenu {
    NSString *name = [NSString stringWithFormat:@"%dch", audioDevice.numOfchannels];
    NSString *title = [NSString stringWithFormat:@"Soundflower (%@)", name];
    NSString *imgName = [NSString stringWithFormat:@"sf%d", audioDevice.numOfchannels];
    
    NSMenuItem *deviceMenu = addMenuItem(mMenu, title, self, @selector(selectedSFAudioDevice_menu:));
    [deviceMenu setImage:[NSImage imageNamed:imgName]];
    audioDevice.mainMenu = deviceMenu;
    
    title = [name stringByAppendingString:@" submenu"];
    NSMenu *submenu = [[NSMenu alloc] initWithTitle:title];
    NSMenuItem *bufItem = [submenu addItemWithTitle:@"Buffer Size" action:nil keyEquivalent:@""];
    
    title = [name stringByAppendingString:@" Buffer"];
    NSMenu *bufferMenu = [[NSMenu alloc] initWithTitle:title];
    audioDevice.bufferMenu = bufferMenu;
    
    NSMenuItem *item;
    for (NSNumber *num in audioDevice.bufferSizes) {
        item = addMenuItem(bufferMenu, [num stringValue], self, @selector(bufferSizeChanged:));
        [item setTag:[num integerValue]];
    }
    
    item = [bufferMenu itemWithTag:audioDevice.selectedBufferSize];
    [item setState:NSOnState];
    
    [bufItem setSubmenu:bufferMenu];
    
    [submenu addItem:[NSMenuItem separatorItem]];
    
    item = [submenu addItemWithTitle:@"Routing" action:nil keyEquivalent:@""];
    for (int i = 1; i <= audioDevice.numOfchannels; i++) {
        NSString *title = [NSString stringWithFormat:@"Channel %d", i];
        item = [submenu addItemWithTitle:title action:@selector(noAction) keyEquivalent:@""];
        item.tag = i;
    }
    
    [deviceMenu setSubmenu:submenu];
    
    audioDevice.selectedDeviceTag = NONE_DEVICE_TAG;
}

- (void)noAction {
    // Simply do nothing here
}

- (void)updateAudioDeviceIDs {
    AudioDeviceList::DeviceList &thelist = mOutputDeviceList->GetList();
    AudioDeviceList::DeviceList::iterator i;
    int index = 0;
    _AD_count = 0;
    
    for (i = thelist.begin(); i != thelist.end(); ++i) {
        AudioDevice ad(i->mID, false);
        if (ad.CountChannels())
        {
            audioDeviceIDs[index++] = *i;
        }
    }
    _AD_count = index;
}

- (void)buildMenu {
	_rootMenu = [[NSMenu alloc] initWithTitle:@"Main Menu"];
		
    if (_2chDevice.deviceID) {
        [self buildMenuFor:_2chDevice onTo:_rootMenu];
//        _2chDevice.bufferMenu = 0;
	} else {
		[_rootMenu addItemWithTitle:@"Soundflower Is Not Installed!!" action:nil keyEquivalent:@""];
	}
	
	if (_16chDevice.deviceID) {
        [self buildMenuFor:_16chDevice onTo:_rootMenu];
//        _16chDevice.bufferMenu.tag = 1;
		
	}
    //Volume Slider
    NSMenuItem *volumeMenu = [_rootMenu addItemWithTitle:@"Volume" action:nil keyEquivalent:@""];
    [volumeMenu setView:[_volumeViewController view]];
    [[_volumeViewController view] setEnabled:false];
    
	[_rootMenu addItem:[NSMenuItem separatorItem]];
    
    addMenuItem(_rootMenu, @"Audio Devices", nil, nil);
    
    NSMenuItem *item;
    item = addMenuItem(_rootMenu, @"None (OFF)", self, @selector(selectOutputDevice:));
    item.state = NSOnState;
    item.tag = NONE_DEVICE_TAG;
    
    
    for (int i = 0; i < _AD_count; i++) {
        AudioDeviceList::Device device = audioDeviceIDs[i];
        
        item = [_rootMenu addItemWithTitle:[NSString stringWithUTF8String:device.mName] action:@selector(selectOutputDevice:) keyEquivalent:@""];
        item.target = self;
        item.tag = i + NONE_DEVICE_TAG + 1;
    }
    
    [_rootMenu addItem:[NSMenuItem separatorItem]];
    
    // menu, title, target, selector
    addMenuItem(_rootMenu, @"Audio Setup...", self, @selector(doAudioSetup));
    addMenuItem(_rootMenu, @"About Soundflowerbed...", self, @selector(doAbout));
    addMenuItem(_rootMenu, @"Quit Soundflowerbed", self, @selector(doQuit));

	[mSbItem setMenu:_rootMenu];
}

- (void)buildDeviceList
{
	if (mOutputDeviceList) {
		[self RemoveListeners];
		delete mOutputDeviceList;
	}
    
    //Sometimes selecting "Airplay" causes empty device list for a while and then
    //changes all DeviceID(CoreAudio Restarted??), In that case we need retart
    BOOL restartRequired = false;
	mOutputDeviceList = new AudioDeviceList(false);
    while(mOutputDeviceList->GetList().size() == 0){
        restartRequired = true;
        delete mOutputDeviceList;
        [NSThread sleepForTimeInterval:0.1];
        mOutputDeviceList = new AudioDeviceList(false);
        NSLog(@"----------waiting for devices");
    }
	
	// find soundflower devices, store and remove them from our output list
	AudioDeviceList::DeviceList &thelist = mOutputDeviceList->GetList();
    AudioDeviceList::DeviceList::iterator i;
    
	int index = 0;
    
	for (i = thelist.begin(); i != thelist.end();
         ++i, ++index) {
        
		if (0 == strcmp("Soundflower (2ch)", i->mName)) {
            _2chDevice.deviceID = i->mID;
			AudioDeviceList::DeviceList::iterator toerase = i;
            i--;
			thelist.erase(toerase);
		}
		else if (0 == strcmp("Soundflower (16ch)", i->mName)) {
			_16chDevice.deviceID = i->mID;
			AudioDeviceList::DeviceList::iterator toerase = i;
            i--;
			thelist.erase(toerase);
		}
        else if (0 == strcmp("Soundflower (64ch)", i->mName)) {
            _16chDevice.deviceID = i->mID;
            AudioDeviceList::DeviceList::iterator toerase = i;
            i--;
            thelist.erase(toerase);
        }
	}
    
    [self updateAudioDeviceIDs];
    
    if (restartRequired) {
        NSLog(@"restarting Thru Engines");
        
        [_2chDevice deleteThruEngine];
        [_16chDevice deleteThruEngine];
    }

    [_2chDevice initThruEngine];
    [_16chDevice initThruEngine];
    
    _2chDevice.thruEngine->Start();
    _16chDevice.thruEngine->Start();

    [self InstallListeners];
}

- (void)awakeFromNib
{
	[[NSApplication sharedApplication] setDelegate:self];
    
    _volumeViewController = [[VolumeViewController alloc] initWithNibName:@"VolumeView" bundle:nil];
    [_volumeViewController setVolumeSliderTarget:self action:@selector(setVolume2ch:)];
    
	[self buildDeviceList];
	
	mSbItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
	[mSbItem retain];
	
	//[sbItem setTitle:@"ее"];
	[mSbItem setImage:[NSImage imageNamed:@"menuIcon"]];
	[mSbItem setHighlightMode:YES];
	
	[self buildMenu];
	
    if ([_2chDevice initThruEngine]) {
        _2chDevice.thruEngine->Start();
        [self buildRoutingMenu:_2chDevice menuAction:@selector(routingChanged2ch:)];
    }
    if ([_16chDevice initThruEngine]) {
        _16chDevice.thruEngine->Start();
        [self buildRoutingMenu:_16chDevice menuAction:@selector(routingChanged16ch:)];
    }
	if (_2chDevice.deviceID && _16chDevice.deviceID) {
        [self readGlobalPrefs];
	}
	
	// ask to be notified on system sleep to avoid a crash
	IONotificationPortRef notify;
    io_object_t           anIterator;

    root_port = IORegisterForSystemPower(self, &notify, MySleepCallBack, &anIterator);
    if (!root_port) {
		printf("IORegisterForSystemPower failed\n");
    } else
		CFRunLoopAddSource(CFRunLoopGetCurrent(),
                           IONotificationPortGetRunLoopSource(notify),
                           kCFRunLoopCommonModes);
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	if (_2chDevice.thruEngine->IsRunning())
		_2chDevice.thruEngine->Stop();
		
	if (_16chDevice.thruEngine->IsRunning())
		_16chDevice.thruEngine->Stop();
		
	if (_2chDevice.deviceID && _16chDevice.deviceID)
		[self writeGlobalPrefs];
}

//

- (void)bufferSizeChanged:(NSMenuItem *)sender {
    NSLog(@"buffer changed to %ld", sender.tag);
    
    SFAudioDevice *device = _allDevices[sender.parentItem.tag];
    NSMenuItem *lastSelectedBufferSizeItem =
        [sender.menu itemWithTag:device.selectedBufferSize];
    [lastSelectedBufferSizeItem setState:NSOffState];
    
    device.selectedBufferSize = (int)sender.tag;
    
    device.thruEngine->SetBufferSize(device.selectedBufferSize);
    [sender setState:NSOnState];
}

- (IBAction)bufferSizeChanged2ch:(NSMenuItem *)sender
{
    [self bufferSizeChanged:sender];
}

- (IBAction)bufferSizeChanged16ch:(NSMenuItem *)sender
{
	[self bufferSizeChanged:sender];
}

//

void routingChanged(NSMenuItem *outDeviceChanItem, AudioThruEngine *engine) {
    NSMenu *outDevMenu = [outDeviceChanItem menu];
    int sfChan = (int)[outDeviceChanItem parentItem].tag;
    int outDevChan = (int)[outDevMenu indexOfItem:outDeviceChanItem];
    
    // set the new channel map
    engine->SetChannelMap(sfChan, outDevChan - 1);
    
    // turn off all check marks
    for (NSMenuItem *item in [outDevMenu itemArray])
        [item setState:NSOffState];
    
    // set this one
    [outDeviceChanItem setState:NSOnState];
}

- (IBAction)routingChanged2ch:(NSMenuItem *)outDeviceChanItem
{
    if (_crntDeviceIndex >= 0) {
        // need to fix this, device selection process
        NSInteger idx = [_rootMenu indexOfItem:outDeviceChanItem.parentItem.parentItem];
        SFAudioDevice *device = _allDevices[idx];
        routingChanged(outDeviceChanItem, device.thruEngine);
        // write to prefs
        [self writeDevicePrefs:device];
    }
}

- (IBAction)routingChanged16ch:(NSMenuItem *)outDevChanItem
{
	routingChanged(outDevChanItem, _16chDevice.thruEngine);
	// write to prefs
	[self writeDevicePrefs:_16chDevice];
}

//

- (IBAction)volChanged2ch
{
    AudioDeviceID outDevID = _2chDevice.thruEngine->GetOutputDevice();
    if (outDevID == kAudioDeviceUnknown){
        return ;
    }
    
    AudioDevice device(outDevID, false);
    VolumeView *view = (VolumeView *)[_volumeViewController view];
    [view setScalar:device.GetVolumeScalar()];
    [view setDB:device.GetVolumeDB()];
}

- (IBAction)setVolume2ch:(NSSlider *)sender
{
    NSLog(@"vol changed to %f", [sender floatValue]);
    //
    
    AudioDeviceID outDevID = _2chDevice.thruEngine->GetOutputDevice();
    if (outDevID == kAudioDeviceUnknown){
        return ;
    }
    
    AudioDevice device(outDevID,false);
    
    device.SetVolumeScalar([sender floatValue]);
    VolumeView *view = (VolumeView *)[sender superview];
    [view setDB:device.GetVolumeDB()];
}

//
- (void)selectedSFAudioDevice_menu:(NSMenuItem *)SFAudioDeviceItem {
    [self selectSFAudioDevice:(int)SFAudioDeviceItem.tag];
}

- (void)selectSFAudioDevice:(int)idx {
    SFAudioDevice *device;
    BOOL is_newDevice = _crntDeviceIndex != idx;
    if (_crntDeviceIndex >= 0) {
        device = _allDevices[_crntDeviceIndex];
        [_rootMenu itemWithTag:_crntDeviceIndex].state = NSOffState;
        [_rootMenu itemWithTag:device.selectedDeviceTag].state = NSOffState;
        _crntDeviceIndex = -1;
    }
    
    // new device
    if (is_newDevice) {
        _crntDeviceIndex = idx;
        device = _allDevices[idx];
        [_rootMenu itemWithTag:_crntDeviceIndex].state = NSOnState;
        [self audioDevice:device selectOutputDevice:device.selectedDeviceTag];
    }
    [self buildRoutingMenu:device menuAction:@selector(routingChanged2ch:)];
}

- (void)audioDevice:(SFAudioDevice *)audioDevice selectOutputDevice:(NSInteger)tag {
    
    //[self updateThruLatency];
    BOOL selected = tag > NONE_DEVICE_TAG;
    
    if (audioDevice) {
        int index = (int)tag - NONE_DEVICE_TAG - 1;
        AudioDeviceID deviceID = selected ? audioDeviceIDs[index].mID : kAudioDeviceUnknown;
        audioDevice.thruEngine->SetOutputDevice(deviceID);
        [_rootMenu itemWithTag:audioDevice.selectedDeviceTag].state = NSOffState;
        [_rootMenu itemWithTag:tag].state = NSOnState;
        audioDevice.selectedDeviceTag = (int)tag;
        
        // get the channel routing from the prefs
        [self readDevicePrefs:audioDevice];
        
        // now set the menu
        [self buildRoutingMenu:audioDevice menuAction:@selector(routingChanged2ch:)];
        
        //
        VolumeView *volumeView = (VolumeView *)[_volumeViewController view];
        if (selected){
            AudioDevice outDevice(deviceID, false);
            if (outDevice.IsVolumeAvailableForMaster() ||
                outDevice.IsVolumeAvailableForChannels()) {
                [volumeView setEnabled:true];
                [volumeView setScalar:outDevice.GetVolumeScalar()];
                [volumeView setDB:outDevice.GetVolumeDB()];
            }
        } else {
            [volumeView setEnabled:false];
        }
        
    }
}

- (IBAction)selectOutputDevice:(NSMenuItem *)sender
{
    if (_crntDeviceIndex >= 0) {
        SFAudioDevice *device = _allDevices[_crntDeviceIndex];
        [self audioDevice:device selectOutputDevice:sender.tag];
    }
}

- (void)readGlobalPrefs
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    NSInteger idx = [prefs integerForKey:@"Current Device Index"];
    // if device was selected
    if (idx > -1) {
        SFAudioDevice *device = _allDevices[idx];
        
        NSString *key = [NSString stringWithFormat:@"%dch Output Device", device.numOfchannels];
        NSInteger tag = [prefs integerForKey:key];
        device.selectedDeviceTag = (int)tag;
        
        // set this would cause disable; _crntDeviceIndex = num;
        [self selectSFAudioDevice:(int)idx];
    }
    
    int tag;
    tag = (int)[prefs integerForKey:@"2ch Buffer Size"];
    _2chDevice.selectedBufferSize = tag;
    [self bufferSizeChanged:[_2chDevice.bufferMenu itemWithTag:tag]];
	
    tag = (int)[prefs integerForKey:@"16ch Buffer Size"];
    _16chDevice.selectedBufferSize = tag;
    [self bufferSizeChanged:[_16chDevice.bufferMenu itemWithTag:tag]];
}
		
- (void)writeGlobalPrefs
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];

    [prefs setObject:@(_crntDeviceIndex) forKey:@"Current Device Index"];
    [prefs setObject:@(_2chDevice.selectedDeviceTag) forKey:@"2ch Output Device"];
    [prefs setObject:@(_16chDevice.selectedDeviceTag) forKey:@"16ch Output Device"];
    
    UInt32 val = _2chDevice.selectedBufferSize;
    [prefs setObject:[NSNumber numberWithInt:val] forKey:@"2ch Buffer Size"];
    
    val = _16chDevice.selectedBufferSize;
    [prefs setObject:[NSNumber numberWithInt:val]  forKey:@"16ch Buffer Size"];

    [prefs synchronize];
}

- (CFStringRef)formDevicePrefName:(SFAudioDevice *)device
{
    int tag = device.selectedDeviceTag;
    NSString *routingTag = [NSString stringWithFormat:@"outputDevice %d [%dch Routing]",
                            tag, device.numOfchannels];;
    return CFStringCreateWithCString(kCFAllocatorSystemDefault, [routingTag UTF8String], kCFStringEncodingMacRoman);
}

- (void)readDevicePrefs:(SFAudioDevice *)device
{
    AudioThruEngine *thruEng = device.thruEngine;
    int numChans = device.numOfchannels;
    
	CFStringRef arrayName = [self formDevicePrefName:device];
	CFArrayRef mapArray = (CFArrayRef) CFPreferencesCopyAppValue(arrayName, kCFPreferencesCurrentApplication);
	
	if (mapArray) {
		for (int i = 0; i < numChans; i++) {
			CFNumberRef num = (CFNumberRef)CFArrayGetValueAtIndex(mapArray, i);
			if (num) {
				UInt32 val;
				CFNumberGetValue(num, kCFNumberLongType, &val);	
				thruEng->SetChannelMap(i, val-1);
				//CFRelease(num);
			}
		}
		//CFRelease(mapArray);
	} else { // set to default
		for (int i = 0; i < numChans; i++) 
			thruEng->SetChannelMap(i, i);
	}
}

- (void)writeDevicePrefs:(SFAudioDevice *)device
{
    AudioThruEngine *thruEng = device.thruEngine;
    int numChans = device.numOfchannels;
    CFNumberRef map[64];
    
    CFStringRef arrayName = [self formDevicePrefName:device];
    
    for (int i = 0; i < numChans; i++)
    {
        UInt32 val = thruEng->GetChannelMap(i) + 1;
        map[i] = CFNumberCreate(kCFAllocatorSystemDefault, kCFNumberIntType, &val);
    }
    
    CFArrayRef mapArray = CFArrayCreate(kCFAllocatorSystemDefault, (const void**)&map, numChans, NULL);
    CFPreferencesSetAppValue(arrayName, mapArray, kCFPreferencesCurrentApplication);

    
    CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication);
}

-(void)doAudioSetup
{
	[[NSWorkspace sharedWorkspace] launchApplication:@"Audio MIDI Setup"];
}

-(void)doAbout
{
	// orderFrontStandardAboutPanel doesnt work for background apps
	[mAboutController doAbout];
}
- (void)doQuit
{
	[NSApp terminate:nil];
}


@end
