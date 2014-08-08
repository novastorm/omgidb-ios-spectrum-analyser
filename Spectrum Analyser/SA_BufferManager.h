//
//  SA_BufferManager.h
//  Spectrum Analyser
//
//  Created by Adland Lee on 7/25/14.
//  Copyright (c) 2014 Adland Lee. All rights reserved.
//

/*
 
 File: BufferManager.h
 Abstract: This class handles buffering of audio data that is shared between the view and audio controller
 Version: 2.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 
 
 */

#ifndef __Spectrum_Analyser__SA_BufferManager__
#define __Spectrum_Analyser__SA_BufferManager__

#include <AudioToolbox/AudioToolbox.h>
#include <libkern/OSAtomic.h>

#include "SA_FFTHelper.h"

const UInt32 kNumDrawBuffers = 12;
const UInt32 kDefaultDrawSamples = 512;

const UInt32 kDisplayModeOscilloscopeWaveForm = 0;

class BufferManager
{
private:
    UInt32 _displayMode;
    
    Float32* _drawBuffers[kNumDrawBuffers];
    UInt32 _drawBufferIndex;
    UInt32 _currentDrawBufferLength;
    
    Float32* _FFTInputBuffer;
    UInt32 _FFTInputBufferFrameIndex;
    UInt32 _FFTInputBufferLength;
    volatile int32_t _hasNewFFTData;
    volatile int32_t _needsNewFFTData;
    
    FFTHelper*  _FFTHelper;

public:
    BufferManager (UInt32 inMaxFramesPerSlice);
    ~BufferManager ();
    
    void SetDisplayMode (UInt32 inDisplayMode);
    UInt32 GetDisplayMode ();

    Float32** GetDrawBuffers ();
    void CopyAudioDataToDrawBuffer (Float32* inData, UInt32 numberOfFrames);
    void CycleDrawBuffers ();

    void SetCurrentDrawBufferLength (UInt32 inDrawBufferLength);
    UInt32 GetCurrentDrawBufferLength ();
    
    bool HasNewFFTData ();
    bool NeedsNewFFTData ();
    
    void CopyAudioDataToFFTInputBuffer (Float32* inData, UInt32 numberOfFrames);
    UInt32 GetFFTOutputBufferLength ();
    void GetFFTOutput (Float32* outFFTData);
};

#endif /* defined(__Spectrum_Analyser__SA_BufferManager__) */
