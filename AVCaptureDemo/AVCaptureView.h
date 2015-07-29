//
//  AVCaptureView.h
//  AVCaptureDemo
//
//  Created by liyuchang on 15/6/15.
//  Copyright (c) 2015年 liyuchang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AVFoundation/AVCaptureSession.h"
#import "AVFoundation/AVCaptureOutput.h"
#import "AVFoundation/AVCaptureDevice.h"
#import "AVFoundation/AVCaptureInput.h"
#import "AVFoundation/AVCaptureVideoPreviewLayer.h"
#import "AVFoundation/AVMediaFormat.h"

#import "AVFoundation/AVAssetWriter.h"
#import "AVFoundation/AVAssetWriterInput.h"
#import "AVFoundation/AVMediaFormat.h"
#import "AVFoundation/AVVideoSettings.h"
typedef void(^SecondCallBack)(NSString *countTime);
@interface AVCaptureView : UIView<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate>
@property (nonatomic,copy)SecondCallBack secCb;

-(void)startRecord;
-(void)stopRecord;
-(void)saveVideoToAlbum;

@end
