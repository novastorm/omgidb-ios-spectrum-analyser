//
//  SA_AudioController.m
//  Spectrum Analyser
//
//  Created by Adland Lee on 7/25/14.
//  Copyright (c) 2014 Adland Lee. All rights reserved.
//

#import "SA_AudioController.h"

#import "CAXException.h"
#import "CAStreamBasicDescription.h"

struct CallbackData
{
    AudioUnit rioUnit;
    BufferManager* bufferManager;
    DCRejectionFilter* dcRejectionFilter;
    BOOL* muteAudio;
    BOOL* audioChainIsBeingReconstructed;
    
    CallbackData():
        rioUnit(NULL)
        , bufferManager(NULL)
        , muteAudio(NULL)
        , audioChainIsBeingReconstructed(NULL)
    { /* Empty */ }
} cd;

// render function
static OSStatus performRender (
	void* inRefCon
	, AudioUnitRenderActionFlags* ioActionFlags
    , const AudioTimeStamp* inTimeStamp
    , UInt32 inBusNumber
    , UInt32 inNumberFrames
    , AudioBufferList* ioData)
{
    OSStatus err = noErr;
    if (*(cd.audioChainIsBeingReconstructed) == NO) {
        // Capture audio data from microphone and store in ioData
        err = AudioUnitRender(cd.rioUnit, ioActionFlags, inTimeStamp, 1, inNumberFrames, ioData);
        
        // Filter average offset (DC component)
        cd.dcRejectionFilter->ProcessInplace((Float32*)ioData->mBuffers[0].mData, inNumberFrames);

        switch (cd.bufferManager->GetDisplayMode()) {
            case SA_DisplayModeOscilloscopeWaveform :
                cd.bufferManager->CopyAudioDataToDrawBuffer((Float32*)ioData->mBuffers[0].mData, inNumberFrames);
                break;
            
            case SA_DisplayModeOscilloscopeFFT :
                if (cd.bufferManager->NeedsNewFFTData()) {
                    cd.bufferManager->CopyAudioDataToFFTInputBuffer((Float32*)ioData->mBuffers[0].mData, inNumberFrames);
                }
                break;
                
            default:
                DLog(@"Invalid displayMode");
                exit(0);
                break;
        }
    }

    // mute audio
    if (cd.muteAudio) {
        for (UInt32 i = 0; i < ioData->mNumberBuffers; ++i) {
            memset(ioData->mBuffers[i].mData, 0, ioData->mBuffers[i].mDataByteSize);
        }
    }
    
    return err;
}

@interface AudioController () {
    AudioUnit _rioUnit;
    BufferManager* _bufferManager;
    DCRejectionFilter* _DCRejectionFilter;
    AVAudioPlayer* _audioPlayer;
}

- (void) setupAudioSession;
- (void) setupIOUnit;
- (void) createButtonPressedSound;
- (void) setupAudioChain;

@end

@implementation AudioController

@synthesize muteAudio = _muteAudio;
@synthesize audioChainIsBeingReconstructed = _audioChainIsBeingReconstructed;

/******************************************************************************/
- (id) init
{
    if (self = [super init]) {
        _bufferManager = NULL;
        _DCRejectionFilter = NULL;
        _muteAudio = YES;
        [self setupAudioChain];
    }
    
    return self;
}

/******************************************************************************/
- (void) handleInterruption:(NSNotification*)notification
{
    try {
        UInt8 theInterruptionType = [[notification.userInfo valueForKey:AVAudioSessionInterruptionTypeKey] intValue];
        NSLog(@"Session interrupted > --- %@ --- \n", theInterruptionType == AVAudioSessionInterruptionTypeBegan ? @"Begin Interruption" : @"End Interruption");
        
        if (theInterruptionType == AVAudioSessionInterruptionTypeBegan) {
            [self stopIOUnit];
        }
        if (theInterruptionType == AVAudioSessionInterruptionTypeEnded) {
            // activate audio session
            NSError* error = nil;
            [[AVAudioSession sharedInstance] setActive:YES error:&error];
            if (nil != error) NSLog(@"AVAudioSession set active failed with: %@", error);
            [self startIOUnit];
        }
    } catch (CAXException e) {
        char buf[256];
        fprintf(stderr, "Error: %s (%s)\n", e.mOperation, e.FormatError(buf, 256));
    }
}

