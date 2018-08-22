//
//  glimpseScreen.m
//  Runner
//
//  Created by Brett on 8/13/18.
//  Copyright © 2018 The Chromium Authors. All rights reserved.
//

#import "glimpseScreen.h"
#import "AVFoundation/AVFoundation.h"
#import "AVFoundation/AVFoundation.h"
#import <ImageIO/ImageIO.h>
@import Firebase;


@interface glimpseScreen ()


//  glimpseScreen.m
//  Runner
//
//  Created by Brett on 8/13/18.
//  Copyright © 2018 The Chromium Authors. All rights reserved.
//





@property (nonatomic,strong) UIButton *editBtn;
@property (nonatomic,strong) UIButton *sendBtn;
@property (nonatomic,strong) UIView * sendBtnBackdrop;
@property (nonatomic,strong) UIView * editBtnBackdrop;
@property (nonatomic,strong) UIButton *sendGlimpseBtn;
@property (nonatomic,strong) UIButton *xButton;
@property (nonatomic,strong) UIImageView *preview;
@property (nonatomic,strong) UIImage *previewImage;
@property (nonatomic,strong) UIImage *edittedImage;
@property (nonatomic,strong) UIView * textView;
@property (nonatomic,strong) UITextField * msgTextfield;
@property (nonatomic,strong) UIView * confirmGlimpse;
@property (nonatomic) UIImageView * profilePic;
@property (nonatomic) UIView * slideBar;
@property (nonatomic) UIView * slideBubble;
@property (nonatomic) UILabel * slideValTxt;
@property (strong, nonatomic) FIRDatabaseReference *ref;
@property (nonatomic,strong) UIActivityIndicatorView *loadingCircle;
@property (nonatomic,strong) UIButton *cameraBtn;
@property (strong, nonatomic)  UIButton *libraryGlimpseBtn;
@property (strong, nonatomic) UIImagePickerController* imagePicker;
@property (strong, nonatomic) AVCaptureSession *session;
@property (strong, nonatomic) AVCapturePhotoOutput *stillImageOutput;
@property ( nonatomic) bool camSetup;




// Check if image access is authorized

@end

@implementation glimpseScreen


- (instancetype)initWithResult:(FlutterResult )result recipient:(NSString *)recip sender:(NSString *)sender convoId:(NSString *)convoId name:(NSString *)fullName imgURL:(NSString *)imgURL{
    self = [super init];
    if (self) {
        _flutterRes = result;
        _convoId = convoId;
        _sender = sender;
        _recip = recip;
        _imgURL = imgURL;
        _fullName = fullName;
    }
    return self;
}

int slideval = 10.0;
bool confirmGlimpseShowing = false;
bool cameraFacingFront = false;
bool loading = false;

CGPoint textViewStartPoint;




- (void)viewDidLoad {
    [super viewDidLoad];
    [[FIRAuth auth] signInAnonymouslyWithCompletion:^(FIRAuthDataResult * _Nullable authResult,
                                                      NSError * _Nullable error) {
        // ...
    }];

    
    self.ref = [[FIRDatabase database] reference];
    
    _imagePicker = [[UIImagePickerController alloc]init];
    _imagePicker.delegate = self;

    [self addTakePhotoBtn];
    [self addFlipCameraBtn];
    [self addPhotoLibraryBtn];
    [self addBackBtn];
    [self showPicPreview];
    [self performSelectorInBackground:@selector(loadImage) withObject:nil];
    self.slideValTxt.text = @"10s";
    textViewStartPoint = CGPointMake(self.view.frame.size.width/2, 0.0);
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChange:) name:UIKeyboardWillChangeFrameNotification object:nil];
    
}

-(void) viewWillAppear:(BOOL)animated {
    
    if(!_camSetup){
        [self setupCam];
        _camSetup = true;
        

    }
}


