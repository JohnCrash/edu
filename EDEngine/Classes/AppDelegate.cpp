#include "AppDelegate.h"
#include "HelloWorldScene.h"
#include "SimpleAudioEngine.h"
#include "lua_ext.h"
#include "luaDebug.h"
#include "AssetsManager.h"

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
	glview->setFrameSize(1024,576);
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
    auto designSize = Size(1024, 768);
	// auto designSize = Size(1024, 576);

    if (screenSize.height > 320)
    {
//        auto resourceSize = Size(960, 640); //4:3
		auto resourceSize = Size(1024, 768); 
        std::vector<std::string> searchPaths;
        searchPaths.push_back("hd");
        pFileUtils->setSearchPaths(searchPaths);
        director->setContentScaleFactor(resourceSize.height/designSize.height);
    }
    
    glview->setDesignResolutionSize(designSize.width, designSize.height, ResolutionPolicy::NO_BORDER);
 
	auto path = FileUtils::getInstance()->getWritablePath();
	if( path.length() > 0 )
		if( path.back() == '/'||
			path.back() == '\\' )
		{
			path.pop_back();
		}
	std::string luap = path + "/luacore";
	FileUtils::getInstance()->addSearchPath(luap.c_str());

    auto pEngine = LuaEngine::getInstance();
	luaopen_lua_exts(pEngine->getLuaStack()->getLuaState());
    ScriptEngineManager::getInstance()->setScriptEngine(pEngine);
    
    LuaStack* stack = pEngine->getLuaStack();
	stack->setXXTEAKeyAndSign("2dxLua", strlen("2dxLua"), "XXTEA", strlen("XXTEA"));
    register_assetsmanager_test_sample(stack->getLuaState());
	#ifdef _DEBUG
		startRuntime();
	#endif
    pEngine->executeScriptFile("bootstrap.lua");
}

#if CC_TARGET_PLATFORM == CC_PLATFORM_WIN32
void AppDelegate::InitForDebugMode()
{
	auto path = FileUtils::getInstance()->getWritablePath();
	
	TCHAR cur[256];
	GetCurrentDirectory(255,cur);
	wcscat(cur,L"\\luacore");
	SetCurrentDirectory( cur );
//	GetCurrentDirectory(255,cur);
//	printf("write dir = %s\n",path.c_str());
//	printf("current dir= %s\n",cur);
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

/*
bool AppDelegate::initInternalLuaEngine()
{
	_core = LuaStack::create();
	_debuger = LuaStack::create();
	_core->retain();
	_debuger->retain();


	return true;
}

void AppDelegate::releaseInternalLuaEngine()
{
	CC_SAFE_RELEASE(_core);
	CC_SAFE_RELEASE(_debuger);
	_core = nullptr;
	_debuger = nullptr;
}
*/