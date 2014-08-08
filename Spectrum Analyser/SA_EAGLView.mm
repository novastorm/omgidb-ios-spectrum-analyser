//
//  SA_EAGLView.m
//  Spectrum Analyser
//
//  Created by Adland Lee on 7/25/14.
//  Copyright (c) 2014 Adland Lee. All rights reserved.
//

#import "SA_EAGLView.h"

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>

#import "SA_BufferManager.h"

#define USE_DEPTH_BUFFER YES

#ifndef CLAMP
#define CLAMP(min, x, max) (x < min ? min : (x > max ? max : x))
#endif

const GLfloat _Spectrum_bar_width = 4;
const GLsizei _NumberOfFrameBuffers = 1;

// value, alpha, red, green, blue
const GLfloat _ColorLevels[] = {
      0.000, 1.0, 0.0, 0.0, 0.0
    , 0.333, 1.0, 0.7, 0.0, 0.0
    , 0.667, 1.0, 0.0, 0.0, 1.0
    , 1.000, 1.0, 0.0, 1.0, 1.0
};

enum {
    kMinDrawSamples = 64
    , kMaxDrawSamples = 4096
};

typedef struct SpectrumLinkedTexture {
    GLuint textureName;
    struct SpectrumLinkedTexture* nextTexture;
} SpectrumLinkedTexture;

//typedef enum SA_DisplayMode {
//    SA_DisplayModeOscilloscopeWaveform
//    , SA_DisplayModeOscilloscopeFFT
//} SA_DisplayMode;


/******************************************************************************/
@interface EAGLView ()
{
    // Render buffer dimensions
    GLuint _renderBufferWidth;
    GLuint _renderBufferHeight;
    
    EAGLContext* _context;
    
    // OpenGl Render and Frame Buffers
    GLuint _viewRenderBuffer, _viewFrameBuffer;
    
    // OpenGL depth buffer
    GLuint _depthRenderBuffer;
    
    NSTimer* _animationTimer;
    NSTimeInterval _animationInterval;
    NSTimeInterval _animationStarted;
    
    UIImageView* sampleSizeOverlay;
    
    BOOL initted_oscilloscope;
    UInt32* _textureBitBuffer;
    
    SA_DisplayMode _displayMode;
    
    UIEvent* _pinchEvent;
    CGFloat _lastPinchDist;
    
    AudioController* _audioController;
    Float32* _FFTData;
    GLfloat* _oscilloscopeLine;
}

@end

/******************************************************************************/
@implementation EAGLView

@synthesize applicationResignActive = _applicationResignActive;

/******************************************************************************
 set default layer to CAEAGLLayer class **required**
 ******************************************************************************/
+ (Class) layerClass
{
    return [CAEAGLLayer class];
}

/******************************************************************************
 called when xib is unarchived using interface builder
 ******************************************************************************/
- (id)initWithCoder:(NSCoder*)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.frame = [[UIScreen mainScreen] bounds];
        [self setupLayer];
        if(![self setupContext] || ![self setupFrameBuffer]) return nil;
        
        _audioController = [[AudioController alloc] init];
        _FFTData = (Float32*)calloc([_audioController getBufferManagerInstance]->GetFFTOutputBufferLength(), sizeof(Float32));
        
        _oscilloscopeLine = (GLfloat*)malloc(kDefaultDrawSamples * 2 * sizeof(GLfloat));
        
        _animationInterval = 1.0 / 60.0;
        
//        [self setupView];
//        [self drawView];
        
        _displayMode = SA_DisplayModeOscilloscopeWaveform;
        
        // setup overlay view for oscilloscope pinch/zoom
//        UIImage* img_ui = nil;
//        {
//            // draw bg path rounded rectangle
//            CGPathRef bgPath = CreateRoundedRectPath(CGRectMake(0, 0, 110,234), 15.0);
//        }

        [self render];
    }
    return self;
}

/******************************************************************************/
- (void) dealloc
{
    free(_oscilloscopeLine);
}

/******************************************************************************/
- (void) setupLayer
{
     CAEAGLLayer* eaglLayer = (CAEAGLLayer*)self.layer;
    
    eaglLayer.opaque = YES;
    eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
        FALSE, kEAGLDrawablePropertyRetainedBacking
        , kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat
    	, nil];
}

/******************************************************************************/
- (BOOL) setupContext
{
    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (! _context) {
        ALog(@"Failed to initialize OpenGLES 2.0 context");
        return NO;
    }
    
    if (! [EAGLContext setCurrentContext:_context]) {
        ALog(@"Failed to set current OpenGL context");
        return NO;
    }

    return YES;
}

/******************************************************************************/
- (BOOL) setupRenderBuffer
{
    glGenRenderbuffers(_NumberOfFrameBuffers, &_viewRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _viewRenderBuffer);
    [_context
     renderbufferStorage:GL_RENDERBUFFER
     fromDrawable:(CAEAGLLayer*)self.layer];
    
    return YES;
}

/******************************************************************************/
- (BOOL) setupFrameBuffer
{
    [self setupRenderBuffer];
    glGenFramebuffers(_NumberOfFrameBuffers, &_viewFrameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _viewFrameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _viewRenderBuffer);
    
    return YES;
}

/******************************************************************************/
- (void) render
{
    glClearColor(0.0, 104.0/255, 55.0/255, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}

/******************************************************************************/
- (void) setupView
{
    // setup OpenGL ES matrices and transforms
    glViewport(0, 0, _renderBufferWidth, _renderBufferHeight);
}

/******************************************************************************/
- (void) startAnimation
{
    
}

/******************************************************************************/
- (void) stopAnimation
{
    
}

@end
