#ifndef _LUA_MULTITHREAD_H_
#define _LUA_MULTITHREAD_H_

#include "staticlib.h"

#if __cplusplus
extern "C" {
#endif

#include <lua.h>
#include <lauxlib.h>

	int luaopen_multithread(lua_State *L);

#if __cplusplus
}
#endif
#endif