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
#import "SA_AudioController.h"
#import "SA_BufferManager.h"

#define USE_DEPTH_BUFFER YES

#ifndef CLAMP
#define CLAMP(min, x, max) (x < min ? min : (x > max ? max : x))
#endif

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

typedef struct {
    GLKVector3 positionCoords;
}
SceneVertex;

/******************************************************************************/
@interface SA_ViewController () {
    NSTimer* _animationTimer;
    NSTimeInterval _animationTimeInterval;
    NSTimeInterval _animationStarted;
    
    BOOL _inittedOscilloscope;
    
    SA_DisplayMode _displayMode;
    
    AudioController* _audioController;
    Float32* _FFTData;
    GLfloat* _oscilloscopeLine;
    
    NSInteger _NumberOfDrawBuffers;
}

@property (weak, nonatomic) IBOutlet UILabel *drawBuffersLabel;
@property (weak, nonatomic) IBOutlet UIButton *waveFFTButton;

@end

/******************************************************************************/
@implementation SA_ViewController

//@synthesize applicationResignedActive = _applicationResignedActive;

const GLfloat _Spectrum_bar_width = 4;
const GLsizei _NumberOfFrameBuffers = 1;

// value, alpha, red, green, blue
const GLfloat _ColorLevels[] = {
    0.000, 1.0, 0.0, 0.0, 0.0
    , 0.333, 1.0, 0.7, 0.0, 0.0
    , 0.667, 1.0, 0.0, 0.0, 1.0
    , 1.000, 1.0, 0.0, 1.0, 1.0
};

static const SceneVertex vertices[] =
{
      {{-0.5f, -0.5f, 0.0 }}
    , {{ 0.5f, -0.5f, 0.0 }}
    , {{-0.5f,  0.5f, 0.0 }}
    , {{ 0.5f,  0.5f, 0.0 }}
};

/******************************************************************************/
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
    
    self.baseEffect.transform.modelviewMatrix =
        GLKMatrix4Multiply(
            GLKMatrix4MakeTranslation(-0.95f, -0.95f, 0.0f)
            , GLKMatrix4MakeScale(1.9f, 2.0f, 1.0f)
            );

    
    _audioController = [[AudioController alloc] init];

    // create vertex buffer
    _NumberOfDrawBuffers = 1;
    [self.drawBuffersLabel setText:[NSString stringWithFormat:@"%d", _NumberOfDrawBuffers]];
    
    BufferManager* bufferManager = [_audioController getBufferManagerInstance];
    
    _FFTData = (Float32*)calloc(bufferManager->GetFFTOutputBufferLength(), sizeof(Float32));
    _oscilloscopeLine = (GLfloat*)malloc(kDefaultDrawSamples * (2 + 4) * sizeof(GLfloat));
    _animationTimeInterval = 1.0 / 60.0;

    // set view context background color
    ((AGLKContext*)view.context).clearColor = GLKVector4Make(
        0.0f   // red
        , 0.0f // green
        , 0.0f // blue
        , 1.0f // alpha
        );


    self.vertexBuffer = [[AGLKVertexAttribArrayBuffer alloc]
    	initWithAttribStride:(2 + 4) * sizeof(GLfloat)
        numberOfVertices:bufferManager->GetCurrentDrawBufferLength()
        bytes:_oscilloscopeLine
        usage:GL_STATIC_DRAW
    ];

    _displayMode = SA_DisplayModeOscilloscopeWaveform;
    bufferManager->SetDisplayMode(_displayMode);

    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE);

    [_audioController startIOUnit];
}

/******************************************************************************/
- (void) update
{
//    DLog();
    [self drawView];
}

/******************************************************************************
 GLKView delegate method called by view controller's view when asked to draw
 itself
 ******************************************************************************/
- (void) glkView:(GLKView *)view drawInRect:(CGRect)rect
{
//    DLog();
    [(AGLKContext*)view.context clear:GL_COLOR_BUFFER_BIT];

    [self drawView];

    return;

//    GLfloat max = kDefaultDrawSamples;
//
//    [self.vertexBuffer
//     reinitWithAttribStride:2 * sizeof(GLfloat)
//     numberOfVertices:max
//     bytes:_oscilloscopeLine
//     ];
//    
//    [self.vertexBuffer
//     prepareToDrawWithAttrib:GLKVertexAttribPosition
//     numberOfCoordinates:2
//     attribOffset:0
//     shouldEnable:YES
//     ];
//    
//    [self.baseEffect prepareToDraw];
//    
//    [self.vertexBuffer
//     drawArrayWithMode:GL_LINE_STRIP
////     drawArrayWithMode:GL_POINTS // Crashes on device. Do not draw using GL_POINTS
//     startVertexIndex:0
//     numberOfVertices:max
//     ];
}

