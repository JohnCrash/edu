#ifndef _LUA_THREAD_CURL_
#define _LUA_THREAD_CURL_

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