/******************************************************************************/
- (void) handleRouteChange:(NSNotification*)notification
{
    UInt8 reasonValue = [[notification.userInfo valueForKey:AVAudioSessionRouteChangeReasonKey] intValue];
    AVAudioSessionRouteDescription *routeDescription = [notification.userInfo valueForKey:AVAudioSessionRouteChangePreviousRouteKey];
    
    NSLog(@"Route Change");
    switch (reasonValue) {
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable :
            NSLog(@"     NewDeviceAvailable");
            break;
        
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable :
            NSLog(@"     OldDeviceUnavailable");
            break;
            
        case AVAudioSessionRouteChangeReasonCategoryChange :
            NSLog(@"     CategoryChange");
            NSLog(@" New Category: %@", [[AVAudioSession sharedInstance] category]);
            break;

        case AVAudioSessionRouteChangeReasonOverride :
            NSLog(@"     Override");
            break;
            
        case AVAudioSessionRouteChangeReasonWakeFromSleep :
            NSLog(@"     WakeFromSleep");
            break;
            
        case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory :
            NSLog(@"     NoSuitableRouteForCategory");
            break;
            
        default:
            NSLog(@"     ReasonUnknown");
    }
    
    NSLog(@"Previous route:\n");
    NSLog(@"%@", routeDescription);
}

/******************************************************************************/
- (void) handleMediaServerReset:(NSNotification*)notification
{
    NSLog(@"Media server has reset");
    _audioChainIsBeingReconstructed = YES;
    
    // wait for objects to settle
    usleep(25000);
    
    // rebuild audio chain
    delete _bufferManager; _bufferManager = NULL;
    delete _DCRejectionFilter; _DCRejectionFilter = NULL;
    _audioPlayer = nil;
    
    [self setupAudioChain];
    [self startIOUnit];
    
    _audioChainIsBeingReconstructed = NO;
}

