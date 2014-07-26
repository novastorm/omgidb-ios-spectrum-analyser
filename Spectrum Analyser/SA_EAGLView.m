//
//  SA_EAGLView.m
//  Spectrum Analyser
//
//  Created by Adland Lee on 7/25/14.
//  Copyright (c) 2014 Adland Lee. All rights reserved.
//

#import "SA_EAGLView.h"

/******************************************************************************/
@implementation SA_EAGLView
{
    CAEAGLLayer* _eaglLayer;
    EAGLContext* _context;
    GLuint _colorRenderBuffer;
}

/******************************************************************************
 set default layer to CAEAGLLayer class **required**
 ******************************************************************************/
+ (Class) layerClass
{
    return [CAEAGLLayer class];
}

/******************************************************************************
 called when xib is unarchived
 ******************************************************************************/
- (id)initWithCoder:(NSCoder *)aDecoder
{
    DLog(@"HELLO");
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.frame = [[UIScreen mainScreen] bounds];
        [self setupLayer];
        [self setupContext];
        [self setupRenderBuffer];
        [self setupFrameBuffer];
        [self render];
    }
    return self;
}

/******************************************************************************
 ******************************************************************************/
- (void) setupLayer
{
    _eaglLayer = (CAEAGLLayer *) self.layer;
    
    _eaglLayer.opaque = YES;
}

/******************************************************************************
 ******************************************************************************/
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

/******************************************************************************
 ******************************************************************************/
- (void) setupRenderBuffer
{
    DLog();
    glGenRenderbuffers(1, &_colorRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
}

/******************************************************************************
 ******************************************************************************/
- (void) setupFrameBuffer
{
    DLog();
    GLuint frameBuffer;
    glGenFramebuffers(1, &frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);
}

/******************************************************************************
 ******************************************************************************/
- (void) render
{
    DLog();
    glClearColor(0, (104.0/255.0), (55.0/255.0), 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}

/******************************************************************************
 ******************************************************************************/

- (void) startAnimation
{
    
}

- (void) stopAnimation
{
    
}

@end
