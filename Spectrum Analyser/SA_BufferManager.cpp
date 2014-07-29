//
//  SA_BufferManager.cpp
//  Spectrum Analyser
//
//  Created by Adland Lee on 7/25/14.
//  Copyright (c) 2014 Adland Lee. All rights reserved.
//

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