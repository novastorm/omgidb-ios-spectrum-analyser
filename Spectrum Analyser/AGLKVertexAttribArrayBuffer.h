//
//  AGLKVertexAttribArrayBuffer.h
//  
//

/******************************************************************************
 
 Copyright (c) 2012 Erik M. Buck
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 
 ******************************************************************************/

#import <GLKit/GLKit.h>

@class AGLKElementIndexArrayBuffer;

/////////////////////////////////////////////////////////////////
// 
typedef enum {
    AGLKVertexAttribPosition = GLKVertexAttribPosition,
    AGLKVertexAttribNormal = GLKVertexAttribNormal,
    AGLKVertexAttribColor = GLKVertexAttribColor,
    AGLKVertexAttribTexCoord0 = GLKVertexAttribTexCoord0,
    AGLKVertexAttribTexCoord1 = GLKVertexAttribTexCoord1,
} AGLKVertexAttrib;


@interface AGLKVertexAttribArrayBuffer : NSObject
{
   GLsizeiptr   stride;
   GLsizeiptr   bufferSizeBytes;
   GLuint       name;
}

@property (nonatomic, readonly) GLuint
   name;
@property (nonatomic, readonly) GLsizeiptr
   bufferSizeBytes;
@property (nonatomic, readonly) GLsizeiptr
   stride;

+ (void)drawPreparedArraysWithMode:(GLenum)mode
   startVertexIndex:(GLint)first
   numberOfVertices:(GLsizei)count;

- (id)initWithAttribStride:(GLsizeiptr)stride
   numberOfVertices:(GLsizei)count
   bytes:(const GLvoid *)dataPtr
   usage:(GLenum)usage;

- (void)prepareToDrawWithAttrib:(GLuint)index
   numberOfCoordinates:(GLint)count
   attribOffset:(GLsizeiptr)offset
   shouldEnable:(BOOL)shouldEnable;

- (void)drawArrayWithMode:(GLenum)mode
   startVertexIndex:(GLint)first
   numberOfVertices:(GLsizei)count;
   
- (void)reinitWithAttribStride:(GLsizeiptr)stride
   numberOfVertices:(GLsizei)count
   bytes:(const GLvoid *)dataPtr;
   
@end
