#include "main.h"
#include "cocos2d.h"
#include "AppDelegate.h"

USING_NS_CC;
#ifdef USE_WIN32_CONSOLE
bool g_Quit = true;
#endif

std::string g_Cookie;
std::string g_Launch;
std::string g_Userid;
std::string g_Mode;
std::string toUTF8( const std::wstring& wstr );
HANDLE g_hFileMap;

std::wstring getParam(const std::wstring& cmd,const std::wstring& key)
{
		std::wstring::size_type pos = cmd.find(key,0);
		if( pos != std::wstring::npos )
		{
			std::wstring::size_type epos = cmd.find(TEXT(" "),pos);
			if( epos != std::wstring::npos )
			{
				return cmd.substr(pos+key.length(),epos-pos-key.length());
			}
			else
			{
				return cmd.substr(pos+key.length());
			}
		}else
			return std::wstring();
}

void ParseCommand(LPTSTR lpCmdLine)
{
	std::wstring cmd(lpCmdLine);
	g_Cookie = toUTF8(getParam(cmd,TEXT("cookie=")));
	g_Launch = toUTF8(getParam(cmd,TEXT("launch=")));
	g_Userid = toUTF8(getParam(cmd,TEXT("userid=")));
	g_Mode = toUTF8(getParam(cmd,TEXT("mode=")));
	CCLOG("cookie=%s",g_Cookie.c_str());
	CCLOG("userid=%s", g_Userid.c_str());
	CCLOG("launch=%s", g_Launch.c_str());
}

int APIENTRY _tWinMain(HINSTANCE hInstance,
                       HINSTANCE hPrevInstance,
                       LPTSTR    lpCmdLine,
                       int       nCmdShow)
{
    UNREFERENCED_PARAMETER(hPrevInstance);
    UNREFERENCED_PARAMETER(lpCmdLine);
	ParseCommand(lpCmdLine);
#ifdef USE_WIN32_CONSOLE
    AllocConsole();
    freopen("CONIN$", "r", stdin);
    freopen("CONOUT$", "w", stdout);
    freopen("CONOUT$", "w", stderr);
#endif

    // create the application instance
    AppDelegate app;
    int ret;

	std::wstring uri = TEXT("com.edengine.luacore.") + getParam(lpCmdLine, TEXT("launch="));
	g_hFileMap = CreateFileMapping(INVALID_HANDLE_VALUE, NULL, PAGE_READWRITE, 0, sizeof(APPFILEMAPINFO), uri.c_str());
	//ÒÑ¾­´æÔÚ
	if (GetLastError() == ERROR_ALREADY_EXISTS)
		return false;

#ifdef USE_WIN32_CONSOLE
	while(g_Quit)
	{
		CCLOG("EDEngine is launch...");
		ret = Application::getInstance()->run();

		//reload lua engine
		LuaEngine * pEngine = LuaEngine::getInstance();
		ScriptEngineManager::getInstance()->setScriptEngine(nullptr);
	//	pEngine = LuaEngine::getInstance();
	//	ScriptEngineManager::getInstance()->setScriptEngine(pEngine);
	}
#else
	ret = Application::getInstance()->run();
#endif

#ifdef USE_WIN32_CONSOLE
    FreeConsole();
#endif

	return ret;
}
