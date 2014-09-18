#include "AppDelegate.h"
#include "HelloWorldScene.h"
#include "SimpleAudioEngine.h"
#include "lua_ext.h"
#include "lua_ljshell.h"
#include "luaDebug.h"
#include "AssetsManager.h"

#if CC_TARGET_PLATFORM == CC_PLATFORM_MAC||CC_TARGET_PLATFORM == CC_PLATFORM_IOS
#include "AppleBundle.h"
#endif

AppDelegate::AppDelegate()
{

}

AppDelegate::~AppDelegate() 
{
	//releaseInternalLuaEngine();
}

bool AppDelegate::applicationDidFinishLaunching() 
{
    // initialize director
    auto director = Director::getInstance();
    auto glview = director->getOpenGLView();
    if(!glview) {
		glview = GLView::create("EDEngine");
        director->setOpenGLView(glview);
    }

#ifdef USE_WIN32_CONSOLE
    // turn on display FPS
    //director->setDisplayStats(true);
#endif
    // set FPS. the default value is 1.0/60 if you don't call this
    director->setAnimationInterval(1.0 / 60);
	
#ifdef USE_WIN32_CONSOLE
	registerHotkey();
#endif

	initLuaEngine();

    return true;
}

void AppDelegate::initLuaEngine()
{
	auto director = Director::getInstance();
	auto glview = director->getOpenGLView();
#if CC_TARGET_PLATFORM == CC_PLATFORM_WIN32	|| CC_TARGET_PLATFORM == CC_PLATFORM_MAC
	glview->setFrameSize(1024,576);
	//glview->setFrameSize(1920,1080);
#endif	
    auto screenSize = glview->getFrameSize();
    
	auto pFileUtils = FileUtils::getInstance();

#if CC_TARGET_PLATFORM == CC_PLATFORM_WIN32
	InitForDebugMode();
#endif

#if CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID
	Director::getInstance()->getConsole()->listenOnTCP(5678);
#endif
    //auto designSize = Size(480, 320);
	//auto designSize = Size(960, 640);
    auto designSize = Size(1024,768);
	// auto designSize = Size(1024, 576);

    if (screenSize.height > 320)
    {
//        auto resourceSize = Size(960, 640); //4:3
		auto resourceSize = Size(1024, 768); 
        std::vector<std::string> searchPaths;

        director->setContentScaleFactor(resourceSize.height/designSize.height);
    }
    
    glview->setDesignResolutionSize(designSize.width, designSize.height, ResolutionPolicy::NO_BORDER);

#if CC_TARGET_PLATFORM == CC_PLATFORM_WIN32
	std::string wpath = pFileUtils->getWritablePath();
	pFileUtils->addSearchPath(wpath+"src/luacore");
	pFileUtils->addSearchPath(wpath+"luacore");
	pFileUtils->addSearchPath(wpath+"src");
    pFileUtils->addSearchPath(wpath+"res");
#else
	std::string wpath = pFileUtils->getWritablePath();
	pFileUtils->addSearchPath(wpath+"src/luacore");
	pFileUtils->addSearchPath("luacore");
	pFileUtils->addSearchPath("src");
    pFileUtils->addSearchPath("res");
#endif
    
    auto pEngine = LuaEngine::getInstance();
	auto L = pEngine->getLuaStack()->getLuaState();
	luaopen_lua_exts(L);
	luaopen_lua_ljshell(L);
    ScriptEngineManager::getInstance()->setScriptEngine(pEngine);
	LuaStack* stack = pEngine->getLuaStack();
    //pEngine->executeScriptFile("bootstrap.lua");
	pEngine->executeScriptFile("resume.lua");
	pEngine->executeScriptFile("crash.lua");
	pEngine->executeScriptFile("launcher.lua");
}

#if CC_TARGET_PLATFORM == CC_PLATFORM_WIN32
void AppDelegate::InitForDebugMode()
{
	TCHAR cur[256];

	GetModuleFileName(GetModuleHandle(NULL),cur,256);
	std::wstring path(cur);
	size_t p = path.rfind('\\');
	if( p !=std::wstring::npos )
	{
		std::wstring wp = path.substr(0,p);
		wp += TEXT("\\luacore");
		SetCurrentDirectory( wp.c_str() );
	}
}
#endif

void AppDelegate::registerHotkey()
{
	auto director = Director::getInstance();
	auto pDispatcher = director->getEventDispatcher();
	//ped->addEventListenerWithFixedPriority(this,0);
	auto listener = EventListenerKeyboard::create();
	listener->onKeyPressed = CC_CALLBACK_2(AppDelegate::onKeyPressed,this);
	listener->onKeyReleased = CC_CALLBACK_2(AppDelegate::onKeyReleased,this);
	pDispatcher->addEventListenerWithFixedPriority(listener,1);
}

void AppDelegate::onKeyPressed(cocos2d::EventKeyboard::KeyCode code,cocos2d::Event *pEvent)
{
#ifdef USE_WIN32_CONSOLE
	if(code==EventKeyboard::KeyCode::KEY_F9) //reset
	{
		auto director = Director::getInstance();
		director->end();
	}
	else if(code==EventKeyboard::KeyCode::KEY_F12) //quit
	{
		auto director = Director::getInstance();
		g_Quit = false;
		director->end();
	}
#endif
}

void AppDelegate::onKeyReleased(cocos2d::EventKeyboard::KeyCode code,cocos2d::Event *pEvent)
{
}

// This function will be called when the app is inactive. When comes a phone call,it's be invoked too
void AppDelegate::applicationDidEnterBackground() {
    Director::getInstance()->stopAnimation();

    // if you use SimpleAudioEngine, it must be pause
    CocosDenshion::SimpleAudioEngine::getInstance()->pauseBackgroundMusic();
}

// this function will be called when the app is active again
void AppDelegate::applicationWillEnterForeground() {
    Director::getInstance()->startAnimation();

    // if you use SimpleAudioEngine, it must resume here
    CocosDenshion::SimpleAudioEngine::getInstance()->resumeBackgroundMusic();
}