/******************************************************************************/
- (void) drawView
{
    GLKView *view = (GLKView*) self.view;
    
//    if (_applicationResignedActive) return;
    
    [AGLKContext setCurrentContext:view.context];
    [self.baseEffect prepareToDraw];
    [self drawView:self forTime:([NSDate timeIntervalSinceReferenceDate] - _animationStarted)];
}

/******************************************************************************/
- (void) drawView:(id)sender forTime:(NSTimeInterval)time
{
//    DLog();
    if ([_audioController audioChainIsBeingReconstructed]) return;
    
    if ((_displayMode == SA_DisplayModeOscilloscopeWaveform)
    	|| (_displayMode == SA_DisplayModeOscilloscopeFFT)
    ) {
        if (!_inittedOscilloscope) [self setupViewForOscilloscope];
        [self drawOscilloscope];
    }
}

/******************************************************************************/
- (void) setupViewForOscilloscope
{
    _inittedOscilloscope = YES;
}

/******************************************************************************/
- (void) drawOscilloscope
{
//    DLog();
    GLKView *view = (GLKView*) self.view;
//    [(AGLKContext*)view.context clear:GL_COLOR_BUFFER_BIT];
    
    BufferManager* bufferManager = [_audioController getBufferManagerInstance];
    Float32** drawBuffers = bufferManager->GetDrawBuffers();
    
    if (_displayMode == SA_DisplayModeOscilloscopeFFT) {
        if (bufferManager->HasNewFFTData()) {
            bufferManager->GetFFTOutput(_FFTData);
            
            int y, maxY;
            maxY = bufferManager->GetCurrentDrawBufferLength();
            int FFTLength = bufferManager->GetFFTOutputBufferLength();
            for (y = 0; y < maxY; y++) {
                CGFloat yFract = (CGFloat)y / (CGFloat)(maxY - 1);
                CGFloat FFTIndex = yFract * ((CGFloat)FFTLength - 1);
                
                double FFTIndex_i, FFTIndex_f;
                FFTIndex_f = modf(FFTIndex, &FFTIndex_i);
                
                CGFloat FFT_l_fl, FFT_r_fl;
                CGFloat interpVal;
                
                int lowerIndex = (int) FFTIndex_i;
                int upperIndex = (int) FFTIndex_i + 1;
                
                upperIndex = (upperIndex == FFTLength) ? FFTLength - 1 : upperIndex;
                
                FFT_l_fl = (CGFloat)(_FFTData[lowerIndex] + 80) / 64.0;
                FFT_r_fl = (CGFloat)(_FFTData[upperIndex] + 80) / 64.0;
                interpVal = FFT_l_fl * (1.0 - FFTIndex_f) + FFT_r_fl * FFTIndex_f;
                
                drawBuffers[0][y] = CLAMP(0.0, interpVal, 1.0);
            }
            [self cycleOscilloscopeLines];
        }
    }
    
    GLfloat* oscilloscopeLine_ptr;
    GLfloat max = kDefaultDrawSamples;
//    GLfloat max = bufferManager->GetCurrentDrawBufferLength();
    Float32* drawBuffer_ptr;
    
    UInt32 drawBuffer_i;
    // draw a line for each stored line in the buffer
    for (drawBuffer_i = 0; drawBuffer_i < _NumberOfDrawBuffers; drawBuffer_i++) {
        if (!drawBuffers[drawBuffer_i]) continue;
        
        oscilloscopeLine_ptr = _oscilloscopeLine;
        drawBuffer_ptr = drawBuffers[drawBuffer_i];
        
        GLfloat i;
        // fill vertex array with points
        for (i = 0.0; i < max; i=i+1.0) {
            *oscilloscopeLine_ptr++ = i / max ;
            *oscilloscopeLine_ptr++ = (Float32)(*drawBuffer_ptr++);
            
            if (drawBuffer_i == 0) {
                *oscilloscopeLine_ptr++ = 1.0; // red
                *oscilloscopeLine_ptr++ = 1.0; // green
                *oscilloscopeLine_ptr++ = 1.0; // blue
                *oscilloscopeLine_ptr++ = 1.0; //alpha
            }
            else {
                *oscilloscopeLine_ptr++ = 0.0; // red
                *oscilloscopeLine_ptr++ = 1.0; // green
                *oscilloscopeLine_ptr++ = 0.0; // blue
                *oscilloscopeLine_ptr++ =      //alpha
                (1.0 * (1.0 - ((GLfloat)drawBuffer_i / (GLfloat)kNumDrawBuffers)));
            }
        }
        
        [self.vertexBuffer
         reinitWithAttribStride:(2 + 4) * sizeof(GLfloat) numberOfVertices:max bytes:_oscilloscopeLine
         ];
        
        [self.vertexBuffer
         prepareToDrawWithAttrib:GLKVertexAttribPosition numberOfCoordinates:2 attribOffset:0 shouldEnable:YES
         ];
        
        // draw newest line in solid green, else draw in faded green
//        if (drawBuffer_i == 0) {
////            *(_oscilloscopeLine + 256 - 1) = 0.25;
////            *(_oscilloscopeLine + 512 - 1) = 0.50;
////            *(_oscilloscopeLine + 1024 - 1) = 0.75;
////            self.baseEffect.constantColor = GLKVector4Make(1.0, 1.0, 1.0, 1.0);
//        }
//        else {
////            self.baseEffect.constantColor = GLKVector4Make(0.0, 1.0, 0.0, (1.0 * (1.0 - ((GLfloat)drawBuffer_i / (GLfloat)kNumDrawBuffers))));
//            for(int j = 0; j < max; j++) {
//                *oscilloscopeLineColor_ptr++ = 0.0; // red
//                *oscilloscopeLineColor_ptr++ = 1.0; // green
//                *oscilloscopeLineColor_ptr++ = 0.0; // blue
//                *oscilloscopeLineColor_ptr++ =      //alpha
//                    (1.0 * (1.0 - ((GLfloat)drawBuffer_i / (GLfloat)kNumDrawBuffers)));
//            }
//        }
        
        [self.vertexBuffer
         prepareToDrawWithAttrib:GLKVertexAttribColor
         numberOfCoordinates:4
         attribOffset:2 * sizeof(GLfloat)
         shouldEnable:YES
         ];

        [self.vertexBuffer
         drawArrayWithMode:GL_LINE_STRIP startVertexIndex:0 numberOfVertices:max
         ];
    }
}

