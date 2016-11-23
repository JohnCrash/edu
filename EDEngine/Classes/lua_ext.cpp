#include "lua_ext.h"
#include "lua_thread_curl.h"
#include "lua_ffmpeg.h"
#include "lua_thread.h"
#include "tolua++.h"
#include "cocos2d.h"
#include "CCLuaStack.h"
#include "CCLuaEngine.h"
#include "Platform.h"
#include "RenderTextureEx.h"
#include "Files.h"
#include "acr.h"
//#include "lua_multithread.h"

#if CC_TARGET_PLATFORM == CC_PLATFORM_WIN32
#include <windows.h>
#else
#include <sys/time.h>
#endif

#if CC_TARGET_PLATFORM == CC_PLATFORM_MAC||CC_TARGET_PLATFORM == CC_PLATFORM_IOS
#include "AppleBundle.h"
#endif

UsingMySpace;
MySpaceBegin
extern std::string g_Mode;

#if CC_TARGET_PLATFORM == CC_PLATFORM_WIN32
extern int g_FrameWidth;
extern int g_FrameHeight;
extern bool g_Reset;
extern std::wstring utf8ToUnicode(const std::string& s);
extern COLORREF g_frameColor;
extern COLORREF g_titleColor;
extern HWND g_hMainWnd;

static void UpdateMainFrame(HWND hwnd) {
	SetWindowPos(hwnd, NULL, 0, 0, 0, 0,
		SWP_NOSIZE | SWP_NOMOVE | SWP_NOZORDER | SWP_FRAMECHANGED);
	RedrawWindow(hwnd, NULL, NULL, RDW_INVALIDATE | RDW_UPDATENOW);
}
#endif

static int g_callref=LUA_REFNIL;
static int g_callnsl = LUA_REFNIL;
struct TRS
{
	std::string path;
	int result;
	int type;
	TRS(){}
	TRS( int t,int r,std::string s ):type(t),result(r),path(s){}
};

static void takeResource_progressFunc(void *ptrs)
{
	cocos2d::LuaEngine *pEngine = cocos2d::LuaEngine::getInstance();
	if( pEngine )
	{
		cocos2d::LuaStack *pLuaStack = pEngine->getLuaStack();
		if( pLuaStack )
		{
			lua_State *L = pLuaStack->getLuaState();
			if( L && g_callref != LUA_REFNIL && ptrs )
			{
				TRS *trs = (TRS*)ptrs;
				lua_rawgeti(L, LUA_REGISTRYINDEX, g_callref);
				lua_pushinteger(L,trs->type);
				lua_pushinteger(L,trs->result);
				lua_pushstring(L,trs->path.c_str());
				pLuaStack->executeFunction(3);
				delete trs;
				lua_unref(L,g_callref);
				g_callref = LUA_REFNIL;
			}
		}
	}
}
static int s_State = 0;
static void networkStateChange_progressFunc(void *p)
{
	cocos2d::LuaEngine *pEngine = cocos2d::LuaEngine::getInstance();
	if (pEngine)
	{
		cocos2d::LuaStack *pLuaStack = pEngine->getLuaStack();
		if (pLuaStack)
		{
			lua_State *L = pLuaStack->getLuaState();
			if (L && g_callnsl != LUA_REFNIL && p)
			{
				lua_rawgeti(L, LUA_REGISTRYINDEX, g_callnsl);
				lua_pushinteger(L, s_State);
				pLuaStack->executeFunction(2);
				//lua_unref(L, g_callnsl);
				//g_callnsl = LUA_REFNIL;
			}
		}
	}
}

void networkStateChange(int state)
{
	cocos2d::Director *pDirector = cocos2d::Director::getInstance();
	if (pDirector)
	{
		auto scheduler = cocos2d::Director::getInstance()->getScheduler();
		if (scheduler)
		{
            s_State = state;
			scheduler->performFunctionInCocosThread_ext(networkStateChange_progressFunc, nullptr);
		}
	}
}
void takeResource_callback(std::string resource,int typeCode,int resultCode)
{
	//call lua progress function
	cocos2d::Director *pDirector = cocos2d::Director::getInstance();
	if( pDirector )
	{
		auto scheduler = cocos2d::Director::getInstance()->getScheduler();
		if( scheduler )
		{
			scheduler->performFunctionInCocosThread_ext(takeResource_progressFunc,(void*)new TRS(typeCode,resultCode,resource));
		}
	}
}