-(void)setupCam{
    _session = [[AVCaptureSession alloc]init];
    [_session setSessionPreset:AVCaptureSessionPresetPhoto];
    AVCaptureDevice * inputDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error;
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:inputDevice error:&error];
    if([_session canAddInput:deviceInput]){
        [_session addInput:deviceInput];
    }
    AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:_session];
    [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    CALayer * rootLayer = [[self view] layer];
    [rootLayer setMasksToBounds:YES];
    CGRect frame = self.view.frame;
    [previewLayer setFrame:frame];
    [rootLayer insertSublayer:previewLayer atIndex:0];
    _stillImageOutput = [[AVCapturePhotoOutput alloc]init];
    [_session addOutput:_stillImageOutput];
    [_session startRunning];
}



-(void) addTakePhotoBtn{
    _cameraBtn = [[UIButton alloc] init];
    _cameraBtn.backgroundColor = [UIColor clearColor];
    _cameraBtn.layer.cornerRadius = 25.0;
    _cameraBtn.layer.borderWidth = 3.0;
    _cameraBtn.layer.borderColor = [UIColor whiteColor].CGColor;
    _cameraBtn.translatesAutoresizingMaskIntoConstraints = false;
    [self.view addSubview:_cameraBtn];
    //Trailing
    NSLayoutConstraint *centerx =[NSLayoutConstraint
                                  constraintWithItem:_cameraBtn
                                  attribute:NSLayoutAttributeCenterX
                                  relatedBy:NSLayoutRelationEqual
                                  toItem:self.view
                                  attribute:NSLayoutAttributeCenterX
                                  multiplier:1.0f
                                  constant:0.f];
    
    NSLayoutConstraint *height = [NSLayoutConstraint
                                  constraintWithItem:_cameraBtn
                                  attribute:NSLayoutAttributeHeight
                                  relatedBy:NSLayoutRelationEqual
                                  toItem:nil
                                  attribute:NSLayoutAttributeNotAnAttribute
                                  multiplier:0
                                  constant:50.0];
    
    NSLayoutConstraint *width = [NSLayoutConstraint
                                 constraintWithItem:_cameraBtn
                                 attribute:NSLayoutAttributeWidth
                                 relatedBy:NSLayoutRelationEqual
                                 toItem:nil
                                 attribute:NSLayoutAttributeNotAnAttribute
                                 multiplier:0
                                 constant:50.0];
    
    NSLayoutConstraint *bottomPadding = [NSLayoutConstraint
                                         constraintWithItem:_cameraBtn
                                         attribute:NSLayoutAttributeBottom
                                         relatedBy:NSLayoutRelationEqual
                                         toItem:self.view
                                         attribute:NSLayoutAttributeBottom
                                         multiplier:1.0f
                                         constant:-50.0];
    
    //Add constraints to the Parent
    [self.view addConstraint:centerx];
    [self.view addConstraint:bottomPadding];
    //Add height constraint to the subview, as subview owns it.
    [_cameraBtn addConstraint:height];
    [_cameraBtn addConstraint:width];
    [_cameraBtn addTarget:self action:@selector(takePicture) forControlEvents:UIControlEventTouchUpInside];
    
}




-(void) showPicPreview{
    
    self.preview = [[UIImageView alloc]init];
    [self.preview setUserInteractionEnabled:true];
    
    [self.preview setImage:self.previewImage];
    [self.preview setContentMode:UIViewContentModeScaleAspectFill];
    self.preview.translatesAutoresizingMaskIntoConstraints = false;
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(previewTapped:)];
    [self.preview addGestureRecognizer:tapRecognizer];
    [self.view addSubview:self.preview];
    
    
    NSLayoutConstraint *centerx =[NSLayoutConstraint constraintWithItem:self.preview attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view
                                                              attribute:NSLayoutAttributeCenterX multiplier:1.0f constant:0.f];
    NSLayoutConstraint *centery =[NSLayoutConstraint constraintWithItem:self.preview attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1.0f constant:0.f];
    NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:self.preview attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.view attribute:NSLayoutAttributeHeight multiplier:1.0 constant:1.0];
    NSLayoutConstraint *width = [NSLayoutConstraint  constraintWithItem:self.preview attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.view attribute:NSLayoutAttributeWidth  multiplier:1.0 constant:0.f];
    
    [self.view addConstraint:centerx];
    [self.view addConstraint:centery];
    [self.view addConstraint:width];
    [self.view addConstraint:height];
    
    [self addXBtn];
    [self addSendBtn];
    [self addEditBtn];
    
    [self.preview setHidden:YES];
}


