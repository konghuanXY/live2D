//
//  EAGLView.h
//  live2D
//
//  Created by 空幻 on 2017/5/26.
//  Copyright © 2017年 空幻. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import "Live2DModelIPhone.h"
#import <GLKit/GLKit.h>

@interface EAGLView : UIView
{
@private
    live2d::Live2DModelIPhone* live2DModel;
    NSMutableArray* textures;
    
    EAGLContext* context;
    
    GLint deviceWidth, deviceHeight;
    
    GLuint defaultFramebuffer, colorRenderbuffer;
@public
    NSTimer* timer;
}
- (id)initWithFrame:(CGRect)frame;
- (void)drawView:(id)sender;
- (GLuint)loadTexture:(NSString*)fileNamel;

@end
