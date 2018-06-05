# JFVideoRecord

1.JFAudioRecordController  音频录制

关键代码如下
NSError *error;
[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error];
[[AVAudioSession sharedInstance] setActive:YES error:&error];

- (void)initRecord{
NSString *path = [self getSaveFilePath];
NSURL *url = [NSURL fileURLWithPath:path];
NSMutableDictionary *mDic = [NSMutableDictionary dictionaryWithCapacity:10];
//设置录音格式
[mDic setObject:@(kAudioFormatLinearPCM) forKey:AVFormatIDKey];
//设置录音采样率，8000是电话采样率，对于一般录音已经够了
[mDic setObject:@(8000) forKey:AVSampleRateKey];
//设置通道,这里采用单声道
[mDic setObject:@(1) forKey:AVNumberOfChannelsKey];
//每个采样点位数,分为8、16、24、32
[mDic setObject:@(8) forKey:AVLinearPCMBitDepthKey];
//是否使用浮点数采样
[mDic setObject:@(YES) forKey:AVLinearPCMIsFloatKey];

NSError *error;
AVAudioRecorder *recorder = [[AVAudioRecorder alloc] initWithURL:url settings:mDic error:&error];
if(error){
NSLog(@"recorder %@",error);
}
recorder.meteringEnabled = YES;
recorder.delegate = self;
[recorder prepareToRecord];
self.recorder = recorder;
}

/* 设置音频会话支持录音和音乐播放 */
- (void)setAVAudioSession{
//获取音频会话
AVAudioSession *audioSession = [AVAudioSession sharedInstance];
//设置为播放和录音状态，以便可以在录制完之后播放录音
[audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:NULL];
//激活修改
[audioSession setActive:YES error:NULL];
}


2.   JFVideoRecordController   视频录制

关键代码如下

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

以上仅仅是关键代码， demo请参见  https://github.com/thomas0326/JFVideoRecord.git




