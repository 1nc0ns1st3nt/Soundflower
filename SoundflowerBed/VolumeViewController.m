//
//  VolumeViewController.m
//  Soundflowerbed
//
//  Created by koji on 2013/06/01.
//
//

#import "VolumeViewController.h"


@implementation VolumeViewController

@dynamic view;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)setVolumeSliderTarget:(id)target action:(SEL)selector {
    VolumeView *aView = (VolumeView *)self.view;
    NSSlider *slider = [aView slider];
    slider.target = target;
    slider.action = selector;
}

@end
