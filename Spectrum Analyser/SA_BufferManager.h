//
//  SA_BufferManager.h
//  Spectrum Analyser
//
//  Created by Adland Lee on 7/25/14.
//  Copyright (c) 2014 Adland Lee. All rights reserved.
//

#ifndef __Spectrum_Analyser__SA_BufferManager__
#define __Spectrum_Analyser__SA_BufferManager__

#include <AudioToolbox/AudioToolbox.h>
#include <libkern/OSAtomic.h>

#include "SA_FFTHelper.h"

const UInt32 kNumDrawBuffers = 12;
const UInt32 kDefaultDrawSamples = 1024;

class BufferManager
{
private:
    UInt32 _DisplayMode;
    
    Float32* _drawBuffers[kNumDrawBuffers];
    UInt32 _drawBuffersIndex;
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
    
    void SetDisplayMode (UInt32 inDisplayMode) { _DisplayMode = inDisplayMode; }
    UInt32 GetDisplayMode () { return _DisplayMode; }

    Float32** GetDrawBuffers () { return _drawBuffers; }
    void CopyAudioDataToDrawBuffer (Float32* inData, UInt32 numberOfFrames);
    void CycleDramBuffers ();

    void SetCurrentDrawBufferLength (UInt32 inDrawBufferLength) { _currentDrawBufferLength = inDrawBufferLength; }
    UInt32 GetCurrentDrawBufferLength () { return _currentDrawBufferLength; }
    
    bool HasNewFFTData () { return static_cast<bool>(_hasNewFFTData); }
    bool NeedsNewFFTData () { return static_cast<bool>(_needsNewFFTData); }
    
    void CopyAduioDataToFFTInputBuffer (Float32* inData, UInt32 numberOfFrames);
    UInt32 GetFFTOutputBufferLength () { return _FFTInputBufferLength / 2; }
    void GetFFTOutput (Float32* outFFTData);
};

#endif /* defined(__Spectrum_Analyser__SA_BufferManager__) */
