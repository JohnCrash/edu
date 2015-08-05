#include "lua_ljshell.h"
#include "Files.h"
#include "MD5.h"

MySpaceBegin

USING_NS_CC;

CDirMng g_DirMng;

void InitEngineDirectory()
{
	CCLog("InitEngineDirectory EDEngine");
	g_DirMng.Init("EDEngine");
}
std::string getLjShellDirectory(LJDirectory edd)
{
	switch(edd)
	{
	case Data_DIRECTORY:
		return g_DirMng.GetDataDir();
	case Share_DIRECTORY:
		return g_DirMng.GetShareDir();
	case Lobby_DIRECTORY:
		return g_DirMng.GetLobbyDir();
	case Download_DIRECTORY:
		return g_DirMng.GetDownloadDir();
	case App_DIRECTORY:
#if CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID
		return FileUtils::getInstance()->getWritablePath();
#else
		return g_DirMng.GetAppDir();
#endif
	case AppData_DIRECTORY:
		return g_DirMng.GetAppDataDir();
	case AppTmp_DIRECTORY:
		return g_DirMng.GetAppTmpDir();
	case User_DIRECTORY:
		return g_DirMng.GetUserDir();
	case AppUser_DIRECTORY:
		return g_DirMng.GetAppUserDir();
	case IDName_FILE:
		return g_DirMng.GetIDNamePathName();
	case ShareSetting_FILE:
		return g_DirMng.GetShareSettingsPathName();
	case UserSetting_FILE:
		return g_DirMng.GetUserSettingsPathName();
	case LJShell_DIRECTORY:
		return g_DirMng.GetLJShelldir();
	}
	return std::string();
}

#if __cplusplus
extern "C" {
#endif

#define VERSION "1.0"
#if LUA_VERSION_NUM < 502
#  define luaL_newlib(L,l) (lua_newtable(L), luaL_register(L,NULL,l))
#endif
#define LUA_LJSHELL_HANDLE "lua_ljshell_t"

static int getDirectory( lua_State *L )
{
	if( lua_isnumber(L,1) )
	{
		int e = lua_tointeger(L,1);
		std::string str = getLjShellDirectory( (LJDirectory)e );
		lua_pushstring(L,str.c_str());
		return 1;
	}
	else
	{
		lua_pushnil(L);
		lua_pushstring(L,"ljshell.getDirectory invalid paramter #1");
		return 2;
	}
}

static int initApp(  lua_State *L )
{
	if( lua_isstring(L,1) )
	{
		const char * appname = lua_tostring(L,1);
		g_DirMng.Init(appname);
		lua_pushboolean(L,true);
		return 1;
	}
	else
	{
		lua_pushnil(L);
		lua_pushstring(L,"ljshell.initApp invalid paramter #1");
		return 2;
	}
}

static int initUser(  lua_State *L )
{
	if( lua_isnumber(L,1) )
	{
		int userID = lua_tointeger(L,1);
		g_DirMng.InitUser(userID);
		lua_pushboolean(L,true);
		return 1;
	}
	else
	{
		lua_pushnil(L);
		lua_pushstring(L,"ljshell.initApp invalid paramter #1");
		return 2;
	}
}

static const struct luaL_Reg tclib[] = 
{
	{"getDirectory",getDirectory},
	{"initApp",initApp},
	{"initUser",initUser},
	{NULL,NULL}
};

static const struct luaL_Reg lua_ljshell_methods[] = 
{
	{NULL,NULL}
};

static void set_info(lua_State *L) 
{
	lua_pushliteral (L, "_COPYRIGHT");
	lua_pushliteral (L, "Copyright (C) 2014");
	lua_settable (L, -3);
	lua_pushliteral (L, "_DESCRIPTION");
	lua_pushliteral (L, "LuaLjShell is lua library.");
	lua_settable (L, -3);
	lua_pushliteral (L, "_VERSION");
	lua_pushliteral (L, "LuaLjShell" VERSION);
	lua_settable (L, -3);
}

static void createmeta(lua_State *L)
{
	luaL_newmetatable(L, LUA_LJSHELL_HANDLE);
	lua_pushliteral(L, "__index");
	lua_pushvalue(L, -2);
	lua_rawset(L, -3);
}

static int lua_ljshell(lua_State *L)
{
	createmeta(L);
	luaL_openlib (L, 0, lua_ljshell_methods, 0);
	lua_newtable(L);
	luaL_newlib(L,tclib);
	set_info( L );
	return 1;
}

static luaL_Reg luax_ljshell_exts[] = {
    {"ljshell", lua_ljshell},
    {NULL, NULL}
};

void luaopen_lua_ljshell(lua_State *L)
{
    luaL_Reg* lib = luax_ljshell_exts;

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

MySpaceEnd