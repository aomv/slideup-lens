//
//  ViewController.m
//  Sing
//
//  Created by Marco Vanossi on 4/15/19.
//  Copyright © 2019 Marco Vanossi. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>


//toggle front camera and back camera

@interface ViewController ()<UIWebViewDelegate>
@property (nonatomic, strong) AVCaptureSession *capture;
@property (nonatomic,strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (nonatomic,assign) BOOL isUsingFrontFacingCamera;

@property (nonatomic,strong) AVCaptureDeviceInput *videoInputDevice;

@property (nonatomic, strong) UIWebView *webView;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.view.backgroundColor=[UIColor redColor];
    
    UIButton * cameraChangeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    cameraChangeButton.frame=CGRectMake(self.view.frame.size.width-102.0/2.0, 0, 102.0/2.0, 133.0/2.0);
    [cameraChangeButton setImage:[UIImage imageNamed:@"lens-camera-change-button.png"] forState:UIControlStateNormal];
    cameraChangeButton.imageView.contentMode=UIViewContentModeScaleAspectFit;
    [cameraChangeButton addTarget:self action:@selector(didTapSwitchCamera) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:cameraChangeButton];
    
    
    UIButton * closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    closeButton.frame=CGRectMake(0, 0, 117.0/2.0, 122.0/2.0);
    [closeButton setImage:[UIImage imageNamed:@"lens-close-button.png"] forState:UIControlStateNormal];
    closeButton.imageView.contentMode=UIViewContentModeScaleAspectFit;
    [closeButton addTarget:self action:@selector(didTapCloseButton) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:closeButton];
    
    
    
    UIButton * cameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
    cameraButton.frame=CGRectMake((self.view.frame.size.width-180.0/2.0)/2.0, self.view.frame.size.height-182.0/2.0-142.0/2.0, 180.0/2.0, 182.0/2.0);
    [cameraButton setImage:[UIImage imageNamed:@"lens-camera-button.png"] forState:UIControlStateNormal];
    cameraButton.imageView.contentMode=UIViewContentModeScaleAspectFit;
    [cameraButton addTarget:self action:@selector(didTapCameraButton) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:cameraButton];
    
    
    [self loadLens];

    
}

-(void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    return;
    //https://developer.apple.com/documentation/avfoundation/cameras_and_media_capture/requesting_authorization_for_media_capture_on_macos?language=objc
    switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo])
    {
        case AVAuthorizationStatusAuthorized:
        {
            // The user has previously granted access to the camera.
            NSLog(@"User has previously granted the camera");

            __weak typeof(self) weakSelf=self;
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf startCapture];
            });
            break;
        }
        case AVAuthorizationStatusNotDetermined:
        {
            // The app hasn't yet asked the user for camera access.
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (granted) {
                    
                    NSLog(@"User granted the camera");
                    __weak typeof(self) weakSelf=self;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakSelf startCapture];
                    });
                }
                else {
                    NSLog(@"User denied access to the camera");
                }
            }];
            break;
        }
        case AVAuthorizationStatusDenied:
        {
            NSLog(@"User previously denied access to the camera");

            // The user has previously denied access.
            return;
        }
        case AVAuthorizationStatusRestricted:
        {
            
            NSLog(@"User cant grant access due to restrictions");
            // The user can't grant access due to restrictions.
            return;
        }
    }
    
    
    
    
}

- (void)startCapture
{
    
    NSError *error;
    self.capture = [[AVCaptureSession alloc] init];
    

    NSArray *captureDeviceType = @[AVCaptureDeviceTypeBuiltInWideAngleCamera];
    AVCaptureDeviceDiscoverySession *cameraDevices = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:captureDeviceType mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionFront];
    
    AVCaptureDevice *cameraDev = [[cameraDevices devices] lastObject];
    //    AVCaptureDevice *cameraDev = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (cameraDev == nil){
        NSLog(@"Couldn't create video capture device");
        return ;
    }
    self.videoInputDevice = [AVCaptureDeviceInput deviceInputWithDevice:cameraDev error:&error];
    if (error != nil){
        NSLog(@"Couldn't create video input");
        return ;
    }
    if ([self.capture canAddInput:self.videoInputDevice] == NO){
        NSLog(@"Couldn't add video input");
        return ;
    }
    [self.capture addInput:self.videoInputDevice];
    
    
    
    
    
    AVCaptureDevice *audioDev = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    if (audioDev == nil){
        NSLog(@"Couldn't create audio capture device");
        return ;
    }
    AVCaptureDeviceInput *audioIn = [AVCaptureDeviceInput deviceInputWithDevice:audioDev error:&error];
    if (error != nil){
        NSLog(@"Couldn't create audio input");
        return ;
    }
    if ([self.capture canAddInput:audioIn] == NO){
        NSLog(@"Couldn't add audio input");
        return ;
    }
    [self.capture addInput:audioIn];
    
    
    
    
    
    self.videoPreviewLayer=[AVCaptureVideoPreviewLayer layerWithSession:self.capture];
    self.videoPreviewLayer.frame = self.view.bounds;
    [self.videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [self.view.layer addSublayer:self.videoPreviewLayer];
    
    
    
    // export audio data
    /*
    AVCaptureAudioDataOutput *audioOutput = [[AVCaptureAudioDataOutput alloc] init];
    [audioOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    if ([self.capture canAddOutput:audioOutput] == NO){
        NSLog(@"Couldn't add audio output");
        return ;
    }
    [self.capture addOutput:audioOutput];
    [audioOutput connectionWithMediaType:AVMediaTypeAudio];*/
    
    
    dispatch_queue_t globalQueue =  dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_async(globalQueue, ^{
        [self.capture startRunning];
        //Step 13
    });
    
    
    
    
    
    
    
    
}

- (void)didTapSwitchCamera {
    
    AVCaptureDevicePosition desiredPosition;
    if (!self.isUsingFrontFacingCamera)
        desiredPosition = AVCaptureDevicePositionBack;
    else
        desiredPosition = AVCaptureDevicePositionFront;
    
    
    //find new camera
    NSArray *captureDeviceType = @[AVCaptureDeviceTypeBuiltInWideAngleCamera];
    AVCaptureDeviceDiscoverySession *cameraDevices = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:captureDeviceType mediaType:AVMediaTypeVideo position:desiredPosition];
    AVCaptureDevice *cameraDev = [[cameraDevices devices] lastObject];
    
    
    [[self.videoPreviewLayer session] beginConfiguration];
    
    //remove old camera
    [[self.videoPreviewLayer session] removeInput:self.videoInputDevice];

    //add new camera
    self.videoInputDevice = [AVCaptureDeviceInput deviceInputWithDevice:cameraDev error:nil];
    [[self.videoPreviewLayer session] addInput:self.videoInputDevice];
    
    [[self.videoPreviewLayer session] commitConfiguration];
    
    
    self.isUsingFrontFacingCamera = !self.isUsingFrontFacingCamera;
}
-(void)didTapCloseButton {
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
}
-(void)didTapCameraButton {
    
    //take picture
    
}

-(void)loadLens {
    
    //
    
    self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    self.webView.backgroundColor=[UIColor clearColor];
    [self.webView setOpaque:NO];

    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.bereal.to/stats/slide-up/lens-details/"]]];
    
    
    self.webView.delegate=self;
    [self.view addSubview:self.webView];
}
@end
