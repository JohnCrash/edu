#include "lua_ext.h"
#include "lua_thread_curl.h"
#include "tolua++.h"
#include "cocos2d.h"
#include "CCLuaStack.h"
#include "CCLuaEngine.h"
#include "Platform.h"

#if CC_TARGET_PLATFORM == CC_PLATFORM_MAC||CC_TARGET_PLATFORM == CC_PLATFORM_IOS
#include "AppleBundle.h"
#endif

static int g_callref=LUA_REFNIL;

struct TRS
{
	std::string path;
	int result;
	int type;
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

extern std::string g_Cookie;
extern std::string g_Launch;
extern std::string g_Userid;

static int cc_launchparam(lua_State* L)
{
	lua_pushstring(L,g_Launch.c_str());
	lua_pushstring(L,g_Cookie.c_str());
	lua_pushstring(L,g_Userid.c_str());
	return 3;
}

#if CC_TARGET_PLATFORM == CC_PLATFORM_WIN32
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

#if __cplusplus
extern "C" {
#endif

extern int luaopen_json( lua_State *L );

static luaL_Reg luax_exts[] = {
    {"mt", luaopen_threadcurl},
	{"json-c",luaopen_json},
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
	CCLOG("VoiceStartRecord %d,%d,%d",channel,rate,samples);
	bool b = VoiceStartRecord(channel,rate,samples);
	CCLOG("VoiceStartRecord return %s",b?"true":"false");
	lua_pushboolean(L,b);
	return 1;
}

int cc_stopRecordVoice(lua_State *L)
{
	char pszSaveFile[256];
	CCLOG("VoiceStopRecord");
	bool b = VoiceStopRecord( pszSaveFile );
	CCLOG("VoiceStopRecord return %s,%s",b?"true":"false",pszSaveFile);
	lua_pushboolean(L,b);
	lua_pushstring(L,pszSaveFile);
	return 2;
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
#endif
