#include "lua_ffmpeg.h"
#include "cocos2d.h"
#include "ff.h"

USING_NS_CC;


#define VERSION "1.0"
#if LUA_VERSION_NUM < 502
#  define luaL_newlib(L,l) (lua_newtable(L), luaL_register(L,NULL,l))
#endif

#define LUA_FFMPEG_HANDLE "lua_ffmpeg_t"

namespace ff
{
	int CCLog(const char* fmt, ...)
	{
		va_list argp;
		va_start(argp, fmt);
		cocos2d::CCLog(fmt, argp);
		va_end(argp);
		return 1;
	}
}

MySpaceBegin

#if __cplusplus
extern "C" {
#endif

	static void createmeta(lua_State *L)
	{
		luaL_newmetatable(L, LUA_FFMPEG_HANDLE);
		lua_pushliteral(L, "__index");
		lua_pushvalue(L, -2);
		lua_rawset(L, -3);
	}
	
	static int lua_ffmpeg_index(lua_State *L)
	{
		return 0;
	}

	static int lua_ffmpeg_gc(lua_State *L)
	{
		return 0;
	}

	static const struct luaL_Reg lua_ffmpeg_methods[] =
	{
		{ "__index", lua_ffmpeg_index },
		{ "__gc", lua_ffmpeg_gc },
		{ NULL, NULL }
	};
	/*
		local stream = ff.new( filename,ONLY_AUDIO )
	*/
	static int new_ffmpeg(lua_State *L)
	{
		if (lua_isstring(L, 1))
		{
			const char *filename = luaL_checkstring(L, 1);
			if (filename)
			{
				ff::FFVideo * pffv = new ff::FFVideo();
				if (pffv)
				{
					bool ret = pffv->open(filename);
					if (!ret)
					{
						lua_pushnil(L);
						lua_pushstring(L, "open stream fail");
					}
					else
					{
						
						lua_pushnil(L);
					}
					return 2;
				}
				lua_pushnil(L);
				lua_pushstring(L, "out of memory");
				return 2;
			}
		}

		lua_pushnil(L);
		lua_pushstring(L, "invalid arguments");
		return 2;
	}
	static const struct luaL_Reg tclib[] =
	{
		{ "new", new_ffmpeg },
		{ NULL, NULL }
	};

	static void set_info(lua_State *L)
	{
		lua_pushliteral(L, "_COPYRIGHT");
		lua_pushliteral(L, "Copyright (C) 2015");
		lua_settable(L, -3);
		lua_pushliteral(L, "_DESCRIPTION");
		lua_pushliteral(L, "LuaFFMpeg is lua library.");
		lua_settable(L, -3);
		lua_pushliteral(L, "_VERSION");
		lua_pushliteral(L, "LuaFFMpeg" VERSION);
		lua_settable(L, -3);
	}

	int luaopen_ffmpeg(lua_State *L)
	{
		createmeta(L);
		luaL_openlib(L, 0, lua_ffmpeg_methods, 0);
		lua_newtable(L);
		luaL_newlib(L, tclib);
		set_info(L);
		return 1;
	}

#if __cplusplus
}
MySpaceEnd
#endif