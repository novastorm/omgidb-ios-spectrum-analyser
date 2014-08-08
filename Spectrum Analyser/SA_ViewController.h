//
//  SA_ViewController.h
//  Spectrum Analyser
//
//  Created by Adland Lee on 7/24/14.
//  Copyright (c) 2014 Adland Lee. All rights reserved.
//

#import <GLKit/GLKit.h>

@class AGLKVertexAttribArrayBuffer;

@interface SA_ViewController : GLKViewController

@property (nonatomic) GLKBaseEffect *baseEffect;
@property (nonatomic) AGLKVertexAttribArrayBuffer *vertexBuffer;

//@property BOOL applicationResignedActive;

@end

