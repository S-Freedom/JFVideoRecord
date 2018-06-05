//
//  ViewController.m
//  JFVideoRecord
//
//  Created by huangpengfei on 2018/6/5.
//  Copyright © 2018年 huangpengfei. All rights reserved.
//

#import "JFVideoRecordController.h"
#import <AVFoundation/AVFoundation.h>
@interface JFVideoRecordController () <AVCaptureFileOutputRecordingDelegate>
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureInput *input;
@property (nonatomic, strong) AVCaptureOutput *output;

@property (nonatomic, strong) AVCaptureDeviceInput *deviceAudioInput;
@property (nonatomic, strong) AVCaptureDeviceInput *deviceVideoInput;

@property (nonatomic, strong) AVCaptureMovieFileOutput *fileOutPut;

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

@property (nonatomic, copy) NSString *filePath;

@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@end

@implementation JFVideoRecordController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(10, 100, 100,50)];
    btn.tag = 1;
    [btn setTitle:@"record" forState:UIControlStateNormal];
    //    [btn setTitle:@"record-pause" forState:UIControlStateSelected];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(record:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    UIButton *play = [[UIButton alloc] initWithFrame:CGRectMake(120, 100, 100,50)];
    play.tag = 1001;
    [play setTitle:@"stop" forState:UIControlStateNormal];
    //    [play setTitle:@"stop" forState:UIControlStateSelected];
    [play setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [play addTarget:self action:@selector(stop:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:play];
    
    UIButton *reverse = [[UIButton alloc] initWithFrame:CGRectMake(230, 100, 100,50)];
    reverse.tag = 1001;
    [reverse setTitle:@"play" forState:UIControlStateNormal];
    [reverse setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [reverse addTarget:self action:@selector(play:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:reverse];
    
    [self initCapture];
}

- (void)initCapture{
    //    1. 创建捕捉会话
    self.session = [[AVCaptureSession alloc] init];
    if([self.session canSetSessionPreset:AVCaptureSessionPreset640x480]){
        self.session.sessionPreset = AVCaptureSessionPreset640x480;
    }
    //    2. 设置视频的输入
    [self setUpInputVideo];
    //    3. 设置音频的输入
    [self setUpInputAudio];
    //    4. 输出源设置,这里视频，音频数据会合并到一起输出，在代理方法中国也可以单独拿到视频或者音频数据，给AVCaptureMovieFileOutput指定路径，开始录制之后就会向这个路径写入数据
    [self setUpFileOut];
    //    5. 添加视频预览层
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    self.previewLayer.frame = CGRectMake(10, 200, 300, 400);
    [self.view.layer addSublayer:self.previewLayer];
    //    6. 开始采集数据，这个时候还没有写入数据，用户点击录制后就可以开始写入数据
    
}

- (void)setUpInputVideo{
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    //    device.videoHDREnabled = YES;
    //    device.activeVideoMinFrameDuration = CMTimeMake(1, 60);
    NSError *error;
    self.deviceVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:device error:&error];
    if([self.session canAddInput:self.deviceVideoInput]){
        [self.session addInput:self.deviceVideoInput];
    }
}

- (void)setUpInputAudio{
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    
    NSError *error;
    self.deviceAudioInput = [[AVCaptureDeviceInput alloc] initWithDevice:device error:&error];
    if([self.session canAddInput:self.deviceAudioInput]){
        [self.session addInput:self.deviceAudioInput];
    }
}

- (void)setUpFileOut{
    
    self.fileOutPut = [[AVCaptureMovieFileOutput alloc] init];
    AVCaptureConnection *conn = [self.fileOutPut connectionWithMediaType:AVMediaTypeVideo];
    if([conn isVideoStabilizationSupported]){
        conn.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
    }
    //    conn.videoOrientation = [self.view.layer connect];
    if([self.session canAddOutput:self.fileOutPut]){
        [self.session addOutput:self.fileOutPut];
    }
}

- (BOOL)canRecord
{
    __block BOOL bCanRecord = YES;
    if ([[[UIDevice currentDevice]systemVersion]floatValue] >= 7.0) {
        
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        if ([audioSession respondsToSelector:@selector(requestRecordPermission:)]) {
            [audioSession performSelector:@selector(requestRecordPermission:) withObject:^(BOOL granted) {
                if (granted) {
                    bCanRecord = YES;
                } else {
                    bCanRecord = NO;
                }
            }];
        }
    }
    
    NSLog(@"bCanRecord1 : %d",bCanRecord);
    return bCanRecord;
}

- (void)captureOutput:(AVCaptureFileOutput *)output didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections{
    NSLog(@"%s",__func__);
}

- (void)captureOutput:(AVCaptureFileOutput *)output didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections error:(nullable NSError *)error{
    NSLog(@"%s",__func__);
    NSLog(@"%@",outputFileURL);
}

/* 获取录音存放路径 */
- (NSString *)getSaveFilePath{
    NSString *urlStr = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                           NSUserDomainMask,YES).firstObject;
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat  = @"yyyyMMddHHmmss";
    NSString *dateStr = [formatter stringFromDate:[NSDate date]];
    urlStr = [urlStr stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-output.mov",dateStr]];
    return urlStr;
}

- (void)record:(UIButton *)sender{
    [self.session startRunning];
    self.previewLayer.frame = CGRectMake(10, 200, 300, 400);
    NSString *path = [self getSaveFilePath];
    NSURL *url = [NSURL fileURLWithPath:path];
    [self.fileOutPut startRecordingToOutputFileURL:url recordingDelegate:self];
    self.filePath = path;
}

- (void)stop:(UIButton *)sender{
    [self.session stopRunning];
}

- (void)play:(UIButton *)sender{
    
    self.previewLayer.frame = CGRectZero;
    NSURL *url = [NSURL fileURLWithPath:self.filePath];
    AVPlayerItem *item = [[AVPlayerItem alloc] initWithURL:url];
    AVPlayer *player = [AVPlayer playerWithPlayerItem:item];
    AVPlayerLayer *playerLayer = [[AVPlayerLayer alloc] initWithLayer:player];
    playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
    playerLayer.frame = CGRectMake(10, 200, 300, 400);
    playerLayer.backgroundColor = [UIColor blackColor].CGColor;
    playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    [self.view.layer addSublayer:playerLayer];
    self.playerLayer = playerLayer;
    [player play];
}

@end
