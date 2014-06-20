#ifndef _LUA_EXT_
#define _LUA_EXT_

#if __cplusplus
extern "C" {
#endif

#include <lua.h>
#include <lauxlib.h>

void luaopen_lua_exts(lua_State *L);

#if __cplusplus
}
#endif

#endif