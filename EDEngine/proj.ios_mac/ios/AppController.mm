/****************************************************************************
 Copyright (c) 2010 cocos2d-x.org

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

#import "AppController.h"
#import "CCEAGLView.h"
#import "cocos2d.h"
#import "AppDelegate.h"
#import "RootViewController.h"
#import "parsparam.h"
#import "Platform.h"
#import "Reachability.h"
#import "AudioToolbox/AudioToolbox.h"
#import "staticlib.h"

UsingMySpace;

@implementation AppController_v3

#pragma mark -
#pragma mark Application lifecycle

MySpaceBegin
// cocos2d application instance
#ifndef EmbedCocos2d
static AppDelegate_v3 s_sharedApplication;
#endif
extern std::string g_Goback;
extern std::string g_Launch;
static AppController_v3 *s_myAppController = nullptr;

#ifdef _BAIDU_VOICE_
/*
 * 显示百度语音识别对话栏
 */
void showBaiduVoice()
{
    /*
     单独运行的时候使用[s_myAppController.viewController showBaiduVoice]调用
     植入到ljshell中使用下面的调用
     */
    RootViewController_v3 * viewController = (RootViewController_v3*)getCurrentRootViewController();
    if( viewController )
        [viewController showBaiduVoice];
}
/*
 * 强制关闭百度语音识别对话栏
 */
void closeBaiduVoice()
{
    RootViewController_v3 * viewController = (RootViewController_v3*)getCurrentRootViewController();
    if( viewController )
        [viewController closeBaiduVoice];
}

/*
 * 显示百度语音识别配置界面
 */
void showBaiduVoiceConfigure()
{
    
}
#else
void showBaiduVoice(){}
void closeBaiduVoice(){}
void showBaiduVoiceConfigure(){}
#endif

