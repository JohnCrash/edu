/****************************************************************************
 Copyright (c) 2013      cocos2d-x.org
 Copyright (c) 2013-2014 Chukong Technologies Inc.

 http://www.cocos2d-x.org

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 ****************************************************************************/

#import "RootViewController.h"
#import "cocos2d.h"
#import "CCEAGLView.h"
#import "staticlib.h"
#import "parsparam.h"
#import "Platform.h"

#ifdef _BAIDU_VOICE_
#import "baidu/BDRecognizerViewController.h"
#import "baidu/BDVRSConfig.h"

#define API_KEY @"1hiGONxNPY4GEYg7Dwj19L3w"
#define SECRET_KEY @"iXqgeznUL17nv3j8XRZCGyIkpTTeyYoO"
#endif

UsingMySpace;

@implementation RootViewController_v3

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}

 
*/

/*
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    
}
*/
- (void)closeBaiduVoice
{
    [_recognizerViewController cancel];
}
- (void)showBaiduVoice
{
    CGPoint pt = [self.view center];
    pt.x -= 128;
    pt.y -= 116;
    BDRecognizerViewController *tmpRecognizerViewController = [[BDRecognizerViewController alloc] initWithOrigin:pt withTheme:[BDVRSConfig sharedInstance].theme];
    
    // 全屏UI
    //if ([[BDVRSConfig sharedInstance].theme.name isEqualToString:@"全屏亮蓝"]) {
    //    tmpRecognizerViewController.enableFullScreenMode = YES;
    //}
    tmpRecognizerViewController.enableFullScreenMode = NO;
    
    tmpRecognizerViewController.delegate = self;
    self.recognizerViewController = tmpRecognizerViewController;
    [tmpRecognizerViewController release];
    
    // 设置识别参数
    BDRecognizerViewParamsObject *paramsObject = [[BDRecognizerViewParamsObject alloc] init];
    
    // 开发者信息，必须修改API_KEY和SECRET_KEY为在百度开发者平台申请得到的值，否则示例不能工作
    paramsObject.apiKey = API_KEY;
    paramsObject.secretKey = SECRET_KEY;
    
    // 设置是否需要语义理解，只在搜索模式有效
    paramsObject.isNeedNLU = [BDVRSConfig sharedInstance].isNeedNLU;
    
    // 设置识别语言
    paramsObject.language = (TBDVoiceRecognitionLanguage)[BDVRSConfig sharedInstance].recognitionLanguage;
    
    // 设置识别模式，分为搜索和输入
    paramsObject.recogPropList = @[[BDVRSConfig sharedInstance].recognitionProperty];
    
    // 设置城市ID，当识别属性包含EVoiceRecognitionPropertyMap时有效
    paramsObject.cityID = 1;
    
    // 开启联系人识别
    //    paramsObject.enableContacts = YES;
    
    // 设置显示效果，是否开启连续上屏
    if ([BDVRSConfig sharedInstance].resultContinuousShow)
    {
        paramsObject.resultShowMode = BDRecognizerResultShowModeContinuousShow;
    }
    else
    {
        paramsObject.resultShowMode = BDRecognizerResultShowModeWholeShow;
    }
    
    // 设置提示音开关，是否打开，默认打开
    if ([BDVRSConfig sharedInstance].uiHintMusicSwitch)
    {
        paramsObject.recordPlayTones = EBDRecognizerPlayTonesRecordPlay;
    }
    else
    {
        paramsObject.recordPlayTones = EBDRecognizerPlayTonesRecordForbidden;
    }
    
    paramsObject.isShowTipAfter3sSilence = NO;
    paramsObject.isShowHelpButtonWhenSilence = NO;
    //    paramsObject.tipsTitle = @"可以使用如下指令记账";
    //    paramsObject.tipsList = [NSArray arrayWithObjects:@"我要记账", @"买苹果花了十块钱", @"买牛奶五块钱", @"第四行滚动后可见", @"第五行是最后一行", nil];
    
    [_recognizerViewController startWithParams:paramsObject];
    
    [paramsObject release];
}