///////// buttons for preview

-(void) addXBtn{
    _xButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_xButton addTarget:self action:@selector(handleXBtnTap) forControlEvents:UIControlEventTouchUpInside];
    [_xButton setImage:[UIImage imageNamed:@"close"] forState:UIControlStateNormal];
    _xButton.frame = CGRectMake(30.0, 60.0, 35.0, 35.0);
    [self.preview addSubview:_xButton];
}


-(void) addFlipCameraBtn{
    
    _cameraBtn = [[UIButton alloc] init];
    
    _cameraBtn.frame = CGRectMake((self.view.frame.size.width - 60.0), 60.0, 30.0, 30.0);
    [_cameraBtn setImage:[UIImage imageNamed:@"switchCamera"] forState:UIControlStateNormal];
    [_cameraBtn addTarget:self action:@selector(switchCameraTapped) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:_cameraBtn];
    
}

-(void) addSendBtn{
    _sendBtnBackdrop = [UIView new];
    [_sendBtnBackdrop setUserInteractionEnabled:true];
    _sendBtnBackdrop.backgroundColor = [UIColor yellowColor];
    _sendBtnBackdrop.layer.cornerRadius = 20.0;
    _sendBtnBackdrop.frame = CGRectMake((self.view.frame.size.width - 60.0), (self.view.frame.size.height - 95.0), 40.0, 40.0);
    [self.preview addSubview:_sendBtnBackdrop];
    

    
    _sendBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _sendBtn.frame = CGRectMake((self.view.frame.size.width - 47.5), (self.view.frame.size.height - 85), 20.0, 20.0);
    [_sendBtn setImage:[UIImage imageNamed:@"sendblack"] forState:UIControlStateNormal];
    [_sendBtn addTarget:self action:@selector(handleSendBtnTap) forControlEvents:UIControlEventTouchUpInside];
    [self.preview addSubview:_sendBtn];
}


-(void) addEditBtn{
    
    _editBtnBackdrop = [UIView new];
    [_editBtnBackdrop setUserInteractionEnabled:true];
    _editBtnBackdrop.backgroundColor = [UIColor yellowColor];
    _editBtnBackdrop.layer.cornerRadius = 20.0;
    _editBtnBackdrop.frame = CGRectMake((self.view.frame.size.width - 60.0), (self.view.frame.size.height - 150.0), 40.0, 40.0);
    [self.preview addSubview:_editBtnBackdrop];
    
    self.editBtn = [[UIButton alloc] init];
    [self.editBtn setUserInteractionEnabled:YES];
    self.editBtn.frame = CGRectMake((self.view.frame.size.width - 50.0), (self.view.frame.size.height - 140.0), 20.0, 20.0);
    [self.editBtn setImage:[UIImage imageNamed:@"text"] forState:UIControlStateNormal];
    [self.editBtn addTarget:self action:@selector(handleEditBtnTap) forControlEvents:UIControlEventTouchUpInside];
    [self.preview addSubview:self.editBtn];
}


-(void) addBackBtn{
    UIButton * backBtn = [[UIButton alloc] init];
    [backBtn setUserInteractionEnabled:YES];
    backBtn.frame = CGRectMake(30.0, (self.view.frame.size.height - 80.0), 40.0, 40.0);
    [backBtn setImage:[UIImage imageNamed:@"back"] forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(handleBackBtnTap) forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:backBtn];
}

