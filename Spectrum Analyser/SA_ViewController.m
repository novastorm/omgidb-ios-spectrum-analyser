//
//  SA_ViewController.m
//  Spectrum Analyser
//
//  Created by Adland Lee on 7/24/14.
//  Copyright (c) 2014 Adland Lee. All rights reserved.
//

#import "SA_ViewController.h"

#import "AGLKVertexAttribArrayBuffer.h"
#import "AGLKContext.h"

@implementation SA_ViewController

typedef struct {
    GLKVector3 positionCoords;
}
SceneVertex;

static const SceneVertex vertices[] =
{
      {{-0.5f, -0.5f, 0.0 }}
    , {{ 0.5f, -0.5f, 0.0 }}
    , {{-0.5f,  0.5f, 0.0 }}
    , {{ 0.5f,  0.5f, 0.0 }}
};

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // verify view is a GLKView
    GLKView *view = (GLKView*) self.view;
    NSAssert([view isKindOfClass:[GLKView class]]
    	, @"View controller is not a GLKView");
    
    // create OpenGL ES 2.0 context
    view.context = [[AGLKContext alloc]
    	initWithAPI:kEAGLRenderingAPIOpenGLES2];

    // make new context current
    [AGLKContext setCurrentContext:view.context];
    
    // set base effect and setup
    self.baseEffect = [[GLKBaseEffect alloc] init];
    self.baseEffect.useConstantColor = GL_TRUE;
    self.baseEffect.constantColor = GLKVector4Make(
    	1.0f   // red
        , 1.0f // green
        , 1.0f // blue
        , 1.0f // alpha
    );
    
    // set view context background color
    ((AGLKContext*)view.context).clearColor = GLKVector4Make(
        0.0f   // red
        , 0.0f // green
        , 0.0f // blue
        , 1.0f // alpha
        );

    // create vertex buffer
    self.vertexBuffer = [[AGLKVertexAttribArrayBuffer alloc]
    	initWithAttribStride:sizeof(SceneVertex)
        numberOfVertices:sizeof(vertices) / sizeof(SceneVertex)
        bytes:vertices
        usage:GL_STATIC_DRAW
    ];
}

/******************************************************************************
 GLKView delegate method called by view controller's view when asked to draw
 itself
 ******************************************************************************/
- (void) glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    [self.baseEffect prepareToDraw];
    
    // clear back frame buffer
    [(AGLKContext*)view.context clear:GL_COLOR_BUFFER_BIT];
    
    [self.vertexBuffer
    	prepareToDrawWithAttrib:GLKVertexAttribPosition
        numberOfCoordinates:3
        attribOffset:offsetof(SceneVertex, positionCoords)
        shouldEnable:YES
    ];
    
    // draw triangles
    [self.vertexBuffer
    	drawArrayWithMode:GL_LINE_STRIP
        startVertexIndex:0
        numberOfVertices:sizeof(vertices) / sizeof(SceneVertex)
    ];
}

@end