/******************************************************************************/
- (void) cycleOscilloscopeLines
{
    BufferManager* bufferManager = [_audioController getBufferManagerInstance];
    // Cycle draw buffer line display
    bufferManager->CycleDrawBuffers();
}

/******************************************************************************/

- (IBAction)cycleDrawBufferSize:(id)sender {
    if (_displayMode == SA_DisplayModeOscilloscopeWaveform) {
        _NumberOfDrawBuffers = 1;
    }
    else {
        switch (_NumberOfDrawBuffers) {
            case 1:
                _NumberOfDrawBuffers = 2;
                break;

            case 2:
                _NumberOfDrawBuffers = kNumDrawBuffers;
                break;
                
            case kNumDrawBuffers:
                _NumberOfDrawBuffers = 1;
                break;
                
            default:
                break;
        }
    }
    
    [self.drawBuffersLabel
      setText:[NSString stringWithFormat:@"%d", _NumberOfDrawBuffers]
     ];
}

- (IBAction)switchDisplayDomain:(id)sender {
    BufferManager* bufferManager = [_audioController getBufferManagerInstance];

    if(_displayMode == SA_DisplayModeOscilloscopeWaveform) {
        [self.waveFFTButton
         setTitle:@"FFT" forState:UIControlStateNormal
         ];
        _displayMode = SA_DisplayModeOscilloscopeFFT;
    }
    else if(_displayMode == SA_DisplayModeOscilloscopeFFT) {
        [self.waveFFTButton
         setTitle:@"Wave" forState:UIControlStateNormal
         ];
        _displayMode = SA_DisplayModeOscilloscopeWaveform;
        [self cycleDrawBufferSize:NULL];
    }

    bufferManager->SetDisplayMode(_displayMode);
}

@end