/******************************************************************************/
- (void) setupAudioSession
{
    try {
        // Configure audio session
        AVAudioSession *sessionInstance = [AVAudioSession sharedInstance];
        
        // Set play and record category
        NSError *error = nil;
        [sessionInstance setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
        XThrowIfError((OSStatus)error.code, "could not set audio session category");
        
        // set buffer duration to 5ms
        NSTimeInterval bufferDuration = 0.005;
        [sessionInstance setPreferredIOBufferDuration:bufferDuration error:&error];
        XThrowIfError((OSStatus)error.code, "could not set session I/O buffer duration");
        
        // set session sample rate
        [sessionInstance setPreferredSampleRate:44100 error:&error];
        XThrowIfError((OSStatus)error.code, "could not set session preferred sample rate");
        
        // attach interrupt handler
        [[NSNotificationCenter defaultCenter]
         	addObserver:self
            selector:@selector(handleInterruption:)
        	name:AVAudioSessionInterruptionNotification
            object:sessionInstance
        ];
        
        // attach route change handler
        [[NSNotificationCenter defaultCenter]
        	addObserver:self
            selector:@selector(handleRouteChange:)
            name:AVAudioSessionRouteChangeNotification
            object:sessionInstance
        ];
        
        // rebuild audio when media services are reset
        [[NSNotificationCenter defaultCenter]
        	addObserver:self
            selector:@selector(handleMediaServerReset:)
            name:AVAudioSessionMediaServicesWereResetNotification
            object:sessionInstance
        ];
        
        // activate audio session
        [[AVAudioSession sharedInstance] setActive:YES error:&error];
        XThrowIfError((OSStatus)error.code, "could not activate session");
    }
    catch (CAXException &e) {
        NSLog(@"Error returned from setupAudioSession: %d: %s", (int)e.mError, e.mOperation);
        
    }
    catch (...) {
        NSLog(@"Unknown error returned from setupAudioSession");
    }
}

/******************************************************************************/
- (void) setupIOUnit
{
    try {
        // create AURemoteIO instance
        AudioComponentDescription desc;
        desc.componentType = kAudioUnitType_Output;
        desc.componentSubType = kAudioUnitSubType_RemoteIO;
        desc.componentManufacturer = kAudioUnitManufacturer_Apple;
        desc.componentFlags = 0;
        desc.componentFlagsMask = 0;
        
        AudioComponent comp = AudioComponentFindNext(NULL, &desc);
        XThrowIfError(AudioComponentInstanceNew(comp, &_rioUnit)
        	, "could not create new AURemoteIO instance");
        
        // enable AURemoteIO input and output
        AudioUnitElement inputBus = 1;
        AudioUnitElement outputBus = 0;
        
        UInt32 inData = 1;
        XThrowIfError(AudioUnitSetProperty(_rioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, inputBus, &inData, sizeof(UInt32))
            , "could not enable AURemoteIO input");
        XThrowIfError(AudioUnitSetProperty(_rioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, outputBus, &inData, sizeof(UInt32))
        	, "could not enable AURemoteIO output");
        
        // explicitly set input and output client formats
        double inSampleRate = 44100;
        UInt32 inNumChannels = 1;
        bool inIsInterleaved = false;
        CAStreamBasicDescription ioFormat = CAStreamBasicDescription(inSampleRate, inNumChannels, CAStreamBasicDescription::kPCMFormatFloat32, inIsInterleaved);
        XThrowIfError(AudioUnitSetProperty(_rioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, inputBus, &ioFormat, sizeof(ioFormat))
        	, "could not set AURemoteIO input client format");
        XThrowIfError(AudioUnitSetProperty(_rioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, outputBus, &ioFormat, sizeof(ioFormat))
        	, "could not set AURemoteIO output client format");
        
        // set maximum number of frame samples produced by any single call to AudioUnitRender
        UInt32 maxFramesPerSlice = 4096;
        XThrowIfError(AudioUnitSetProperty(_rioUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, outputBus, &maxFramesPerSlice, sizeof(UInt32))
        	, "could not set AURemoteIO MaximumFramesPerSlice");
        
        // get AURemote property value for allocating buffers
        UInt32 propSize = sizeof(UInt32);
        XThrowIfError(AudioUnitGetProperty(_rioUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, outputBus, &maxFramesPerSlice, &propSize)
        	, "could not get AURemoteIO MaximumFramesPerSlice");
        
        _bufferManager = new BufferManager(maxFramesPerSlice);
        _DCRejectionFilter = new DCRejectionFilter;
        
        // setup callback data references
        cd.rioUnit = _rioUnit;
        cd.bufferManager = _bufferManager;
        cd.dcRejectionFilter = _DCRejectionFilter;
        cd.muteAudio = &_muteAudio;
        cd.audioChainIsBeingReconstructed = &_audioChainIsBeingReconstructed;
        
        // set AURemoteIO render callback
        AURenderCallbackStruct renderCallback;
        renderCallback.inputProc = performRender;
        renderCallback.inputProcRefCon = NULL;
        XThrowIfError(AudioUnitSetProperty(_rioUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, outputBus, &renderCallback, sizeof(renderCallback))
        	, "could not set AURemoteIO render callback");
        
        // initialize AURemoteIO instance
        XThrowIfError(AudioUnitInitialize(_rioUnit)
        	, "could not initialize AURemoteIO instance");
    }
    catch (CAXException &e) {
        NSLog(@"Error returned from setupIOUnit: %d: %s", (int)e.mError, e.mOperation);
    }
    catch (...) {
        NSLog(@"Unknown error returned from setupIOUnit");
    }
}

/******************************************************************************/
- (void) createButtonPressedSound
{
    
}

/******************************************************************************/
- (void) playButtonPressedSound
{
    
}

/******************************************************************************/
- (void) setupAudioChain
{
    [self setupAudioSession];
    [self setupIOUnit];
}

/******************************************************************************/
- (OSStatus) startIOUnit
{
    OSStatus err = AudioOutputUnitStart(_rioUnit);
    if (err) NSLog(@"could not start AURemoteIO: %d", (int)err);
    return err;
}

/******************************************************************************/
- (OSStatus) stopIOUnit
{
    OSStatus err = AudioOutputUnitStop(_rioUnit);
    if (err) NSLog(@"could not stop AURemoteIO: %d", (int)err);
    return err;
}

/******************************************************************************/
- (double) sessionSampleRate
{
    return [[AVAudioSession sharedInstance] sampleRate];
}

/******************************************************************************/
- (BufferManager*) getBufferManagerInstance
{
    return _bufferManager;
}

/******************************************************************************/
- (BOOL) audioChainIsBeingReconstructed
{
    return _audioChainIsBeingReconstructed;
}

/******************************************************************************/
- (void) dealloc
{
    delete _bufferManager; _bufferManager = NULL;
    delete _DCRejectionFilter; _DCRejectionFilter = NULL;
    _audioPlayer = nil;
}

@end
