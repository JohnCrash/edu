#include "lua_ext.h"
#include "lua_thread_curl.h"
#include "tolua++.h"
#include "cocos2d.h"
#if CC_TARGET_PLATFORM == CC_PLATFORM_MAC||CC_TARGET_PLATFORM == CC_PLATFORM_IOS
#include "AppleBundle.h"
#endif

static void pathsp(std::string& path)
{
	if( path.length() > 0 )
		if( path.back() == '/'||
           path.back() == '\\' )
		{
			path.pop_back();
		}
}

#if CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID
extern std::string g_Cookie;
extern std::string g_Launch;
#endif

static int cc_launchparam(lua_State* L)
{
	#if CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID
	lua_pushstring(L,g_Launch.c_str());
	lua_pushstring(L,g_Cookie.c_str());
	return 2;
	#else
	return 0;
	#endif
}

#if CC_TARGET_PLATFORM == CC_PLATFORM_WINDOWS
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

void luaopen_lua_exts(lua_State *L)
{
    luaL_Reg* lib = luax_exts;

	lua_register( L,"cc_type",cc_gettype);
	lua_register( L,"cc_istype",cc_istype);
    lua_register( L,"cc_directory",cc_directory);
	lua_register( L,"cc_launchparam",cc_launchparam);

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