-(void) addPhotoLibraryBtn{
    //(self.view.frame.size.width - 60.0), (self.view.frame.size.height - 95.0)
    _libraryGlimpseBtn = [[UIButton alloc] init];
    [_libraryGlimpseBtn setUserInteractionEnabled:YES];
    _libraryGlimpseBtn.frame = CGRectMake((self.view.frame.size.width - 70.0), (self.view.frame.size.height - 90.0), 40.0, 40.0);
    [_libraryGlimpseBtn setImage:[UIImage imageNamed:@"addPhoto"] forState:UIControlStateNormal];
    [_libraryGlimpseBtn addTarget:self action:@selector(showImagePicker) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:_libraryGlimpseBtn];
}



//////////////////// preview methods
-(void)previewTapped:(UITapGestureRecognizer*)sender {
    if([self.confirmGlimpse isDescendantOfView:self.view]){
        [self addXBtn];
        [self addSendBtn];
        [self addEditBtn];
        [_textView setUserInteractionEnabled:true];
        
        [self.confirmGlimpse removeFromSuperview];
        return;
    }
    
    if(![self.textView isDescendantOfView:self.preview]){
        [self.msgTextfield setTextAlignment:NSTextAlignmentLeft];
        [self addTextView];
    }else{
        // dismiss texview
        [self.msgTextfield resignFirstResponder];
    }
}

-(void) handleEditBtnTap{
    if(![self.textView isDescendantOfView:self.preview]){
        [self addTextView];
    }else{
        [self.textView removeFromSuperview];
    }
}

-(void)handleXBtnTap{
    [self.textView removeFromSuperview];
    [self.preview setHidden:YES];
    
}

-(void)handleBackBtnTap{
    // dismiss view
    [self dismissViewControllerAnimated:false completion:nil];

}



-(void) handleSendBtnTap{
    [self showConfirmGlimpseScreen];
}

/////textfield stuff

-(void)addTextView{
    self.textView = [[UIView alloc]init];
    self.textView.backgroundColor = [UIColor yellowColor];
    [self.preview addSubview:self.textView];
    self.textView.frame = CGRectMake(0.0, (self.view.frame.size.height/2), self.view.frame.size.width, 40.0);
    self.textView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7f];
    
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveTextView:)];
    [panRecognizer setMinimumNumberOfTouches:1];
    // [panRecognizer setMaximumNumberOfTouches:1];
    [self.textView addGestureRecognizer:panRecognizer];
    
    // add textfield to textview
    self.msgTextfield = [[UITextField alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 40.0)];
    [self.msgTextfield becomeFirstResponder];
    [self.msgTextfield setTextColor:[UIColor whiteColor]];
    self.msgTextfield.delegate = self;
    [self.msgTextfield setReturnKeyType:UIReturnKeyDone];
    [self.textView addSubview:self.msgTextfield];
}
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}
- (void)textFieldDidEndEditing:(UITextField *)textField
                        reason:(UITextFieldDidEndEditingReason)reason{
    [self.msgTextfield setTextAlignment:NSTextAlignmentCenter];
    if([self.msgTextfield.text isEqualToString:@""]){
        
        [self.textView removeFromSuperview];
    }
    
}
- (void)textFieldDidBeginEditing:(UITextField *)textField{
    
    NSLog(@"%f -- @%f",self.textView.center.y, (self.view.frame.size.height/2));
    
    [self.msgTextfield setTextAlignment:NSTextAlignmentLeft];
    
}

- (void)keyboardWillChange:(NSNotification *)notification {
    CGRect keyboardRect = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardRect = [self.view convertRect:keyboardRect fromView:nil];
    
    if((self.view.frame.size.height - _textView.frame.origin.y) < (keyboardRect.size.height + 30)){
        self.textView.frame = CGRectMake(0.0, (self.view.frame.size.height - (keyboardRect.size.height - _textView.frame.size.height/2) -70),_textView.frame.size.width, _textView.frame.size.height);
    }
    
}


