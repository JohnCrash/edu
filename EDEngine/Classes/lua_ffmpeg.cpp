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
	static ff::FFVideo *get_ff_video(lua_State *L)
	{
		ff::FFVideo ** pv = (ff::FFVideo**)luaL_checkudata(L, 1, LUA_FFMPEG_HANDLE);
		if (pv && *pv)
			return *pv;
		return nullptr;
	}
	static int lua_refresh(lua_State *L)
	{
		ff::FFVideo *pfv = get_ff_video(L);
		if (pfv)
		{
			void * p = pfv->refresh();
			if (p)
			{
				lua_pushlightuserdata(L, p);
				return 1;
			}
		}
		return 0;
	}
	static int lua_close(lua_State *L)
	{
		ff::FFVideo *pfv = get_ff_video(L);
		if (pfv)
		{
			pfv->close();
			lua_pushboolean(L, true);
			return 1;
		}
		return 0;
	}
	static int lua_seek(lua_State *L)
	{
		ff::FFVideo *pfv = get_ff_video(L);
		if (pfv)
		{
			if (lua_isnumber(L, 2))
			{
				double t = lua_tonumber(L, 2);
				pfv->seek(t);
				lua_pushboolean(L, true);
				return 1;
			}
		}
		return 0;
	}
	static int lua_play(lua_State *L)
	{
		ff::FFVideo *pfv = get_ff_video(L);
		if (pfv)
		{
			pfv->play(); 
			lua_pushboolean(L, true);
			return 1;
		}
		return 0;
	}
	static int lua_pause(lua_State *L)
	{
		ff::FFVideo *pfv = get_ff_video(L);
		if (pfv)
		{
			pfv->pause();
			lua_pushboolean(L, true);
			return 1;
		}
		return 0;
	}
	static int lua_setPreloadNB(lua_State *L)
	{
		ff::FFVideo *pfv = get_ff_video(L);
		if (pfv)
		{
			if (lua_isnumber(L, 2))
			{
				int nb = lua_tointeger(L, 2);
				pfv->set_preload_nb(nb);
				lua_pushboolean(L, true);
				return 1;
			}
		}
		return 0;
	}
	static int lua_ffmpeg_index(lua_State *L)
	{
		ff::FFVideo ** pv = (ff::FFVideo**)luaL_checkudata(L, 1, LUA_FFMPEG_HANDLE);
		while(pv && *pv)
		{
			ff::FFVideo * pfv = *pv;
			if (!lua_isstring(L, 2))
				break;
			const char *key = lua_tostring(L, 2);
			if (!key)
				break;
			if (key[0] == 'i')
			{
				if (strcmp(key, "isOpen") == 0)
				{
					lua_pushboolean(L, pfv->isOpen());
				}
				else if (strcmp(key, "isPause") == 0)
				{
					lua_pushboolean(L, pfv->isPause());
				}
				else if (strcmp(key, "isPlaying") == 0)
				{
					lua_pushboolean(L, pfv->isPlaying());
				}
				else if (strcmp(key, "isEnd") == 0)
				{
					lua_pushboolean(L, pfv->isEnd());
				}
				else if (strcmp(key, "isError") == 0)
				{
					lua_pushboolean(L, pfv->isError());
				}
				else
					lua_pushnil(L);
			}
			else if (key[0] == 'r')
			{
				if (strcmp(key, "refresh") == 0)
				{
					lua_pushcfunction(L, lua_refresh);
				}else
					lua_pushnil(L);
			}
			else
			{
				if (strcmp(key, "current") == 0)
					lua_pushvalue(L, pfv->cur());
				else if (strcmp(key, "preload")==0)
					lua_pushinteger(L, pfv->preload_packet_nb());
				else if (strcmp(key, "width") == 0)
					lua_pushinteger(L, pfv->width());
				else if (strcmp(key, "height") == 0)
					lua_pushinteger(L, pfv->height());
				else if (strcmp(key, "hasVideo") == 0)
					lua_pushboolean(L, pfv->hasVideo());
				else if (strcmp(key, "hasAudio") == 0)
					lua_pushboolean(L, pfv->hasAudio());
				else if (strcmp(key, "errorMsg") == 0)
					lua_pushstring(L, pfv->errorMsg());
				else if (strcmp(key, "close") == 0)
					lua_pushcfunction(L, lua_close);
				else if (strcmp(key, "seek") == 0)
					lua_pushcfunction(L, lua_seek);
				else if (strcmp(key, "length") == 0)
					lua_pushvalue(L, pfv->length());
				else if (strcmp(key, "play") == 0)
					lua_pushcfunction(L, lua_play);
				else if (strcmp(key, "pause") == 0)
					lua_pushcfunction(L, lua_pause);
				else if (strcmp(key, "setPreloadNB"))
					lua_pushcfunction(L, lua_setPreloadNB);
				else
					lua_pushnil(L);
			}
			return 1;
		}
		lua_pushnil(L);
		return 1;
	}

	static int lua_ffmpeg_gc(lua_State *L)
	{
		ff::FFVideo ** pv = (ff::FFVideo**)luaL_checkudata(L, 1, LUA_FFMPEG_HANDLE);
		if (pv && *pv)
		{
			ff::FFVideo * pfv = *pv;
			delete pfv;
		}
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
						ff::FFVideo** pv = (ff::FFVideo**)lua_newuserdata(L, sizeof(ff::FFVideo*));
						*pv = pffv;
						luaL_getmetatable(L, LUA_FFMPEG_HANDLE);
						lua_setmetatable(L, -2);
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