static void pathsp(std::string& path)
{
	if( path.length() > 0 )
		if( path.back() == '/'||
           path.back() == '\\' )
		{
			path.pop_back();
		}
}

static int cc_launchparam(lua_State* L)
{
	lua_pushstring(L,g_Launch.c_str());
	lua_pushstring(L,g_Cookie.c_str());
	lua_pushstring(L,g_Userid.c_str());
	lua_pushstring(L, g_Orientation.c_str());
	return 4;
}

#if CC_TARGET_PLATFORM == CC_PLATFORM_WIN32

std::string toMutiByte(const std::wstring& wstr)
{
	std::string str;
	int len = WideCharToMultiByte(CP_ACP, 0, wstr.c_str(), -1, NULL, NULL, NULL, NULL);
	if (len == 0)
	{
		return "";
	}
	str.resize(len);
	len = WideCharToMultiByte(CP_ACP, 0, wstr.c_str(), -1, &str[0], str.size(), NULL, NULL);
	if (str.back() == 0)
		str.pop_back();
	return str;
}
std::string getDirectory(EDDirectory edd)
{
    std::string path;
    switch(edd)
    {
        case APP_DIRECTORY:
            path = cocos2d::FileUtils::getInstance()->getWritablePath();
            break;
        case LUA_DIRECTORY:
            path = cocos2d::FileUtils::getInstance()->getWritablePath();
            break;
        case RESOURCE_DIRECTORY:
            break;
        case CACHE_DIRECTORY:
            break;
        case LUACORE_DIRECTORY:
            break;
    }
    return path;
}
#elif CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID
std::string getDirectory(EDDirectory edd)
{
    std::string path;
    switch(edd)
    {
        case APP_DIRECTORY:
            path = cocos2d::FileUtils::getInstance()->getWritablePath();
            break;
        case LUA_DIRECTORY:
            path = cocos2d::FileUtils::getInstance()->getWritablePath();
            break;
        case RESOURCE_DIRECTORY:
            break;
        case CACHE_DIRECTORY:
            break;
        case LUACORE_DIRECTORY:
            break;
    }
    return path;
}
#elif CC_TARGET_PLATFORM == CC_PLATFORM_IOS
std::string getDirectory(EDDirectory edd)
{
    std::string path;
    switch(edd)
    {
        case APP_DIRECTORY:
            path = cocos2d::FileUtils::getInstance()->getWritablePath();
            break;
        case LUA_DIRECTORY:
            path = cocos2d::FileUtils::getInstance()->getWritablePath();
            break;
        case RESOURCE_DIRECTORY:
            break;
        case CACHE_DIRECTORY:
            break;
        case LUACORE_DIRECTORY:
            break;
    }
    return path;
}
#elif CC_TARGET_PLATFORM == CC_PLATFORM_MAC
std::string getDirectory(EDDirectory edd)
{
    std::string path;
    switch(edd)
    {
        case APP_DIRECTORY:
            path = cocos2d::FileUtils::getInstance()->getWritablePath();
            break;
        case LUA_DIRECTORY:
            path = cocos2d::FileUtils::getInstance()->getWritablePath();
            break;
        case RESOURCE_DIRECTORY:
            break;
        case CACHE_DIRECTORY:
            break;
        case LUACORE_DIRECTORY:
            break;
    }
    return path;
}
#endif