-(void)moveTextView:(UIPanGestureRecognizer*)sender {
    //  disclaimer i did not write this, but i had the intelligence required to modify it, so that's worth something right?
    
    [self.view bringSubviewToFront:sender.view];
    CGPoint translatedPoint = [sender translationInView:sender.view.superview];
    
    translatedPoint = CGPointMake(sender.view.center.x, sender.view.center.y+translatedPoint.y);
    
    [sender.view setCenter:translatedPoint];
    [sender setTranslation:CGPointZero inView:sender.view];
    
    if (sender.state == UIGestureRecognizerStateEnded) {
        CGFloat velocityX = (0.2*[sender velocityInView:self.view].x);
        CGFloat finalX = self.view.frame.size.width/2;
        CGFloat finalY = translatedPoint.y;// translatedPoint.y + (.35*[(UIPanGestureRecognizer*)sender velocityInView:self.view].y);
        
        if (finalX < 0) {
            finalX = 0;
        } else if (finalX > self.view.frame.size.width) {
            finalX = self.view.frame.size.width;
        }
        
        if (finalY < 50) { // to avoid status bar
            finalY = 50;
        } else if (finalY > self.view.frame.size.height) {
            finalY = self.view.frame.size.height;
        }
        
        CGFloat animationDuration = (ABS(velocityX)*.0002)+.2;
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:animationDuration];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(animationDidFinish)];
        [[sender view] setCenter:CGPointMake(finalX, finalY)];
        [UIView commitAnimations];
    }
}

-(void) takePicture{
    NSDictionary *outputSettings = [[NSDictionary alloc]initWithObjectsAndKeys:AVVideoCodecTypeJPEG, AVVideoCodecKey, nil];
    AVCapturePhotoSettings * settins = [AVCapturePhotoSettings photoSettings];
    [_stillImageOutput capturePhotoWithSettings:settins delegate:self];
}



-(void)switchCameraTapped
{
    //Change camera source
    if(_session)
    {
        //Indicate that some changes will be made to the session
        [_session beginConfiguration];
        //Remove existing input
        AVCaptureInput* currentCameraInput = [_session.inputs objectAtIndex:0];
        [_session removeInput:currentCameraInput];
        //Get new input
        AVCaptureDevice *newCamera = nil;
        if(((AVCaptureDeviceInput*)currentCameraInput).device.position == AVCaptureDevicePositionBack)
        {
            newCamera = [self cameraWithPosition:AVCaptureDevicePositionFront];
            cameraFacingFront = true;
        }
        else
        {
            newCamera = [self cameraWithPosition:AVCaptureDevicePositionBack];
            cameraFacingFront = false;
            
        }
        //Add input to session
        NSError *err = nil;
        AVCaptureDeviceInput *newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:newCamera error:&err];
        if(!newVideoInput || err)
        {
            NSLog(@"Error creating capture device input: %@", err.localizedDescription);
        }
        else
        {
            [_session addInput:newVideoInput];
        }
        //Commit all the configuration changes at once
        [_session commitConfiguration];
    }
}

// Find a camera with the specified AVCaptureDevicePosition, returning nil if one is not found


- (AVCaptureDevice *) cameraWithPosition:(AVCaptureDevicePosition) position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices)
    {
        if ([device position] == position) return device;
    }
    return nil;
}


/// confirm Glimpse


