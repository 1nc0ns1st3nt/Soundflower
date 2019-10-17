//
//  VolumeViewController.h
//  Soundflowerbed
//
//  Created by koji on 2013/06/01.
//
//

#import <Cocoa/Cocoa.h>
#import "VolumeView.h"

@interface VolumeViewController : NSViewController
@property (strong) VolumeView *view;
- (void)setVolumeSliderTarget:(id)target action:(SEL)selector;
@end
