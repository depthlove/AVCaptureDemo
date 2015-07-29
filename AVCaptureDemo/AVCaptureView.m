//
//  AVCaptureView.m
//  AVCaptureDemo
//
//  Created by liyuchang on 15/6/15.
//  Copyright (c) 2015年 liyuchang. All rights reserved.
//


#import "AVCaptureView.h"
typedef NSArray Devices;
@interface AVCaptureView ()
{
    AVCaptureSession *_session;
    Devices *_devices;
    AVCaptureVideoDataOutput *_vedioOutput;
    AVCaptureAudioDataOutput *_audioOutput;
    AVAssetWriterInput *_assetVideoWrite;
    AVAssetWriterInput *_assetAudioWrite;
    AVAssetWriter *_asset;
    AVCaptureVideoPreviewLayer *_preview;
    NSDate *timeEnd;
    NSCalendar *gregorian;
    NSString *vedioPath;
}
@end

@implementation AVCaptureView
-(instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self __init];
    }
    return self;
}


-(void)__init
{
    [self __initSession];
    [self __initInputDevice];
    [self __initPreview];
    [_session commitConfiguration];
    [_session startRunning];
}

-(void)__initSession
{
    _session = [[AVCaptureSession alloc] init];
}

-(void)__initInputDevice
{
    _devices = [AVCaptureDevice devices];
    AVCaptureDevice* vedio = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput* vedioInput = [AVCaptureDeviceInput deviceInputWithDevice:vedio error:nil];
    [_session addInput:vedioInput];
    AVCaptureDevice *audio = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audio error:nil];
    [_session addInput:audioInput];
    
    if (/* DISABLES CODE */ (NO) || [[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {//不建议配置参数，使用固定的显示码率更好，反正不是录制码率
        [_session setSessionPreset:AVCaptureSessionPresetInputPriority];
        [self setFPS:vedio];
    }else
    {
        [_session setSessionPreset:AVCaptureSessionPresetMedium];
    }
}

-(void)setFPS:(AVCaptureDevice *)vedio
{
    [_session beginConfiguration];
    NSError *error;
    CMTime frameDuration = CMTimeMake(1, 60);
    NSArray *supportedFrameRateRanges = [vedio.activeFormat videoSupportedFrameRateRanges];
    BOOL frameRateSupported = NO;
    for (AVFrameRateRange *range in supportedFrameRateRanges) {
        if (CMTIME_COMPARE_INLINE(frameDuration, >=, range.minFrameDuration) &&
            CMTIME_COMPARE_INLINE(frameDuration, <=, range.maxFrameDuration)) {
            frameRateSupported = YES;
        }
    }
    
    if (frameRateSupported && [vedio lockForConfiguration:&error]) {
        AVCaptureDeviceFormat *newFormat = [AVCaptureDeviceFormat new];
        [vedio setActiveFormat:newFormat];
        [vedio setActiveVideoMaxFrameDuration:frameDuration];
        [vedio setActiveVideoMinFrameDuration:frameDuration];
        [vedio unlockForConfiguration];
    }
    [_session commitConfiguration];
}

-(void)__initPreview
{
    _preview = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    _preview.videoGravity = AVLayerVideoGravityResize;
    _preview.frame = self.bounds;
    _preview.connection.videoOrientation = [self avOrientationForDeviceOrientation:[UIDevice currentDevice].orientation];
    [self.layer addSublayer:_preview];
}

-(void)__initOutput
{
    dispatch_queue_t captureQueue = dispatch_queue_create("capture", DISPATCH_QUEUE_SERIAL);
    _vedioOutput = [[AVCaptureVideoDataOutput alloc] init];
    _audioOutput = [[AVCaptureAudioDataOutput alloc] init];
    
    [_vedioOutput setSampleBufferDelegate:self queue:captureQueue];
    [_audioOutput setSampleBufferDelegate:self queue:captureQueue];
    [_session addOutput:_vedioOutput];
    [_session addOutput:_audioOutput];
    
    AVCaptureConnection *videoConnection = [self connectionWithMediaType:AVMediaTypeVideo fromConnections:[_vedioOutput connections]];
    if ([videoConnection isVideoOrientationSupported])
        [videoConnection setVideoOrientation:[self avOrientationForDeviceOrientation:[UIDevice currentDevice].orientation]];
}

-(void)__initAsset
{
    vedioPath = [self vedioSavePath];
    NSURL *url = [NSURL fileURLWithPath:vedioPath];
    _asset = [AVAssetWriter assetWriterWithURL:url fileType:AVFileTypeQuickTimeMovie error:nil];
    
    _assetVideoWrite = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:[self vedioAssetWriteSetting]];
    _assetVideoWrite.expectsMediaDataInRealTime = YES;

    if ([_asset canAddInput:_assetVideoWrite]) {
        [_asset addInput:_assetVideoWrite];
    }
    _assetAudioWrite = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio outputSettings:nil];
    _assetAudioWrite.expectsMediaDataInRealTime = YES;
    if ([_asset canAddInput:_assetAudioWrite]) {
        [_asset addInput:_assetAudioWrite];
    }
}


-(AVCaptureConnection *)connectionWithMediaType:(NSString *)mediaType fromConnections:(NSArray *)connections
{
    for ( AVCaptureConnection *connection in connections ) {
        for ( AVCaptureInputPort *port in [connection inputPorts] ) {
            if ( [[port mediaType] isEqual:mediaType] ) {
                return connection;
            }
        }
    }
    return nil;
}