-(void) showConfirmGlimpseScreen{
    [_sendBtnBackdrop removeFromSuperview];
    [_editBtnBackdrop removeFromSuperview];
    
    [_sendBtn removeFromSuperview];
    [_editBtn removeFromSuperview];
    [_xButton removeFromSuperview];
    [_textView setUserInteractionEnabled:false];
    
    _edittedImage = [self screenshot];
    
    
    self.confirmGlimpse = [[UIView alloc]init];
    [self.confirmGlimpse setUserInteractionEnabled:true];
    self.confirmGlimpse.backgroundColor = [UIColor whiteColor];
    self.confirmGlimpse.layer.cornerRadius = 15.0;
    [self.view addSubview:self.confirmGlimpse];
    
    self.confirmGlimpse.frame = CGRectMake(0.0, (self.view.frame.size.height/2 - 75.0),(self.view.frame.size.width - 30.0), 120.0);
    self.confirmGlimpse.center = self.view.center;
    
    // add profile pic
    self.profilePic.frame = CGRectMake(15.0, 15.0, 50.0, 50.0);
    self.profilePic.layer.cornerRadius = 25.0;
    self.profilePic.layer.masksToBounds = true;
    [self.confirmGlimpse addSubview:self.profilePic];
    
    // add the name
    UILabel * name = [[UILabel alloc]init];
    name.adjustsFontSizeToFitWidth = YES;
    name.text = _fullName;
    [name setBackgroundColor:[UIColor clearColor]];
    [name setFont:[UIFont boldSystemFontOfSize:16]];
    name.frame = CGRectMake(70.0, 25.0, 130.0, 30.0);
    [self.confirmGlimpse addSubview:name];
    
    _sendGlimpseBtn = [[UIButton alloc]init];
    [_sendGlimpseBtn setBackgroundColor:[UIColor yellowColor]];
    _sendGlimpseBtn.frame = CGRectMake(203.0, 25.0, (self.view.frame.size.width - 265.5), 50.0);
    _sendGlimpseBtn.layer.cornerRadius = 8.0;
    _sendGlimpseBtn.layer.shadowRadius  = 15.0;
    _sendGlimpseBtn.layer.shadowColor   = [UIColor colorWithRed:176.f/255.f green:199.f/255.f blue:226.f/255.f alpha:1.f].CGColor;
    _sendGlimpseBtn.layer.shadowOffset  = CGSizeMake(0.0f, 0.0f);
    _sendGlimpseBtn.layer.shadowOpacity = 0.9f;
    _sendGlimpseBtn.layer.masksToBounds = NO;
    
    UIEdgeInsets shadowInsets = UIEdgeInsetsMake(0, 0, -1.5f, 0);
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:UIEdgeInsetsInsetRect(_sendGlimpseBtn.bounds, shadowInsets)];
    _sendGlimpseBtn.layer.shadowPath    = shadowPath.CGPath;
    [_sendGlimpseBtn setTitle:@"Send" forState:UIControlStateNormal];
    [_sendGlimpseBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_sendGlimpseBtn.titleLabel setFont:[UIFont boldSystemFontOfSize:17.f]];
    [_sendGlimpseBtn addTarget:self action:@selector(uploadImg) forControlEvents:UIControlEventTouchUpInside];
    [self.confirmGlimpse addSubview:_sendGlimpseBtn];
    
    
    
    [self addSlideBar];
}





-(void) addSlideBar{
    //slidebubble track line
    
    UIView * track = [[UIView alloc]init];
    track.frame = CGRectMake(20.0, 100.0, 220.0, 2.0);
    track.backgroundColor = [UIColor blackColor];
    [self.confirmGlimpse addSubview:track];
    
    // slidebar frame
    UIView * slideBar = [[UIView alloc]init];
    slideBar.frame = CGRectMake(10.0, 65.0, 240.0, 70.0);
    slideBar.backgroundColor = [UIColor clearColor];
    [self.confirmGlimpse addSubview:slideBar];
    
    //slide val txt
    _slideValTxt = [[UILabel alloc]init];
    _slideValTxt.text = @"10s";
    [_slideValTxt setBackgroundColor:[UIColor clearColor]];
    [_slideValTxt setFont:[UIFont boldSystemFontOfSize:16]];
    [_slideValTxt setTextAlignment:NSTextAlignmentCenter];
    _slideValTxt.frame = CGRectMake(237.0,83.0, 50.0, 40.0);
    [self.confirmGlimpse addSubview:_slideValTxt];
    
    
    // slideBubble
    self.slideBubble = [[UIView alloc]init];
    self.slideBubble.frame = CGRectMake(200.0, 24.0, 22.0, 22.0);
    self.slideBubble.backgroundColor = [UIColor yellowColor];
    self.slideBubble.layer.cornerRadius = 11.0;
    [slideBar addSubview:self.slideBubble];
    // gesture recognizer for slide bubble
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveSlideBubble:)];
    [panRecognizer setMinimumNumberOfTouches:1];
    // [panRecognizer setMaximumNumberOfTouches:1];
    [self.slideBubble addGestureRecognizer:panRecognizer];
    
}




