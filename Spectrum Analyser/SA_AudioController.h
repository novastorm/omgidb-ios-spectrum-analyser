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

@interface SA_AudioController : NSObject
{
    AudioUnit _rioUnit;
    BufferManager* _bufferManager;
    DCRejectionFilter* _DCRejectionFilter;
    AVAudioPlayer* _audioPlayer;
}

@property (nonatomic, assign) BOOL muteAudio;
@property (nonatomic, assign, readonly) BOOL audioChainIsBeingReconstructed;

- (BufferManager*) getBufferManagerInstance;
- (OSStatus) startIOUnit;
- (OSStatus) stopIOUnit;
- (void) playButtonPressedSound;
- (double) sessionSampleRate;

@end
