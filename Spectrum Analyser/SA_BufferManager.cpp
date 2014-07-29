//
//  SA_BufferManager.cpp
//  Spectrum Analyser
//
//  Created by Adland Lee on 7/25/14.
//  Copyright (c) 2014 Adland Lee. All rights reserved.
//

/*
 
 File: BufferManager.cpp
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

#include "SA_BufferManager.h"

#define min(x,y) (x < y) ? x : y

BufferManager::BufferManager (UInt32 inMaxFramesPerSlice) :
    _displayMode(kDisplayModeOscilloscopeWaveForm)
    , _drawBuffers()
    , _drawBufferIndex(0)
    , _currentDrawBufferLength(kDefaultDrawSamples)
    , _FFTInputBuffer(NULL)
    , _FFTInputBufferFrameIndex(0)
    , _FFTInputBufferLength(inMaxFramesPerSlice)
    , _hasNewFFTData(0)
    , _needsNewFFTData(0)
    , _FFTHelper(NULL)
{
    for (UInt32 i = 0; i < kNumDrawBuffers; ++i) {
        _drawBuffers[i] = (Float32*)calloc(inMaxFramesPerSlice, sizeof(Float32));
    }
    
    _FFTInputBuffer = (Float32*)calloc(inMaxFramesPerSlice, sizeof(Float32));
    _FFTHelper = new FFTHelper(inMaxFramesPerSlice);
    OSAtomicIncrement32Barrier(&_needsNewFFTData);
}

BufferManager::~BufferManager()
{
    for (UInt32 i = 0; i < kDefaultDrawSamples; ++i) {
        free(_drawBuffers[i]);
        _drawBuffers[i] = NULL;
    }
    
    free(_FFTInputBuffer);
    delete _FFTHelper; _FFTHelper = NULL;
}

void BufferManager::CycleDramBuffers()
{
    for (int drawBuffer_i = (kNumDrawBuffers - 2); drawBuffer_i >= 0; drawBuffer_i--) {
        memmove(_drawBuffers[drawBuffer_i + 1], _drawBuffers[drawBuffer_i], _currentDrawBufferLength);
    }
}

void BufferManager::CopyAduioDataToFFTInputBuffer(Float32 *inData, UInt32 numberOfFrames)
{
    UInt32 framesToCopy = min(numberOfFrames, _FFTInputBufferLength - _FFTInputBufferFrameIndex);
    memcpy(_FFTInputBuffer + _FFTInputBufferFrameIndex, inData, framesToCopy * sizeof(Float32));
    _FFTInputBufferFrameIndex += framesToCopy * sizeof(Float32);
    if (_FFTInputBufferFrameIndex >= _FFTInputBufferLength) {
        OSAtomicIncrement32(&_hasNewFFTData);
        OSAtomicDecrement32(&_needsNewFFTData);
    }
}

void BufferManager::GetFFTOutput(Float32 *outFFTData)
{
    _FFTHelper->ComputeFFT(_FFTInputBuffer, outFFTData);
    _FFTInputBufferFrameIndex = 0;
    OSAtomicDecrement32Barrier(&_hasNewFFTData);
    OSAtomicDecrement32Barrier(&_needsNewFFTData);
}