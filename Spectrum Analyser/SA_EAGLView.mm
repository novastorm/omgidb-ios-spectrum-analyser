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

/******************************************************************************/
@implementation SA_EAGLView
{
    EAGLContext* _context;
    
    // OpenGl Render and Frame Buffers
    GLuint _viewRenderBuffer, _viewFrameBuffer;
    
    // OpenGL depth buffer
    GLuint _depthRenderBuffer;
    
    
    NSTimer* animationTimer;
    NSTimeInterval animationTimeInterval;
    NSTimeInterval animationStarted;
    
    
    AudioController* audioController;
    Float32* _FFTData;
    GLfloat* _oscilloscopeLine;
}

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
    DLog();
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.frame = [[UIScreen mainScreen] bounds];
        [self setupLayer];
        [self setupContext];
        [self setupRenderBuffer];
        [self setupFrameBuffer];
//        [self render];
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
     CAEAGLLayer* eaglLayer = (CAEAGLLayer*) self.layer;
    
    eaglLayer.opaque = YES;
    eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
        FALSE, kEAGLDrawablePropertyRetainedBacking
        , kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat
    	, nil];
}

/******************************************************************************/
- (void) setupContext
{
    DLog();
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    _context = [[EAGLContext alloc] initWithAPI:api];
    
    if (! _context) {
        DLog(@"Failed to initialize OpenGLES 2.0 context");
        exit(1);
    }
    
    if (! [EAGLContext setCurrentContext:_context]) {
        DLog(@"Failed to set current OpenGL context");
        exit(1);
    }
}

/******************************************************************************/
- (void) setupRenderBuffer
{
    DLog();
    glGenRenderbuffers(1, &_viewRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _viewRenderBuffer);
    [_context
     renderbufferStorage:GL_RENDERBUFFER
     fromDrawable:(CAEAGLLayer*) self.layer];
}

/******************************************************************************/
- (void) setupFrameBuffer
{
    DLog();
//    GLuint frameBuffer;
    glGenFramebuffers(1, &_viewFrameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _viewFrameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _viewRenderBuffer);
}

/******************************************************************************/
- (void) render
{
    DLog();
    glClearColor(0, (104.0/255.0), (55.0/255.0), 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    [_context presentRenderbuffer:GL_RENDERBUFFER];

//    audioController = [[SA_AudioController alloc] init];
////    _FFTData = (Float32 *)calloc(<#size_t#>, <#size_t#>);
//    _oscilloscopeLine = (GLfloat*)malloc(kDefaultDrawSamples * 2 * sizeof(GLfloat));
    
}

/******************************************************************************/

- (void) startAnimation
{
    
}

- (void) stopAnimation
{
    
}

@end
