#ifndef _LUA_EXT_
#define _LUA_EXT_

#include <string>

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
    DATA_DIRECTORY = 1,
    SHARE_DIRECTORY = 2,
    LOBBY_DIRECTORY = 3,
    DOWNLOAD_DIRECTORY = 4,
    APP_DIRECTORY = 5,
	APPDATA_DIRECTORY = 6,
	APPTMP_DIRECTORY = 7,
	USER_DIRECTORY = 8,
	APPUSER_DIRECTORY  = 9,
};

std::string getLjShellDirectory(LJDirectory edd);
#endif