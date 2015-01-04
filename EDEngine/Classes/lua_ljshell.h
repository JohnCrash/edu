#ifndef _LUA_LJSHELL_EXT_
#define _LUA_LJSHELL_EXT_
#include "staticlib.h"
#include <string>

MySpaceBegin
#if __cplusplus
extern "C" {
#endif

#include <lua.h>
#include <lauxlib.h>

void luaopen_lua_ljshell(lua_State *L);

#if __cplusplus
}
#endif

enum LJDirectory
{
	Data_DIRECTORY = 1,
    Share_DIRECTORY = 2,
    Lobby_DIRECTORY = 3,
    Download_DIRECTORY = 4,
    App_DIRECTORY = 5,
	AppData_DIRECTORY = 6,
	AppTmp_DIRECTORY = 7,
	User_DIRECTORY = 8,
	AppUser_DIRECTORY  = 9,
	IDName_FILE = 10,
	ShareSetting_FILE = 11,
	UserSetting_FILE = 12,
};

std::string getLjShellDirectory(LJDirectory edd);
void InitEngineDirectory();

MySpaceEnd
#endif