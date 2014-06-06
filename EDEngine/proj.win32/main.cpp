#include "main.h"
#include "cocos2d.h"
#include "AppDelegate.h"

USING_NS_CC;
#ifdef USE_WIN32_CONSOLE
bool g_Quit = true;
#endif

int APIENTRY _tWinMain(HINSTANCE hInstance,
                       HINSTANCE hPrevInstance,
                       LPTSTR    lpCmdLine,
                       int       nCmdShow)
{
    UNREFERENCED_PARAMETER(hPrevInstance);
    UNREFERENCED_PARAMETER(lpCmdLine);
	
#ifdef USE_WIN32_CONSOLE
    AllocConsole();
    freopen("CONIN$", "r", stdin);
    freopen("CONOUT$", "w", stdout);
    freopen("CONOUT$", "w", stderr);
#endif

    // create the application instance
    AppDelegate app;
    int ret;

#ifdef USE_WIN32_CONSOLE
	while(g_Quit)
	{
		CCLOG("EDEngine is launch...");
		ret = Application::getInstance()->run();

		//reload lua engine
		LuaEngine * pEngine = LuaEngine::getInstance();
		ScriptEngineManager::getInstance()->setScriptEngine(nullptr);
		pEngine = LuaEngine::getInstance();
		ScriptEngineManager::getInstance()->setScriptEngine(pEngine);
	}
#else
	ret = Application::getInstance()->run();
#endif

#ifdef USE_WIN32_CONSOLE
    FreeConsole();
#endif

	return ret;
}
