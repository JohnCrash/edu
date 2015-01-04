#ifndef _LUA_THREAD_CURL_
#define _LUA_THREAD_CURL_
#include "staticlib.h"

#if __cplusplus
extern "C" {
#endif

#include <lua.h>
#include <lauxlib.h>

int luaopen_threadcurl( lua_State *L );

#if __cplusplus
}
#endif
#endif