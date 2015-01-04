//
//  Edenginev3.m
//  EDEngine
//
//  Created by john on 14/12/31.
//
//
#import "staticlib.h"
#import "Edenginev3.h"
#import "CCEAGLView.h"
#import "cocos2d.h"
#import "AppDelegate.h"
#import "RootViewController.h"

UsingMySpace;

static ONEXIT_t s_onExit = nullptr;

static void onExit()
{
    if( s_onExit )
    {
        //释放脚本引擎
        //LuaEngine *pEngine = LuaEngine::getInstance();
        ScriptEngineManager::getInstance()->setScriptEngine(nullptr);
        s_onExit();
    }
}

#ifdef EmbedCocos2d
static AppDelegate_v3 s_Application;
#endif
//为cocos2d-x 3.2 创建一个eaglview
void* createV3EAGLView(void *window)
{
    CCEAGLView *eaglView = [CCEAGLView viewWithFrame: [(UIWindow*)window bounds]
                                         pixelFormat: kEAGLColorFormatRGB565
                                         depthFormat: GL_DEPTH24_STENCIL8_OES
                                  preserveBackbuffer: NO
                                          sharegroup: nil
                                       multiSampling: NO
                                     numberOfSamples: 0];
    return (void*)eaglView;
}

void *createV3Controller()
{
    return [[RootViewController_v3 alloc] initWithNibName:nil bundle:nil];
}

//启动cocos2d-x 3.2
void runV3Engine( void *eaglview,ONEXIT_t func)
{
    GLView *glview = GLView::createWithEAGLView(eaglview);
    Director::getInstance()->setOpenGLView(glview);
    //当Director调用end退出时调用
    // 定制函数
    s_onExit = func;
    Director::getInstance()->setEndAfterCall(onExit);
    Application::getInstance()->run();
}

void shutdownV3Engine()
{
    
}

void pauseV3Engine()
{
    //cocos2d-x 3.2 do nothing
}

void resumeV3Engine()
{
    //cocos2d-x 3.2 do nothing
}

void backgroundV3Engine()
{
    cocos2d::Application::getInstance()->applicationDidEnterBackground();
}

void foregroundV3Engine()
{
    cocos2d::Application::getInstance()->applicationWillEnterForeground();
}