static int g_callbaiduResult = LUA_REFNIL;
static void baiduVoice_progressFunc(void *ptrs)
{
	cocos2d::LuaEngine *pEngine = cocos2d::LuaEngine::getInstance();
	if( pEngine )
	{
		cocos2d::LuaStack *pLuaStack = pEngine->getLuaStack();
		if( pLuaStack )
		{
			lua_State *L = pLuaStack->getLuaState();
			if( L && g_callbaiduResult != LUA_REFNIL && ptrs )
			{
				TRS *trs = (TRS*)ptrs;
				lua_rawgeti(L, LUA_REGISTRYINDEX, g_callbaiduResult);
				lua_pushstring(L,trs->path.c_str());
				pLuaStack->executeFunction(1);
				delete trs;
				lua_unref(L,g_callbaiduResult);
				g_callbaiduResult = LUA_REFNIL;
			}
		}
	}
}

void baiduVoiceResult( std::string text )
{
	//call lua progress function
	cocos2d::Director *pDirector = cocos2d::Director::getInstance();
	if( pDirector )
	{
		auto scheduler = cocos2d::Director::getInstance()->getScheduler();
		if( scheduler )
		{
			TRS * ptrs = new TRS();
			ptrs->path = text;
			scheduler->performFunctionInCocosThread_ext(baiduVoice_progressFunc,ptrs);
		}
	}
}