- (AVCaptureVideoOrientation)avOrientationForDeviceOrientation:(UIDeviceOrientation)deviceOrientation
{
    AVCaptureVideoOrientation result = AVCaptureVideoOrientationPortrait;
    if ( deviceOrientation == UIDeviceOrientationLandscapeLeft )
        result = AVCaptureVideoOrientationLandscapeRight;
    else if ( deviceOrientation == UIDeviceOrientationLandscapeRight )
        result = AVCaptureVideoOrientationLandscapeLeft;
    return result;
}

-(NSDictionary *)vedioCaptureOutSetting
{
    CGFloat width = 0.;
    CGFloat height = 0.;
    width = self.frame.size.width;
    height = self.frame.size.height;
    return [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange],kCVPixelBufferPixelFormatTypeKey, nil];
}

-(NSDictionary *)vedioAssetWriteSetting
{
    CGFloat width = 0.;
    CGFloat height = 0.;
    width = self.frame.size.width;
    height = self.frame.size.height;
    return @{AVVideoCodecKey:AVVideoCodecH264,
             AVVideoCompressionPropertiesKey:@{AVVideoAllowFrameReorderingKey:@YES,
                                               AVVideoAverageBitRateKey:@(128.0*1024.0)},
             AVVideoWidthKey:[NSNumber numberWithInt: width],
             AVVideoHeightKey:[NSNumber numberWithInt:height]};
}
-(NSString *)vedioSavePath
{
    NSDate *date = [NSDate date];
    NSDateFormatter *format = [NSDateFormatter new];
    [format setDateFormat:@"yyyyMMddHHmmss"];
    NSString* filename = [NSString stringWithFormat:@"Documents/%@.mp4", [format stringFromDate:date]];
    NSString* path = [NSHomeDirectory() stringByAppendingPathComponent:filename];
    return path;
}


-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {

    if (CMSampleBufferDataIsReady(sampleBuffer))
    {
        CMTime lastSampleTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
        double dPTS = (double)(lastSampleTime.value) / lastSampleTime.timescale;
        [self recoding:dPTS];
        if(_asset.status != AVAssetWriterStatusWriting && _asset.status == AVAssetWriterStatusUnknown)
        {
            [_asset startWriting];
            [_asset startSessionAtSourceTime:lastSampleTime];
        }
        if (captureOutput == _vedioOutput)
        {
            if( _asset.status > AVAssetWriterStatusWriting )
            {
                if( _asset.status == AVAssetWriterStatusFailed )
                    return;
            }
            if ([_assetVideoWrite isReadyForMoreMediaData])
            {
                if(![_assetVideoWrite appendSampleBuffer:sampleBuffer] )
                {
                    NSLog(@"Unable to write to video input");
                }
                else
                {
                    
                    NSLog(@"already write vidio");
                }
            }
        }
        else
            if (captureOutput == _audioOutput)
            {
                
                if( _asset.status > AVAssetWriterStatusWriting )
                {
                    if( _asset.status == AVAssetWriterStatusFailed )
                        return;
                }
                if ([_assetAudioWrite isReadyForMoreMediaData])
                {
                    if( ![_assetAudioWrite appendSampleBuffer:sampleBuffer])
                    {
                        NSLog(@"Unable to write to audio input");
                    }
                    else
                    {
                        NSLog(@"already write audio");
                    }
                }
            }
    }
}

#pragma mark -

-(AVCaptureDevice *)getDevice:(AVCaptureDevicePosition)devicePostion
{
    AVCaptureDevice *dev = nil;
    for (AVCaptureDevice *device in _devices) {
        if ([device hasMediaType:AVMediaTypeVideo]) {
            if ([device position] == AVCaptureDevicePositionBack) {
                NSLog(@"Device position : back");
                dev = device;
            }
            if ([device position] == AVCaptureDevicePositionFront) {
                dev = device;
                NSLog(@"Device position : front");
            }
        }
    }
    return dev;
}


-(void)startRecord
{
    [self __initOutput];
    [self __initAsset];
}

-(void)recoding:(double)dps
{
    [self readSecond:dps];
}

-(void)stopRecord
{

    if (_session) {
        [_session stopRunning];
    }
    if (_asset) {
        [_assetAudioWrite markAsFinished];
        [_assetVideoWrite markAsFinished];
        [_asset finishWritingWithCompletionHandler:^{

            _asset = nil;
            [self saveVideoToAlbum];
            vedioPath = nil;
        }];

    }
}


-(void)saveVideoToAlbum
{
    BOOL compatible = UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(vedioPath);
    if (compatible)
    {
        UISaveVideoAtPathToSavedPhotosAlbum(vedioPath, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
    }

}

- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo: (void *)contextInfo {
    
    NSLog(@"%@",videoPath);
    
    NSLog(@"%@",error);
    
}


-(void)readSecond:(double)pts
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:pts];
        timeEnd = [NSDate dateWithTimeInterval:600 sinceDate:date];
        gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    });
    NSDate *curDate = [NSDate dateWithTimeIntervalSince1970:pts];
    
    NSDateComponents *comps = [gregorian components:NSCalendarUnitMinute|NSCalendarUnitSecond fromDate:timeEnd  toDate:curDate  options:0];
    NSInteger second = [comps second];
    NSInteger min = [comps minute];
    _secCb([NSString stringWithFormat:@"%ld:%ld",min,second]);
    if ([curDate isEqualToDate:timeEnd]) {
        [self stopRecord];
    }

}



@end