-(void)moveSlideBubble:(UIPanGestureRecognizer*)sender {
    [self.view bringSubviewToFront:sender.view];
    CGPoint translatedPoint = [sender translationInView:sender.view.superview];
    translatedPoint = CGPointMake(sender.view.center.x+translatedPoint.x, sender.view.center.y);
    slideval = (int)translatedPoint.x/20;
    if(slideval >= 11){
        self.slideValTxt.text = @"100s";
    }else{
        if(slideval < 0){
            _slideValTxt.text = @"0s";
        }else{
            _slideValTxt.text = [NSString stringWithFormat:@"%@%@", [[NSNumber numberWithInt:slideval] stringValue],@"s"];
        }
    }
    
    [sender.view setCenter:translatedPoint];
    [sender setTranslation:CGPointZero inView:sender.view];
    if (sender.state == UIGestureRecognizerStateEnded) {
        CGFloat velocityX = (0.2*[sender velocityInView:self.view].x);
        CGFloat finalX = translatedPoint.x + velocityX/3;
        slideval = (int)finalX/20;
        double slidevalComp = (double)finalX/20;
        if(slidevalComp > 10.9){
            self.slideValTxt.text = @"100s";
        }else{
            if(slidevalComp <0.0){
                _slideValTxt.text = @"0s";
            }else{
                _slideValTxt.text = [NSString stringWithFormat:@"%@%@", [[NSNumber numberWithInt:slideval] stringValue],@"s"];
            }
        }
        CGFloat finalY = sender.view.center.y;
        if (finalX < 0) {
            finalX = 20.0;
        } else if (slidevalComp > 10.9) {
            finalX = 220.0;
        }
        CGFloat animationDuration = (ABS(velocityX)*.0002)+.2;
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:animationDuration];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        [UIView setAnimationDelegate:self];
        [[sender view] setCenter:CGPointMake(finalX, finalY)];
        [UIView commitAnimations];
    }
}



- (void)loadImage
{
    NSURL * url = [NSURL URLWithString:_imgURL];
    NSData * data = [NSData dataWithContentsOfURL:url];
    UIImage * image = [UIImage imageWithData:data];
    if (image)
    {
        self.profilePic = [[UIImageView alloc]init];
        self.profilePic.image = image;
    }
    else
    {
        
        
    }
}

