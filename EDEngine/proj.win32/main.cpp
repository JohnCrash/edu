#include "main.h"
#include "cocos2d.h"
#include "AppDelegate.h"

USING_NS_CC;

bool g_Quit = true;

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

	while(g_Quit)
	{
		CCLOG("EDEngine is launch...");
		ret = Application::getInstance()->run();
	}

#ifdef USE_WIN32_CONSOLE
    FreeConsole();
#endif

	return ret;
}
