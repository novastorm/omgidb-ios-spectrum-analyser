//
//  SA_AudioController.h
//  Spectrum Analyser
//
//  Created by Adland Lee on 7/25/14.
//  Copyright (c) 2014 Adland Lee. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

#import "SA_BufferManager.h"
#import "SA_DCRejectionFilter.h"

@interface AudioController : NSObject

@property (nonatomic) BOOL muteAudio;
@property (nonatomic, readonly) BOOL audioChainIsBeingReconstructed;

- (BufferManager*) getBufferManagerInstance;
- (OSStatus) startIOUnit;
- (OSStatus) stopIOUnit;
- (void) playButtonPressedSound;
- (double) sessionSampleRate;

@end