-(void) uploadImg{
    // generate current timestamp
    
    [_sendGlimpseBtn removeFromSuperview];
    _loadingCircle = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [_loadingCircle startAnimating];
   // 203.0, 25.0, (self.view.frame.size.width - 265.5), 50.0
    _loadingCircle.frame = CGRectMake(((self.view.frame.size.width - 265.5) + 101.5 - 10.0), 15.0, (self.view.frame.size.width - 265.5), 50.0);
    [_confirmGlimpse addSubview:_loadingCircle];
    

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd hh:mm:ss a"];
    NSString *currentTime = [dateFormatter stringFromDate:[NSDate date]];
    // Data in memory
     NSData *data = UIImageJPEGRepresentation(_edittedImage,0.8);
    FIRStorageReference *storageRef = [[FIRStorage storage] reference];
    
    NSString * key = [[NSString alloc]initWithString:[[_ref childByAutoId]key]];
    NSMutableString * path = [[NSMutableString alloc]initWithString:@"glimpses/"];
    [path appendString:key];
    FIRStorageReference *riversRef = [storageRef child:path];
    FIRStorageUploadTask *uploadTask = [riversRef putData:data
                                                 metadata:nil
                                               completion:^(FIRStorageMetadata *metadata,
                                                            NSError *error) {
                                                   if (error != nil) {
                                                       // Uh-oh, an error occurred!
                                                       [_loadingCircle removeFromSuperview];
                                                       // display error
                                                   } else {
                                                       // Metadata contains file metadata such as size, content-type, and download URL.
                                                       int size = metadata.size;
                                                       // You can also access to download URL after upload.
                                                       [riversRef downloadURLWithCompletion:^(NSURL * _Nullable URL, NSError * _Nullable error) {
                                                           if (error != nil) {
                                                               // Uh-oh, an error occurred!
                                                               [_loadingCircle removeFromSuperview];
                                                               // display error

                                                           } else {
                            
                                                               NSString * url = [[NSString alloc]initWithString:URL.absoluteString];
                                                               int duration = slideval;
                                                               if(duration > 10){
                                                                   duration = 100;
                                                               }
                                                               _flutterRes(url);
                                                               NSDictionary * glimpse = @{@"url":url, @"duration":[NSNumber numberWithInt:duration],@"from":_sender,@"to":_recip,@"type":@"glimpse",@"formattedTime":currentTime, @"viewed":@NO};
                                                               
                                                               [[[[self.ref child:@"convos"] child:_convoId] child:[[_ref childByAutoId] key]]
                                                                setValue:glimpse];
                                                        
                                                               [_loadingCircle removeFromSuperview];
                                                               [self dismissViewControllerAnimated:false completion:nil];
                                                           }
                                                       }];
                                                   }
                                               }];
                                            }

- (UIImage *)screenshot
{
    UIGraphicsBeginImageContextWithOptions(self.view.frame.size, NO, 2.0f);
    [self.view drawViewHierarchyInRect:self.view.bounds afterScreenUpdates:YES];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}



-(void) showImagePicker{
  
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        _imagePicker.modalPresentationStyle = UIModalPresentationCurrentContext;
        _imagePicker.delegate = self;
        _imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;



   

        // Use delegate methods to get result of photo library -- Look up UIImagePicker delegate methods
        
        [self presentViewController:_imagePicker animated:true completion:nil];
}
    
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
 
    [_imagePicker dismissViewControllerAnimated:true completion:nil];
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    self.previewImage = [[UIImage alloc]init];
    [self.preview setImage:image];
    [self.preview setHidden:false];


}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [_imagePicker dismissViewControllerAnimated:YES completion:nil];
    

}


#pragma mark - AVCapturePhotoCaptureDelegate
-(void)captureOutput:(AVCapturePhotoOutput *)captureOutput didFinishProcessingPhotoSampleBuffer:(CMSampleBufferRef)photoSampleBuffer previewPhotoSampleBuffer:(CMSampleBufferRef)previewPhotoSampleBuffer resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings bracketSettings:(AVCaptureBracketedStillImageSettings *)bracketSettings error:(NSError *)error
{
    if (error) {
        NSLog(@"error : %@", error.localizedDescription);
    }
    
    if (photoSampleBuffer) {
        NSData *data = [AVCapturePhotoOutput JPEGPhotoDataRepresentationForJPEGSampleBuffer:photoSampleBuffer previewPhotoSampleBuffer:previewPhotoSampleBuffer];
        UIImage *image = [UIImage imageWithData:data];
        if(cameraFacingFront){
            UIImage * flippedImage = [UIImage imageWithCGImage:image.CGImage scale:image.scale orientation:UIImageOrientationLeftMirrored];
            self.previewImage = [[UIImage alloc]init];
            [self.preview setImage:flippedImage];
            [self.preview setHidden:false];
        }else{
            self.previewImage = [[UIImage alloc]init];
            [self.preview setImage:image];
            [self.preview setHidden:false];
        }
    }
    
    
}








@end

