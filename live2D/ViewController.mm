//
//  ViewController.m
//  live2D
//
//  Created by 空幻 on 2017/5/26.
//  Copyright © 2017年 空幻. All rights reserved.
//

#import "ViewController.h"
#import "EAGLView.h"

@implementation ViewController

- (void)awakeFromNib
{
    [super awakeFromNib];//
    CGRect rect = CGRectMake(
                             50,
                             50,
                             [[UIScreen mainScreen] bounds].size.width - 50,
                             [[UIScreen mainScreen] bounds].size.height - 50) ;
    glView = [[EAGLView alloc] initWithFrame:rect] ;
    glView.backgroundColor = [UIColor redColor];
    glView.userInteractionEnabled = YES;
   
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:glView] ;
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