#ifdef _BAIDU_VOICE_
#pragma mark - BDRecognizerViewDelegate
- (void)onEndWithViews:(BDRecognizerViewController *)aBDRecognizerView withResults:(NSArray *)aResults
{
    if ([[BDVoiceRecognitionClient sharedInstance] getRecognitionProperty] != EVoiceRecognitionPropertyInput)
    {
        // 搜索模式下的结果为数组，示例为
        // ["公园", "公元"]
        NSMutableArray *audioResultData = (NSMutableArray *)aResults;
        NSMutableString *tmpString = [[NSMutableString alloc] initWithString:@""];

        for (int i=0; i < [audioResultData count]; i++)
        {
            [tmpString appendFormat:@"%@\r\n",[audioResultData objectAtIndex:i]];
        }

        //_resultView.text = [_resultView.text stringByAppendingString:tmpString];
        //_resultView.text = [_resultView.text stringByAppendingString:@"\n"];
        std::string result;
        result = [[audioResultData objectAtIndex:0] cStringUsingEncoding:NSUTF8StringEncoding];
        baiduVoiceResult(result);
        [tmpString release];
        }
    else
    {
        // 输入模式下的结果为带置信度的结果，示例如下：
        //  [
        //      [
        //         {
        //             "百度" = "0.6055192947387695";
        //         },
        //         {
        //             "摆渡" = "0.3625582158565521";
        //         },
        //      ]
        //      [
        //         {
        //             "一下" = "0.7665404081344604";
        //         }
        //      ],
        //   ]
        NSString *tmpString = [[BDVRSConfig sharedInstance] composeInputModeResult:aResults];
        std::string result;
        result = [tmpString cStringUsingEncoding:NSUTF8StringEncoding];
        baiduVoiceResult(result);
        //_resultView.text = [_resultView.text stringByAppendingString:tmpString];
        //_resultView.text = [_resultView.text stringByAppendingString:@"\n"];
    }
}
#endif

// Override to allow orientations other than the default portrait orientation.
// This method is deprecated on ios6
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  //  NSLog(@"statusBarOrientation %d",[[UIApplication sharedApplication] statusBarOrientation]);
  //  NSLog(@"interfaceOrientation %d",interfaceOrientation);
  //  [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
  //  UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
  //  NSLog(@"currentDevice Orientation %d",orientation );
    
    if( g_OrientationMode == 2 )
    {
        if( interfaceOrientation == UIInterfaceOrientationPortrait ||
           interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown )
            return YES;
    }
    else
    {
        if( interfaceOrientation == UIInterfaceOrientationLandscapeLeft ||
            interfaceOrientation == UIInterfaceOrientationLandscapeRight )
            return YES;
    }
    return NO;
//    return UIInterfaceOrientationIsLandscape( interfaceOrientation );
}

// For ios6, use supportedInterfaceOrientations & shouldAutorotate instead
- (NSUInteger) supportedInterfaceOrientations{
 //   [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
 //   UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
 //   NSLog(@"currentDevice Orientation %d",orientation );
#ifdef __IPHONE_6_0
    if( g_OrientationMode == 2 )
    {
        return UIInterfaceOrientationMaskPortrait;
    }
    else
    {
        return UIInterfaceOrientationMaskLandscape;
    }
   // return UIInterfaceOrientationMaskAllButUpsideDown;
#endif
}

- (BOOL) shouldAutorotate {
    if( g_bAutorotate )
        return YES;
    else
        return NO;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];

    cocos2d::GLView *glview = cocos2d::Director::getInstance()->getOpenGLView();

    if (glview)
    {
        CCEAGLView *eaglview = (CCEAGLView*) glview->getEAGLView();

        if (eaglview)
        {
            CGSize s = CGSizeMake([eaglview getWidth], [eaglview getHeight]);
            cocos2d::Application::getInstance()->applicationScreenSizeChanged((int) s.width, (int) s.height);
        }
    }
}

//fix not hide status on ios7
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];

    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [_recognizerViewController release];
    [super dealloc];
}


@end
