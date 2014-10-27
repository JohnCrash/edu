#ifndef  _APP_DELEGATE_H_
#define  _APP_DELEGATE_H_

#include "cocos2d.h"
#include "Console.h"
#include "CCScriptSupport.h"
#include "CCLuaStack.h"
#include "CCLuaEngine.h"

USING_NS_CC;

extern bool g_Quit;

#if (CC_TARGET_PLATFORM == CC_PLATFORM_WIN32)
typedef struct
{
	int size;
	HWND hwnd;
}APPFILEMAPINFO, *PAPPFILEMAPINFO;

extern HANDLE g_hFileMap;
#endif

/**
@brief    The cocos2d Application.

The reason for implement as private inheritance is to hide some interface call by Director.
*/
class  AppDelegate : private cocos2d::Application
{
public:
    AppDelegate();
    virtual ~AppDelegate();

    /**
    @brief    Implement Director and Scene init code here.
    @return true    Initialize success, app continue.
    @return false   Initialize failed, app terminate.
    */
    virtual bool applicationDidFinishLaunching();

    /**
    @brief  The function be called when the application enter background
    @param  the pointer of the application
    */
    virtual void applicationDidEnterBackground();

    /**
    @brief  The function be called when the application enter foreground
    @param  the pointer of the application
    */
    virtual void applicationWillEnterForeground();

	void onKeyPressed(cocos2d::EventKeyboard::KeyCode,cocos2d::Event *);
	void onKeyReleased(cocos2d::EventKeyboard::KeyCode,cocos2d::Event *);
private:
	void registerHotkey();
	void initLuaEngine();
#if CC_TARGET_PLATFORM == CC_PLATFORM_WIN32
	void InitForDebugMode();
	std::string getExeDir();
#endif
	/*
	bool initInternalLuaEngine();
	void releaseInternalLuaEngine();
	cocos2d::LuaStack *_core;
	cocos2d::LuaStack *_debuger;
	::Console *_console;
	*/
};

#endif // _APP_DELEGATE_H_

