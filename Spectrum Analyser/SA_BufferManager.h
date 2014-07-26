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

const UInt32 kNumDrawBuffers = 12;
const UInt32 kDefaultDrawSamples = 1024;

#endif /* defined(__Spectrum_Analyser__SA_BufferManager__) */