void setUIOrientation( int m )
{
    if( g_OrientationMode != m )
    {
        /*
        long iOSVersion = [[[UIDevice currentDevice] systemVersion] integerValue];
        
         //不能确定iOS在什么版本使用下面代码,实测在iOS7 iPad mini不工作.iOS8.1 iPhone不工作
        if( iOSVersion <8 )
        {
            g_OrientationMode = m;
            g_bAutorotate = false;
            if( m == 2 )
            {
                [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait];
                s_myAppController.viewController.view.transform = CGAffineTransformIdentity;
            }
            else
            {
                [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeRight];
                s_myAppController.viewController.view.transform = CGAffineTransformMakeRotation(M_PI/2);
            }
            g_bAutorotate = true;
            CGRect rect = s_myAppController.viewController.view.bounds;
            s_myAppController.viewController.view.bounds = CGRectMake(0,0,rect.size.height,rect.size.width);
          // [s_myAppController.window setFrame:[[UIScreen mainScreen] bounds]];
        }else */
        {
            g_OrientationMode = m;
            NSNumber *value;
            if( m == 2 )
                value = [NSNumber numberWithInt:UIInterfaceOrientationPortrait];
            else
                value = [NSNumber numberWithInt:UIInterfaceOrientationLandscapeRight];
            [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
        }
        cocos2dChangeOrientation( m );
    }
}

void statusbarOrientation()
{
    NSNumber *value;
    if( g_OrientationMode == 2 )
        value = [NSNumber numberWithInt:UIInterfaceOrientationPortrait];
    else
        value = [NSNumber numberWithInt:UIInterfaceOrientationLandscapeRight];
    [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
}

void setRootControllerOrientation( int m,unsigned int orientation )
{
    g_OrientationMode = m;
    NSNumber *value;
    value = [NSNumber numberWithInt:orientation];
    [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
}

int getUIOrientation()
{
//    NSLog(@"%s",[[[UIDevice currentDevice] systemName] cStringUsingEncoding:NSUTF8StringEncoding]);
//    NSLog(@"%s",[[[UIDevice currentDevice] systemVersion] cStringUsingEncoding:NSUTF8StringEncoding]);
    return g_OrientationMode;
}

int getDeviceOrientation()
{
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    if( orientation == UIDeviceOrientationPortrait||orientation == UIDeviceOrientationPortraitUpsideDown)
    {
        return 2;
    }
    else
    {
        return 1;
    }
    //[[UIApplication sharedApplication] statusBarOrientation];
}

bool platformOpenURL( const char *strurl )
{
    NSURL *url;
    NSString *nsstr = [[NSString alloc] initWithUTF8String:strurl];
    url = [NSURL URLWithString:nsstr];
    [nsstr release];
    if( [[UIApplication sharedApplication] canOpenURL:url])
    {
        [[UIApplication sharedApplication] openURL:url];
        return true;
    }
    return false;
}
/*
 * 震动,ios不支持震动时长和震动模式
 */
void ShockPhoneDelay( int t )
{
    AudioServicesPlaySystemSound ( kSystemSoundID_Vibrate);
}
void ShockPhonePattern( int *pattern,int n )
{
    AudioServicesPlaySystemSound ( kSystemSoundID_Vibrate);
}
/*
 * 取网络状态，没有网络返回0,wifi=1,gprs/3g/4g=2
 * 错误返回-1
 */
int getNetworkState()
{
    int state = [[Reachability reachabilityForLocalWiFi] currentReachabilityStatus];
    if( state != NotReachable )
    {
        if( state == ReachableViaWiFi)
            return 1;
        else if( state == ReachableViaWWAN )
            return 2;
        else
            return 1;
    }
    if( [[Reachability reachabilityForInternetConnection] currentReachabilityStatus] != NotReachable )
        return 2;
    return 0;
}

/*
 * 监听网络状态变化，发生变化调用networkStateChange
 */
bool s_isRegister = false;
void registerNetworkStateListener()
{
    if( s_isRegister )
        return;
    s_isRegister = true;
    //暂时没有实现,将reachabilityChanged移到viewController中实现
    /* 单独启动时使用
    [[NSNotificationCenter defaultCenter] addObserver:s_myAppController
                                             selector:@selector(reachabilityChanged)
                                                 name: kReachabilityChangedNotification
                                               object: nil];
    */
}
void unregisterNetworkStateListener()
{
    if( !s_isRegister )
        return;
    //[[NSNotificationCenter defaultCenter] removeObserver:s_myAppController];
    s_isRegister = false;
}

/*
 *  popup launch app
 */
static void doGoback()
{
    if( !g_Goback.empty() )
    {
        NSURL *url;
        NSString *nsstr;
        nsstr = [NSString stringWithFormat:@"%s://",g_Goback.c_str()];
        url = [NSURL URLWithString:nsstr];
        if( [[UIApplication sharedApplication] canOpenURL:url] )
        {
            [[UIApplication sharedApplication] openURL:url];
        }
        g_Goback = "";
    }
}
static void onexit()
{
    doGoback();
}
/*
 *  switch lua application
 */
static bool requestURL( NSURL *url,bool isrunning )
{
    if( !url )return false;
    
    NSString *surl = [url absoluteString];
    if( surl )
    {
        const char * purl = [surl cStringUsingEncoding:NSUTF8StringEncoding];
        if( purl )
        {
            std::string oldLanuch = g_Launch;
            MySpace::set_launch_by_url( purl);
            if( isrunning && oldLanuch != g_Launch )
            {
                //switch other application,restart
                cocos2d::ScriptEngineManager::getInstance()->setScriptEngine(nullptr);
                cocos2d::Application::getInstance()->run();
            }
            return true;
        }
    }
    return false;
}

MySpaceEnd

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    requestURL( url,true );
    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    

    s_myAppController = self;
    NSURL *url = [launchOptions objectForKey:UIApplicationLaunchOptionsURLKey];
    if( url )
    {
        requestURL( url,false );
    }
    atexit(onexit);
    // Override point for customization after application launch.

    // Add the view controller's view to the window and display.
    window = [[UIWindow alloc] initWithFrame: [[UIScreen mainScreen] bounds]];

    // Init the CCEAGLView
    CCEAGLView *eaglView = [CCEAGLView viewWithFrame: [window bounds]
                                     pixelFormat: kEAGLColorFormatRGB565
                                     depthFormat: GL_DEPTH24_STENCIL8_OES
                              preserveBackbuffer: NO
                                      sharegroup: nil
                                   multiSampling: NO
                                 numberOfSamples: 0];

    [eaglView setMultipleTouchEnabled:YES];
    
    // Use RootViewController manage CCEAGLView
    _viewController = [[RootViewController_v3 alloc] initWithNibName:nil bundle:nil];
    _viewController.wantsFullScreenLayout = YES;
    _viewController.view = eaglView;
    // Set RootViewController to window
    if ( [[UIDevice currentDevice].systemVersion floatValue] < 6.0)
    {
        // warning: addSubView doesn't work on iOS6
        [window addSubview: _viewController.view];
    }
    else
    {
        // use this method on ios6
        [window setRootViewController:_viewController];
    }

    [window makeKeyAndVisible];

    [[UIApplication sharedApplication] setStatusBarHidden:true];

    // IMPORTANT: Setting the GLView should be done after creating the RootViewController
    cocos2d::GLView *glview = cocos2d::GLView::createWithEAGLView(eaglView);
    /*
     如果end被调用就直接退出eixt(0);
     定制函数
    */
    glview->ifEndToExit(true);
    cocos2d::Director::getInstance()->setOpenGLView(glview);
    cocos2d::Director::getInstance()->setEndAfterCall(nullptr);
    cocos2d::Application::getInstance()->run();

    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
     //We don't need to call this method any more. It will interupt user defined game pause&resume logic
    /* cocos2d::Director::getInstance()->pause(); */
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
     //We don't need to call this method any more. It will interupt user defined game pause&resume logic
    /* cocos2d::Director::getInstance()->resume(); */
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
     */
    cocos2d::Application::getInstance()->applicationDidEnterBackground();
    //doGoback();
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
    cocos2d::Application::getInstance()->applicationWillEnterForeground();
}

- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     See also applicationDidEnterBackground:.
     */
}


#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}


- (void)dealloc {
    [window release];
    [super dealloc];
}

- (void)reachabilityChanged:(NSNotification *)note {
    networkStateChange(getNetworkState());
}
@end
