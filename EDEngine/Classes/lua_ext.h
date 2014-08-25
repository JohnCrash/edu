#ifndef _LUA_EXT_
#define _LUA_EXT_

#include <string>

#if __cplusplus
extern "C" {
#endif

#include <lua.h>
#include <lauxlib.h>

void luaopen_lua_exts(lua_State *L);

#if __cplusplus
}
#endif

enum EDDirectory
{
    APP_DIRECTORY = 1,
    LUA_DIRECTORY = 2,
    RESOURCE_DIRECTORY = 3,
    CACHE_DIRECTORY = 4,
    LUACORE_DIRECTORY = 5,
};

std::string getDirectory(EDDirectory edd);
#endif