#include "AppDelegate.h"
#include "HelloWorldScene.h"

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

    // turn on display FPS
    director->setDisplayStats(true);

    // set FPS. the default value is 1.0/60 if you don't call this
    director->setAnimationInterval(1.0 / 60);
	
#ifdef USE_WIN32_CONSOLE
	registerHotkey();
#endif
/*	_console = ::Console::create();

	if(!_console)
	{
		CCLOGERROR("%s","Fails:can't create console!");
		return false;
	}
*/
	/*
	initInternalLuaEngine();

	// register lua engine
    LuaEngine* pEngine = LuaEngine::getInstance();
    ScriptEngineManager::getInstance()->setScriptEngine(pEngine);

	auto helloworld = HelloWorld::createScene(); 
	cocos2d::Director::getInstance()->runWithScene(helloworld);
	helloworld->addChild(_console);
	//cocos2d::Director::getInstance()->runWithScene(_console);
	printf(FileUtils::getInstance()->getWritablePath().c_str());
	*/
    return true;
}

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
}

void AppDelegate::onKeyReleased(cocos2d::EventKeyboard::KeyCode code,cocos2d::Event *pEvent)
{
}

// This function will be called when the app is inactive. When comes a phone call,it's be invoked too
void AppDelegate::applicationDidEnterBackground() {
    Director::getInstance()->stopAnimation();

    // if you use SimpleAudioEngine, it must be pause
    // SimpleAudioEngine::getInstance()->pauseBackgroundMusic();
}

// this function will be called when the app is active again
void AppDelegate::applicationWillEnterForeground() {
    Director::getInstance()->startAnimation();

    // if you use SimpleAudioEngine, it must resume here
    // SimpleAudioEngine::getInstance()->resumeBackgroundMusic();
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