#include "AppDelegate.h"
#include "HelloWorldScene.h"
//#include "SimpleAudioEngine.h"
#include "lua_ext.h"
#include "lua_ljshell.h"
#include "luaDebug.h"
#include "AssetsManager.h"

#if CC_TARGET_PLATFORM == CC_PLATFORM_WIN32
#include "win32/glfw3native.h"
#endif

#if CC_TARGET_PLATFORM == CC_PLATFORM_MAC||CC_TARGET_PLATFORM == CC_PLATFORM_IOS
#include "AppleBundle.h"
#endif

#if CC_TARGET_PLATFORM == CC_PLATFORM_WIN32
HWND g_hMainWnd = NULL;

std::string toUTF8( const std::wstring& wstr )
{
	std::string str;
	int len = WideCharToMultiByte(CP_UTF8,0,wstr.c_str(),-1,NULL,NULL,NULL,NULL); 
	if( len == 0 )
	{
		return "";
	}
	str.resize( len );
	len = WideCharToMultiByte(CP_UTF8,0,wstr.c_str(),-1,&str[0],str.size(),NULL,NULL);
	if( str.back()==0 )
		str.pop_back();
	return str;
}
#endif
AppDelegate::AppDelegate()
{

}

AppDelegate::~AppDelegate() 
{
	//releaseInternalLuaEngine();
}

