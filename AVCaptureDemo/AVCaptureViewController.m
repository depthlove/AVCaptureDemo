//
//  AVCaptureViewController.m
//  AVCaptureDemo
//
//  Created by liyuchang on 15/6/16.
//  Copyright (c) 2015年 liyuchang. All rights reserved.
//

#import "AVCaptureViewController.h"
#import "AVCaptureView.h"

@interface AVCaptureViewController ()
{
    UILabel *label;
    AVCaptureView *capture;
}
@end

@implementation AVCaptureViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    [self initUI];
}
-(void)initUI
{
    UIView *view = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:view];
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.view addSubview:btn];
    btn.frame = CGRectMake((self.view.frame.size.width-44)/2., 5, 44, 44);
    [btn setBackgroundColor:[UIColor blueColor]];
    [btn setTitle:@"开始" forState:UIControlStateNormal];
    [btn setTitle:@"结束" forState:UIControlStateSelected];
    [btn addTarget:self action:@selector(begin:) forControlEvents:UIControlEventTouchUpInside];
    label = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(btn.frame), self.view.frame.size.width, 44)];
    [self.view addSubview:label];
    label.layer.borderColor = [UIColor redColor].CGColor;
    label.layer.borderWidth = 1.0f;
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor redColor];
    
    capture = [[AVCaptureView alloc] initWithFrame:view.bounds];
    [view addSubview:capture];
    __weak typeof(label) weakLabel = label;
    capture.secCb =^(NSString *countTime){
        dispatch_async(dispatch_get_main_queue(), ^{
            weakLabel.text = countTime;
        });
        
    };
}

-(void)begin:(UIButton *)btn
{
    UIButton *temp = btn;
    if (temp.selected == NO) {//开始
        [capture startRecord];
        temp.selected = YES;
    }else
    {//结束
        [capture stopRecord];
        temp.selected = NO;
    }
    
}

@end
