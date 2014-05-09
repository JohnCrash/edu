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

	initLuaEngine();

    return true;
}

void AppDelegate::initLuaEngine()
{
	auto director = Director::getInstance();
	auto glview = director->getOpenGLView();
    auto screenSize = glview->getFrameSize();
    
	auto pFileUtils = FileUtils::getInstance();

    auto designSize = Size(480, 320);
    
    if (screenSize.height > 320)
    {
        auto resourceSize = Size(960, 640);
        std::vector<std::string> searchPaths;
        searchPaths.push_back("hd");
        pFileUtils->setSearchPaths(searchPaths);
        director->setContentScaleFactor(resourceSize.height/designSize.height);
    }
    
    glview->setDesignResolutionSize(designSize.width, designSize.height, ResolutionPolicy::FIXED_HEIGHT);
 
    auto pEngine = LuaEngine::getInstance();
    ScriptEngineManager::getInstance()->setScriptEngine(pEngine);
    
#if (CC_TARGET_PLATFORM == CC_PLATFORM_WIN32 || CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID ||CC_TARGET_PLATFORM == CC_PLATFORM_IOS || CC_TARGET_PLATFORM == CC_PLATFORM_MAC)
    LuaStack* stack = pEngine->getLuaStack();
    //register_assetsmanager_test_sample(stack->getLuaState());
#endif
	/*
#if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS || CC_TARGET_PLATFORM == CC_PLATFORM_MAC)
    std::string resPrefix("");
#else
    std::string resPrefix("res/");
#endif
    
    std::vector<std::string> searchPaths = pFileUtils->getSearchPaths();
    searchPaths.insert(searchPaths.begin(), resPrefix);

    searchPaths.insert(searchPaths.begin(), resPrefix + "cocosbuilderRes");
    if (screenSize.height > 320)
    {
        searchPaths.insert(searchPaths.begin(), resPrefix + "hd");
        searchPaths.insert(searchPaths.begin(), resPrefix + "hd/Images");
        searchPaths.insert(searchPaths.begin(), resPrefix + "hd/scenetest/ArmatureComponentTest");
        searchPaths.insert(searchPaths.begin(), resPrefix + "hd/scenetest/AttributeComponentTest");
        searchPaths.insert(searchPaths.begin(), resPrefix + "hd/scenetest/BackgroundComponentTest");
        searchPaths.insert(searchPaths.begin(), resPrefix + "hd/scenetest/EffectComponentTest");
        searchPaths.insert(searchPaths.begin(), resPrefix + "hd/scenetest/LoadSceneEdtiorFileTest");
        searchPaths.insert(searchPaths.begin(), resPrefix + "hd/scenetest/ParticleComponentTest");
        searchPaths.insert(searchPaths.begin(), resPrefix + "hd/scenetest/SpriteComponentTest");
        searchPaths.insert(searchPaths.begin(), resPrefix + "hd/scenetest/TmxMapComponentTest");
        searchPaths.insert(searchPaths.begin(), resPrefix + "hd/scenetest/UIComponentTest");
        searchPaths.insert(searchPaths.begin(), resPrefix + "hd/scenetest/TriggerTest");
    }
    else
    {
        searchPaths.insert(searchPaths.begin(), resPrefix + "Images");
        searchPaths.insert(searchPaths.begin(), resPrefix + "scenetest/ArmatureComponentTest");
        searchPaths.insert(searchPaths.begin(), resPrefix + "scenetest/AttributeComponentTest");
        searchPaths.insert(searchPaths.begin(), resPrefix + "scenetest/BackgroundComponentTest");
        searchPaths.insert(searchPaths.begin(), resPrefix + "scenetest/EffectComponentTest");
        searchPaths.insert(searchPaths.begin(), resPrefix + "scenetest/LoadSceneEdtiorFileTest");
        searchPaths.insert(searchPaths.begin(), resPrefix + "scenetest/ParticleComponentTest");
        searchPaths.insert(searchPaths.begin(), resPrefix + "scenetest/SpriteComponentTest");
        searchPaths.insert(searchPaths.begin(), resPrefix + "scenetest/TmxMapComponentTest");
        searchPaths.insert(searchPaths.begin(), resPrefix + "scenetest/UIComponentTest");
        searchPaths.insert(searchPaths.begin(), resPrefix + "scenetest/TriggerTest");
    }

    FileUtils::getInstance()->setSearchPaths(searchPaths);
	*/
	auto path = FileUtils::getInstance()->getWritablePath();
	if( path.length() > 0 )
		if( path.back() == '/'||
			path.back() == '\\' )
		{
			path.pop_back();
		}
	pEngine->addSearchPath(path.c_str());
	FileUtils::getInstance()->addSearchPath("res/");
	FileUtils::getInstance()->addSearchPath(path+"/");
	FileUtils::getInstance()->addSearchPath(path+"/res");
    //pEngine->executeScriptFile("bootstrap.lua");
	pEngine->executeScriptFile("src/controller.lua");
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