extern std::string g_Mode;
#if CC_TARGET_PLATFORM == CC_PLATFORM_WIN32
extern bool g_Reset;
extern int g_FrameWidth;
extern int g_FrameHeight;
#endif
bool AppDelegate::applicationDidFinishLaunching() 
{
    // initialize director
    auto director = Director::getInstance();
    auto glview = director->getOpenGLView();
    if(!glview) {
#if CC_TARGET_PLATFORM == CC_PLATFORM_WIN32
	g_Reset = false;
#ifndef _DEBUG
		if( g_Mode == "fullscreen" )
			glview = GLView::createWithFullScreen(toUTF8(TEXT("乐教乐学")));
		else if( g_Mode == "window" )
			glview = GLView::create(toUTF8(TEXT("乐教乐学")));
		else
			glview = GLView::createWithFullScreen(toUTF8(TEXT("乐教乐学")));
#else
		glview = GLView::create(toUTF8(TEXT("乐教乐学")));
#endif
#else
		glview = GLView::create("EDEngine");
#endif
        director->setOpenGLView(glview);
    }

#ifdef USE_WIN32_CONSOLE
    // turn on display FPS
    director->setDisplayStats(true);
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

#if  (CC_TARGET_PLATFORM == CC_PLATFORM_WIN32)
	if (g_hFileMap)
	{
		PAPPFILEMAPINFO pInfo = (PAPPFILEMAPINFO)MapViewOfFile(g_hFileMap, FILE_MAP_ALL_ACCESS, 0, 0, 0);
		pInfo->size = sizeof(APPFILEMAPINFO);
		g_hMainWnd = glfwGetWin32Window(glview->getWindow());
		pInfo->hwnd = g_hMainWnd;
		UnmapViewOfFile(pInfo);
	}
	else
	{
		g_hMainWnd = NULL;
		CCLOG("ERROR g_hMainWnd = NULL");
	}
#endif

#if CC_TARGET_PLATFORM == CC_PLATFORM_WIN32	|| CC_TARGET_PLATFORM == CC_PLATFORM_MAC
#ifndef _DEBUG
#ifdef _WIN32
    //window release
	if(g_Mode=="window")
	{
		int w, h;
		RECT rect;
		HWND hwnd = GetDesktopWindow();
		GetClientRect(hwnd, &rect);

		if( g_FrameWidth <=0 && g_FrameHeight <= 0 )
		{
			int borderHeight = 72;//GetSystemMetrics(SM_CYBORDER);
			int width = rect.right-rect.left-2*borderHeight;
			int height;
			float v = (rect.bottom-rect.top)/(rect.right-rect.left);
			w = width;
			if( abs(v -9/16) > abs(v-3/4) )
			{
				glview->setFrameSize(width,width*3/4);
				h = width * 3 / 4;
			}
			else
			{
				glview->setFrameSize(width,width*9/16);
				h = width * 9 / 16;
			}
		}
		else
		{
			glview->setFrameSize(g_FrameWidth,g_FrameHeight);
			w = g_FrameWidth;
			h = g_FrameHeight;
		}
		if (g_hMainWnd && hwnd )
		{ //居中放置
			int x,y;
			x = (abs(rect.right-rect.left)-w)/2;
			y = 0;//(abs(rect.bottom-rect.top)-h)/2;
			SetWindowPos(g_hMainWnd, HWND_TOP, x, y, 0, 0, SWP_NOSIZE | SWP_SHOWWINDOW);
		}
	}
#endif //_WIN32
#else
    //window debug
	if (g_Mode == "window")
	{
		if (g_FrameWidth <= 0 && g_FrameHeight <= 0)
		{
			glview->setFrameSize(1024,576);
		}
		else
		{
			glview->setFrameSize(g_FrameWidth, g_FrameHeight);
		}
	}
	else
		glview->setFrameSize(1024, 576);
#endif //_DEBUG
#if CC_TARGET_PLATFORM == CC_PLATFORM_MAC
    //Mac
    if (g_Mode == "window")
    {
        glview->setFrameSize(1024, 576);
    }
    else
        glview->setFrameSize(1024, 576);
#endif
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

#ifndef _DEBUG
	InitEngineDirectory();
	std::string wpath = getLjShellDirectory(App_DIRECTORY);
	pFileUtils->addSearchPath(wpath+"src/luacore",true);
	pFileUtils->addSearchPath(wpath+"res/luacore",true);
	pFileUtils->addSearchPath(wpath+"src");
	pFileUtils->addSearchPath(wpath+"res");
	pFileUtils->addSearchPath(wpath+"cache");
	pFileUtils->addSearchPath(wpath);
#if CC_TARGET_PLATFORM == CC_PLATFORM_WIN32
	std::string exe = getExeDir();
	pFileUtils->addSearchPath(exe);
	pFileUtils->addSearchPath(exe+"luacore");
	pFileUtils->addSearchPath(exe+"luacore/res");
	pFileUtils->addSearchPath(exe+"src");
    pFileUtils->addSearchPath(exe+"res");	
#else
	pFileUtils->addSearchPath("luacore");
	pFileUtils->addSearchPath("luacore/res");
	pFileUtils->addSearchPath("src");
    pFileUtils->addSearchPath("res");
#endif
#else
#ifdef _PROGRAMFILES_DEBUG_
	InitEngineDirectory();
	std::string wpath = getLjShellDirectory(App_DIRECTORY);
	pFileUtils->addSearchPath(wpath + "src/luacore", true);
	pFileUtils->addSearchPath(wpath + "res/luacore", true);
	pFileUtils->addSearchPath(wpath + "src");
	pFileUtils->addSearchPath(wpath + "res");
	pFileUtils->addSearchPath(wpath + "cache");
	pFileUtils->addSearchPath(wpath);
	std::string exe = getExeDir();
	pFileUtils->addSearchPath(exe);
	pFileUtils->addSearchPath(exe + "luacore");
	pFileUtils->addSearchPath(exe + "luacore/res");
	pFileUtils->addSearchPath(exe + "src");
	pFileUtils->addSearchPath(exe + "res");
#else
	InitEngineDirectory();
	std::string wpath = getLjShellDirectory(App_DIRECTORY);
	pFileUtils->addSearchPath(wpath+"cache");
	pFileUtils->addSearchPath(wpath);
	std::string exe = getExeDir();
	pFileUtils->addSearchPath(exe);
	pFileUtils->addSearchPath(exe+"luacore");
	pFileUtils->addSearchPath(exe+"luacore/res");
	pFileUtils->addSearchPath(exe+"src");
    pFileUtils->addSearchPath(exe+"res");	
#endif
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
std::string AppDelegate::getExeDir()
{
	TCHAR cur[256];
	GetModuleFileName(GetModuleHandle(NULL),cur,256);
	std::string exe = toUTF8( cur );
	std::string::size_type pos = exe.find_last_of('\\');
	if( pos != std::string::npos )
	{
		return exe.substr(0,pos+1);
	}
	else
		return exe;
}

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
