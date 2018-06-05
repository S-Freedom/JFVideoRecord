//
//  JFAudioRecordController.m
//  JFVideoRecord
//
//  Created by huangpengfei on 2018/6/5.
//  Copyright © 2018年 huangpengfei. All rights reserved.
//

#import "JFAudioRecordController.h"
#import <AVFoundation/AVFoundation.h>
@interface JFAudioRecordController () <AVAudioRecorderDelegate>
@property (nonatomic, strong) AVAudioRecorder *recorder;
@property (nonatomic, strong) AVAudioPlayer *player;
@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, strong) UILabel *desLabel;
@end

@implementation JFAudioRecordController

- (void)viewDidLoad {
    [super viewDidLoad];

    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(10, 20, 100,50)];
    [btn setTitle:@"record" forState:UIControlStateNormal];
    [btn setTitle:@"pause" forState:UIControlStateSelected];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(record:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    UIButton *stop = [[UIButton alloc] initWithFrame:CGRectMake(120, 20, 100,50)];
    [stop setTitle:@"stop" forState:UIControlStateNormal];
    [stop setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [stop addTarget:self action:@selector(stop:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:stop];
    
    UIButton *play = [[UIButton alloc] initWithFrame:CGRectMake(230, 20, 100,50)];
    [play setTitle:@"play" forState:UIControlStateNormal];
    //    [play setTitle:@"play-pause" forState:UIControlStateSelected];
    [play setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [play addTarget:self action:@selector(playPause:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:play];
    
    UILabel *desLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 100, 100, 20)];
    desLabel.text = @"time";
    desLabel.font = [UIFont systemFontOfSize:14.0f];
    desLabel.textColor = [UIColor blackColor];
    [self.view addSubview:desLabel];
    self.desLabel = desLabel;
    
    [self setAVAudioSession];
    [self initRecord];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    NSLog(@"ssss");
    if ([keyPath isEqualToString:@"recording"]) {
        NSLog(@"Height is changed! new=%@", [change valueForKey:NSKeyValueChangeNewKey]);
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (NSString *)getSaveFilePath{
    NSString *urlStr = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                           NSUserDomainMask,YES).firstObject;
    urlStr = [urlStr stringByAppendingPathComponent:@"recorder.caf"];
    return urlStr;
}

- (void)record:(UIButton *)sender{
        sender.selected = !sender.selected;
        if(![self.recorder isRecording]){
            [self.recorder record];
            NSLog(@"recordering");
            self.desLabel.text = @"0";
            __weak typeof(self) weakSelf = self;
            self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0f repeats:YES block:^(NSTimer * _Nonnull timer) {
                weakSelf.desLabel.text = [NSString stringWithFormat:@"%.1fs",weakSelf.recorder.currentTime];
            }];
        }else if([self.recorder isRecording]){
            [self.recorder pause];
            NSLog(@"recorder pause");
        }
}

- (void)stop:(UIButton *)sender{
    [self.timer invalidate];
    self.timer = nil;
    NSTimeInterval interval = self.recorder.currentTime;
    self.desLabel.text = [NSString stringWithFormat:@"%.1f",interval];
    [self.recorder stop];
    NSLog(@"recorder stop");
}

- (void)playPause:(UIButton *)sender{
    NSLog(@"play");
     [self initPlay];
    [self.player prepareToPlay];
    [self.player play];
    __weak typeof(self) weakSelf = self;
    NSTimeInterval interval = self.player.duration;
    NSLog(@"total time is %.1f",interval);
    __block NSTimeInterval count = 0;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0f repeats:YES block:^(NSTimer * _Nonnull timer) {
        if(interval <= count){
            [weakSelf.timer invalidate];
            weakSelf.timer = nil;
            return;
        }
        count ++ ;
        weakSelf.desLabel.text = [NSString stringWithFormat:@"%.1f",count];
    }];
}

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


- (void)initPlay{
    
    NSString *path = [self getSaveFilePath];
    NSURL *url = [NSURL fileURLWithPath:path];
    NSError *error;
    AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    if(error){
        NSLog(@"initPlay %@",error);
    }
    player.numberOfLoops = 0;
    self.player = player;
}


#pragma mark -- AVAudioRecorderDelegate
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag{
    NSLog(@"%s",__func__);
    
}

- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError * __nullable)error{
    NSLog(@"%s",__func__);
}

@end
