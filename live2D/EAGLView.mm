//
//  EAGLView.m
//  live2D
//
//  Created by 空幻 on 2017/5/26.
//  Copyright © 2017年 空幻. All rights reserved.
//

#import "EAGLView.h"

#import "Live2D.h"
#import "UtSystem.h"
//#import "motion/MotionQueueManager.h"
//#import "motion/Live2DMotion.h"
#import "Live2DMotion.h"
#import "MotionQueueManager.h"
#import "UtSystem.h"

using namespace live2d ;

@implementation EAGLView
{
    MotionQueueManager* motionManager;
    Live2DMotion* motion;
}

NSString* MODEL_PATH = @"haru" ;
NSString* TEXTURE_PATH[] = {
    @"texture_00.png" ,
    @"texture_01.png" ,
    @"texture_02.png" ,
    NULL
} ;


+ (Class) layerClass
{
    return [CAEAGLLayer class];
}

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        btn.frame = CGRectMake(0, 0, 100, 40);
        [btn setTitle:@"播放" forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(play) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:btn];
        CAEAGLLayer* eaglLayer = (CAEAGLLayer*)self.layer;
        self.contentScaleFactor = [UIScreen mainScreen].scale ;
        eaglLayer.opaque = TRUE;
        
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
        
        if (!context || ![EAGLContext setCurrentContext:context])
        {
            return nil;
        }
        glGenFramebuffersOES(1, &defaultFramebuffer);
        glGenRenderbuffersOES(1, &colorRenderbuffer);
        glBindFramebufferOES(GL_FRAMEBUFFER_OES, defaultFramebuffer);
        glBindRenderbufferOES(GL_RENDERBUFFER_OES, colorRenderbuffer);
        glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, colorRenderbuffer);
        
        
        Live2D::init() ;
        
        NSString* modelpath = [[NSBundle mainBundle] pathForResource:MODEL_PATH ofType:@"moc"];
        live2DModel = Live2DModelIPhone::loadModel( [modelpath UTF8String] ) ;
        
        for( int i = 0 ; TEXTURE_PATH[i] != NULL ; i++ )
        {
            int texNo = [self loadTexture:(TEXTURE_PATH[i])] ;
            live2DModel->setTexture( i , texNo ) ;// 贴图和模型之间建立联系
            [textures addObject:[NSNumber numberWithInt:texNo]];// 用于释放资源
        }
        NSString *mtn = [[NSBundle mainBundle] pathForResource:@"idle_00" ofType:@"mtn"];
        motion = Live2DMotion::loadMotion( [mtn UTF8String]);
        motion->setFadeIn( 1000 );//淡入時間設定1000ms
        motion->setFadeOut( 1000 );//淡出時間設定1000ms
        motion->setLoop( true );//重複播放
        motionManager = new MotionQueueManager();//產生管理動作class
    }
    return self;
}

- (void) drawView:(id)sender
{
    [EAGLContext setCurrentContext:context];
    
    //  OpenGL绘制模型的相关设定
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    glClear(GL_COLOR_BUFFER_BIT);
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE , GL_ONE_MINUS_SRC_ALPHA );
    glDisable(GL_DEPTH_TEST) ;
    glDisable(GL_CULL_FACE) ;
    
    //motionManager->startMotion( motion, false );//播放動作
    if (motionManager->isFinished())//开始动作播放只进行一次，需要判断
    {
        motionManager->startMotion(motion,false);
    }
    motionManager->updateParam( live2DModel );//更新動作
    
    live2DModel->update();
    live2DModel->draw();
    
    [context presentRenderbuffer:GL_RENDERBUFFER_OES];
}

- (void) layoutSubviews
{
    [context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(CAEAGLLayer*)self.layer];
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &deviceWidth);
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &deviceHeight);
    
    
    //  令Viewport符合设备的屏幕尺寸。显示出全部画面。
    glViewport(0, 0, deviceWidth, deviceHeight);
    
    //  简单的使用投影矩阵进行所有变换。
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    
    float modelWidth = live2DModel->getCanvasWidth(); //  在Modeler中设定的画布尺寸
    
    //  设定绘图范围。参数顺序为left, right, bottom, top。
    glOrthof(
             0,
             modelWidth,
             modelWidth * deviceHeight / deviceWidth,
             0,
             0.5f, -0.5f
             );
    
    timer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)(1/60)
                                     target:self
                                   selector:@selector(drawView:)
                                   userInfo:nil repeats:TRUE];
}


// 从图像文件读取贴图
- (GLuint)loadTexture:(NSString*)fileName
{
    GLuint texture;
    
    // 打开图像文件生成CGImageRef
    UIImage* uiImage = [UIImage imageNamed:fileName];
    
    CGImageRef image = uiImage.CGImage ;
    
    // 获得图像大小
    size_t width = CGImageGetWidth(image);
    size_t height = CGImageGetHeight(image);
    
    // 准备位图数据
    GLubyte* imageData = (GLubyte*) calloc(width * height * 4 , 1);
    CGContextRef imageContext = CGBitmapContextCreate(imageData,width,height,8,width * 4,CGImageGetColorSpace(image),
                                                      kCGImageAlphaPremultipliedLast);
    CGContextDrawImage(imageContext, CGRectMake(0, 0, (CGFloat)width, (CGFloat)height), image);
    CGContextRelease(imageContext);
    
    // 生成OpenGL用的贴图
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexParameteri(GL_TEXTURE_2D, GL_GENERATE_MIPMAP, GL_TRUE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
    
    free(imageData);
    
    // 返回所生成的贴图
    return texture;
}

- (void)play{
    if (timer != nil) {
        [timer invalidate];
        timer = nil;
    }else{
        timer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)(1/60)
                                                 target:self
                                               selector:@selector(drawView:)
                                               userInfo:nil repeats:TRUE];
    }
}

@end