#if __cplusplus
extern "C" {
#endif
#ifdef USE_ZMQ
	extern int luaopen_lzmq(lua_State *L );
	extern int luaopen_lzmq_timer(lua_State *L);
#endif
extern int luaopen_json( lua_State *L );
#ifndef __APPLE__ //ios arm64 not support luajit
extern int luaopen_bit(lua_State *L);
#endif
static luaL_Reg luax_exts[] = {
    {"mt", luaopen_threadcurl},
	{"json-c",luaopen_json},
	{"ff",luaopen_ffmpeg},
	{ "thread", luaopen_thread },
#ifndef __APPLE__
	{ "bit", luaopen_bit },
#endif
	//{ "multithread", luaopen_multithread },
#ifdef USE_ZMQ
	{ "lzmq", luaopen_lzmq },
	{ "lzmq.timer", luaopen_lzmq_timer },
#endif
    {NULL, NULL}
};

static int cc_gettype(lua_State *L)
{
	if( lua_isuserdata(L,1) )
	{
		lua_pushstring(L,tolua_typename(L,1));
		return 1;
	}
	lua_pushnil(L);
	return 1;
}

static int cc_istype(lua_State *L)
{
	if( lua_isuserdata(L,1) && lua_isstring(L,2))
	{ 
		tolua_Error tolua_err;
		const char * typeName = lua_tostring(L,2); 
		if( tolua_isusertable(L,1,typeName,0,&tolua_err) )
			lua_pushboolean(L,true);
		else
			lua_pushboolean(L,false);
		return 1;
	}
	lua_pushnil(L);
	return 1;
}

static int cc_isobj(lua_State *L)
{
	 tolua_Error tolua_err;
	 if (!tolua_isusertype(L,1,"cc.Ref",0,&tolua_err))
		 return 0;
	 void *obj = tolua_tousertype(L,1,0);
	 if(!obj)
			lua_pushboolean(L,false);
	 else
		 lua_pushboolean(L,true);
	 return 1;
}
    
static int cc_clock(lua_State *L)
{
    lua_Number clock;
#if CC_TARGET_PLATFORM == CC_PLATFORM_WIN32
    clock = (lua_Number)GetTickCount();
    clock /= 1000;
#else
    timeval tv;
    gettimeofday(&tv,NULL);
    clock = (lua_Number)tv.tv_sec + (double)(tv.tv_usec)/1000000;
#endif
    lua_pushnumber(L,clock);
    return 1;
}
/*
    1 = APP directory
    2 = LUA source root directory
    3 = resource directory
    4 = configure directory
*/
static int cc_directory(lua_State *L)
{
    if(lua_isnumber(L, 1))
    {
        int i = (int)lua_tonumber(L, 1);
        std::string str;
        switch(i)
        {
            case 1: //APP
                str = getDirectory(APP_DIRECTORY);
                lua_pushstring(L, str.c_str());
                break;
            case 2: //LUA Source
                str = getDirectory(APP_DIRECTORY);
                lua_pushstring(L, str.c_str());
                break;
            case 3: //Resource
                str = getDirectory(RESOURCE_DIRECTORY);
                lua_pushstring(L, str.c_str());
                break;
            default:
                lua_pushnil(L);
        }
    }
    return 1;
}

static int cc_takeResource(lua_State *L)
{
	if( lua_isnumber(L,1))
	{
		int i = (int)lua_tonumber(L, 1);
        switch(i)
		{
		case 1: //Camera
		case 2: //Photo library
		case 3: //Record audio
			if( lua_isfunction(L,2) )
			{
				lua_pushvalue(L,-1);
				if( g_callref != LUA_REFNIL )
					lua_unref(L,g_callref);
				g_callref = luaL_ref(L,LUA_REGISTRYINDEX);
			}
			else
			{
				g_callref = LUA_REFNIL;
			}
			takeResource(i);
			return 1;
		}
	}
	lua_pushnil(L);
	return 2;
}

int cc_startRecordVoice(lua_State *L)
{
	//1,8000,16
	int channel = 1;
	int rate = 8000;
	int samples = 16;
	
	if( lua_isnumber(L,1) )
		channel = lua_tointeger(L,1);
	if( lua_isnumber(L,2) )
		rate = lua_tointeger(L,2);
	if( lua_isnumber(L,3) )
		samples = lua_tointeger(L,3);
	bool b = VoiceStartRecord(channel,rate,samples);
	lua_pushboolean(L,b);
	return 1;
}

int cc_stopRecordVoice(lua_State *L)
{
	char pszSaveFile[256];
	bool b = VoiceStopRecord( pszSaveFile );
	lua_pushboolean(L,b);
	lua_pushstring(L,pszSaveFile);
	return 2;
}

int cc_getRecordVoiceInfo(lua_State *L)
{
	float Duration;
	int vol;
	bool b = VoiceGetRecordInfo(Duration, vol);
	lua_pushboolean(L, b);
	lua_pushnumber(L, Duration);
	lua_pushnumber(L, vol);
	return 3;
}

int cc_playVoice(lua_State *L)
{
	if (lua_isstring(L,1))
	{
		const char *amr = lua_tostring(L, 1);
		lua_pushboolean(L, VoiceStartPlay(amr));
		return 1;
	}
	lua_pushnil(L);
	return 1;
}

int cc_stopVoice(lua_State *L)
{
	VoiceStopPlay();
	return 0; 
}

int cc_getVoiceLength(lua_State *L)
{
	if (lua_isstring(L, 1))
	{
		const char *amr = lua_tostring(L, 1);
		double d = VoiceLongth(amr);
		lua_pushnumber(L, d);
		return 1;
	}
	lua_pushnumber(L, 0);
	return 1;
}

int cc_isVoicePlaying(lua_State *L)
{
	if (lua_isstring(L, 1))
	{
		const char *amr = lua_tostring(L, 1);
		lua_pushboolean(L,VoiceIsPlaying(amr));
		return 1;
	}
	lua_pushnil(L);
	return 1;
}

int cc_adjustPhoto(lua_State *L)
{
	if (lua_isstring(L, 1) &&lua_isnumber(L,2) )
	{
		std::string fn = lua_tostring(L, 1);
		//utf8 文件名
#if CC_TARGET_PLATFORM == CC_PLATFORM_WIN32
		/*	
			windows 版本文件名是一个utf8编码的文件名，cocos2d需要一个utf8文件名，IsFileExist需要mutibyte
		*/
		std::wstring wfn = utf8ToUnicode(fn);
		std::string fn_mt = toMutiByte(wfn);
		if (IsFileExist(fn_mt.c_str()))
		{
			auto img = new CImageEx();
			if (img->LoadFromFile(fn_mt.c_str()))
			{
				bool b = img->ReduceAndSaveToFile(fn_mt, lua_tonumber(L, 2), img->GetJpgOrientation());
				std::string tmp = img->GetTmpFile();
				img->release();
				lua_pushboolean(L, b);
				lua_pushstring(L, tmp.c_str());
				return 2;
			}
			else
			{
				img->release();
				lua_pushboolean(L, false);
				lua_pushstring(L, "load picture file error");
				return 2;
			}
		}
		else
		{
			lua_pushboolean(L, false);
			lua_pushstring(L, "file not exist");
			return 2;
		}
#else
		if (IsFileExist(fn.c_str()))
		{
			auto img = new CImageEx();
			if (img->LoadFromFile(fn.c_str()))
			{
				bool b = img->ReduceAndSaveToFile(fn, lua_tonumber(L, 2), img->GetJpgOrientation());
				std::string tmp = img->GetTmpFile();
				img->release();
				lua_pushboolean(L, b);
				lua_pushstring(L, tmp.c_str());
				return 2;
			}
			else
			{
				img->release();
				lua_pushboolean(L, false);
				lua_pushstring(L, "load picture file error");
				return 2;
			}
		}
		else
		{
			lua_pushboolean(L, false);
			lua_pushstring(L, "file not exist");
			return 2;
		}
#endif
	}
	else
	{
		lua_pushboolean(L, false);
		lua_pushstring(L, "invalid pamater");
		return 2;
	}
}

int cc_resetWindow(lua_State *L)
{
#if CC_TARGET_PLATFORM == CC_PLATFORM_WIN32
	if (lua_isstring(L, 1))
	{
		std::string mode = lua_tostring(L, 1);
		if (mode == "window")
		{
			if (lua_isnumber(L, 2) && lua_isnumber(L, 3))
			{
				g_FrameWidth = lua_tonumber(L, 2);
				g_FrameHeight = lua_tonumber(L, 3);
			}
			else
			{
				g_FrameWidth = -1;
				g_FrameHeight = -1;
			}
			g_Mode = mode;
			g_Reset = true;
			lua_pushboolean(L, true);
			return 1;
		}
		else if (mode == "fullscreen")
		{

			g_FrameWidth = -1;
			g_FrameHeight = -1;
			g_Mode = mode;
			g_Reset = true;
			lua_pushboolean(L, true);
			return 1;
		}
	}
#else
#endif
	lua_pushboolean(L,false);
	lua_pushstring(L,"Invalid argument");
	return 2;
}

int cc_getWindowInfo(lua_State *L)
{
#if CC_TARGET_PLATFORM == CC_PLATFORM_WIN32
	lua_pushstring(L, g_Mode.c_str());
	lua_pushinteger(L,g_FrameWidth);
	lua_pushinteger(L,g_FrameHeight);
	return 3;
#else
	lua_pushstring(L,"fullscreen");
	return 1;
#endif
}

int cc_getScreenInfo(lua_State *L)
{
#if CC_TARGET_PLATFORM == CC_PLATFORM_WIN32
	HWND hwnd = GetDesktopWindow();
	RECT rect;
	GetClientRect(hwnd, &rect);
	lua_pushnumber(L, abs(rect.right - rect.left));
	lua_pushnumber(L, abs(rect.bottom - rect.top));
	return 2;
#else
    auto director = cocos2d::Director::getInstance();
	auto glview = director->getOpenGLView();
	auto size = glview->getFrameSize();
	lua_pushnumber(L, size.width);
	lua_pushnumber(L, size.height);
	return 2;
#endif
}

static int cc_openURL(lua_State *L)
{
    if( lua_isstring(L, 1) )
    {
        bool ret = platformOpenURL(lua_tostring(L, 1));
        lua_pushboolean(L,ret);
    }
    else
    {
        lua_pushboolean(L, false);
        lua_pushstring(L,"cc_openURL invalid augument #1");
    }
    return 2;
}

int cc_setUIOrientation(lua_State *L)
{
	if (lua_isnumber(L, 1))
	{
		setUIOrientation(lua_tointeger(L,1));
	}
	else
	{
		CCLOG("cc_setUIOrientation first argument is number");
	}
	return 0;
}

int cc_getUIOrientation(lua_State *L)
{
	int ret = getUIOrientation();
	lua_pushinteger(L, ret);
	return 1;
}

int cc_getNetworkState(lua_State *L)
{
	lua_pushinteger(L, getNetworkState());
	return 1;
}

int cc_registerNetworkStateListener(lua_State *L)
{
	if (lua_isfunction(L, 1))
	{
		lua_pushvalue(L, 1);
		if (g_callnsl != LUA_REFNIL)
			lua_unref(L, g_callnsl);
		g_callnsl = luaL_ref(L, LUA_REGISTRYINDEX);
		registerNetworkStateListener();
	}
	return 0;
}

int cc_unregisterNetworkStateListener(lua_State *L)
{
	if (g_callnsl != LUA_REFNIL)
		lua_unref(L, g_callnsl);
	g_callnsl = LUA_REFNIL;
	unregisterNetworkStateListener();
	return 0;
}

int cc_shock(lua_State *L)
{
	if( lua_isnumber(L,1) )
	{
		int delay = lua_tonumber(L,1);
		ShockPhoneDelay( delay );
	}
	return 0;
}

int cc_isdebug(lua_State *L)
{
#ifdef _DEBUG
	lua_pushboolean(L,true);
#else
	lua_pushnil(L);
#endif
	return 1;
}

int cc_showBaiduVoice(lua_State *L)
{
	if( lua_isfunction(L,1) ){
		lua_pushvalue(L, 1);
		if (g_callbaiduResult != LUA_REFNIL)
			lua_unref(L, g_callbaiduResult);
		g_callbaiduResult = luaL_ref(L, LUA_REGISTRYINDEX);
		
		showBaiduVoice();
		lua_pushboolean(L,true);
	}
	else
		lua_pushboolean(L,false);
	return 1;
}

int cc_closeBaiduVoice(lua_State *L)
{
	closeBaiduVoice();
	return 0;
}

int cc_showBaiduVoiceConfigure(lua_State *L)
{
	showBaiduVoiceConfigure();
	return 0;
}

int cc_acr_log(lua_State *L)
{
	if (lua_isstring(L, 1))
	{
#ifndef __APPLE__        //apple not support acr
		const char * msg = lua_tostring(L, 1);
		acr_add_log(msg);
#endif
	}
	return 0;
}

int cc_setFrameColor(lua_State *L)
{
#if CC_TARGET_PLATFORM == CC_PLATFORM_WIN32
	if (lua_isnumber(L, 1) && lua_isnumber(L, 2) &&
		lua_isnumber(L, 3) && lua_isnumber(L, 4) &&
		lua_isnumber(L, 5) && lua_isnumber(L, 6) ){
		g_frameColor = RGB(lua_tonumber(L,1),lua_tonumber(L,2),lua_tonumber(L,3));
		g_titleColor = RGB(lua_tonumber(L, 4), lua_tonumber(L, 5), lua_tonumber(L, 6));
		UpdateMainFrame(g_hMainWnd);
		lua_pushboolean(L, true); 
		lua_pushnil(L);
	}
	else{
		lua_pushboolean(L, false);
		lua_pushstring(L, "invalid argument");
	}
	return 2;
#else
	return 0;
#endif
}

int lua_buy(lua_State *L)
{
	if (lua_isstring(L, 1)){
		buy(luaL_checkstring(L, 1));
		if (lua_isfunction(L, 2))
		{
			lua_pushvalue(L, -1);
			if (g_callref != LUA_REFNIL)
				lua_unref(L, g_callref);
			g_callref = luaL_ref(L, LUA_REGISTRYINDEX);
			lua_pushboolean(L, 1);
			return 1;
		}
		else
		{
			g_callref = LUA_REFNIL;
		}
	}
	return 0;
}

static bool utf8_check_is_valid(const std::string& string)
{
	int c, i, ix, n, j;
	for (i = 0, ix = string.length(); i < ix; i++)
	{
		c = (unsigned char)string[i];
		//if (c==0x09 || c==0x0a || c==0x0d || (0x20 <= c && c <= 0x7e) ) n = 0; // is_printable_ascii
		if (0x00 <= c && c <= 0x7f) n = 0; // 0bbbbbbb
		else if ((c & 0xE0) == 0xC0) n = 1; // 110bbbbb
		else if (c == 0xed && i<(ix - 1) && ((unsigned char)string[i + 1] & 0xa0) == 0xa0) return false; //U+d800 to U+dfff
		else if ((c & 0xF0) == 0xE0) n = 2; // 1110bbbb
		else if ((c & 0xF8) == 0xF0) n = 3; // 11110bbb
		//else if (($c & 0xFC) == 0xF8) n=4; // 111110bb //byte 5, unnecessary in 4 byte UTF-8
		//else if (($c & 0xFE) == 0xFC) n=5; // 1111110b //byte 6, unnecessary in 4 byte UTF-8
		else return false;
		for (j = 0; j<n && i<ix; j++) { // n bytes matching 10bbbbbb follow ?
			if ((++i == ix) || (((unsigned char)string[i] & 0xC0) != 0x80))
				return false;
		}
	}
	return true;
}

static int lua_is_utf8(lua_State *L)
{
	const char * s = luaL_checkstring(L, 1);
	lua_pushboolean(L, utf8_check_is_valid(s));
	return 1;
}

void luaopen_lua_exts(lua_State *L)
{
    luaL_Reg* lib = luax_exts;

	lua_register( L,"cc_type",cc_gettype);
	lua_register( L,"cc_istype",cc_istype);
	lua_register( L,"cc_isobj",cc_isobj);
    lua_register( L,"cc_directory",cc_directory);
	lua_register( L,"cc_launchparam",cc_launchparam);
	lua_register( L,"cc_takeResource",cc_takeResource);
	lua_register( L,"cc_startRecordVoice",cc_startRecordVoice);
	lua_register( L,"cc_stopRecordVoice",cc_stopRecordVoice);
	lua_register(L, "cc_getRecordVoiceInfo", cc_getRecordVoiceInfo);
	lua_register(L, "cc_playVoice", cc_playVoice);
	lua_register(L, "cc_stopVoice", cc_stopVoice);
	lua_register(L, "cc_getVoiceLength", cc_getVoiceLength);
	lua_register(L, "cc_isVoicePlaying", cc_isVoicePlaying);
	lua_register(L, "cc_adjustPhoto", cc_adjustPhoto);
	lua_register(L, "cc_resetWindow", cc_resetWindow);
	lua_register(L, "cc_getWindowInfo", cc_getWindowInfo);
	lua_register(L, "cc_getScreenInfo", cc_getScreenInfo);
    lua_register(L, "cc_clock", cc_clock);
    lua_register(L, "cc_openURL",cc_openURL);
	lua_register(L, "cc_setUIOrientation", cc_setUIOrientation);
	lua_register(L, "cc_getUIOrientation", cc_getUIOrientation);
	lua_register(L, "cc_getNetworkState", cc_getNetworkState);
	lua_register(L, "cc_registerNetworkStateListener", cc_registerNetworkStateListener);
	lua_register(L, "cc_unregisterNetworkStateListener", cc_unregisterNetworkStateListener);
	lua_register(L, "cc_shock", cc_shock);
	lua_register(L, "cc_isdebug", cc_isdebug);
	lua_register(L, "cc_showBaiduVoice",cc_showBaiduVoice);
	lua_register(L, "cc_closeBaiduVoice",cc_closeBaiduVoice);
	lua_register(L, "cc_showBaiduVoiceConfigure",cc_showBaiduVoiceConfigure);
	lua_register(L, "cc_acr_log", cc_acr_log);
	lua_register(L, "cc_setFrameColor", cc_setFrameColor);
	lua_register(L, "cc_isutf8", lua_is_utf8);
	lua_register(L, "cc_buy", lua_buy);
    lua_getglobal(L, "package");

    lua_getfield(L, -1, "preload");
    for (; lib->func; lib++)
    {
        lua_pushcfunction(L, lib->func);
        lua_setfield(L, -2, lib->name);
    }
    lua_pop(L, 2);
}

#if __cplusplus
}

MySpaceEnd
#endif
