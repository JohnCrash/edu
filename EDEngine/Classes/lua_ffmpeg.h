#ifndef __LUA_FFMPEG_H__
#define __LUA_FFMPEG_H__
#include "staticlib.h"

#if __cplusplus
extern "C" {
#endif

#include <lua.h>
#include <lauxlib.h>

	int luaopen_ffmpeg(lua_State *L);
#if __cplusplus
}
#endif

#endif