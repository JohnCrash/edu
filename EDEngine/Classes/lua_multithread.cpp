#include "lua_multithread.h"
#include <thread>
#include "cocos2d.h"

#define VERSION "1.0"
#if LUA_VERSION_NUM < 502
#  define luaL_newlib(L,l) (lua_newtable(L), luaL_register(L,NULL,l))
#endif

#define LUA_MT_HANDLE "lua_mt_t"

#if __cplusplus
extern "C" {
#endif
	/*
	* 创建一个新的线程
	*/
	struct mthread
	{
		std::thread * pthread;
		int ref;
		lua_State* L;
	};
	static void thread_func(void * p)
	{
		mthread *pm = (mthread*)p;
		lua_rawgeti(pm->L, LUA_REGISTRYINDEX, pm->ref);
		if (lua_isfunction(pm->L, -1))
		{
			lua_call(pm->L, 0, 0);
		}
		else
		{
			CCLOG("lua_isfunction 返回false");
		}
		delete pm;
	}

	static int new_thread(lua_State *L)
	{
		if (lua_isfunction(L, 1))
		{
			lua_pushvalue(L, 1);
			int ref = luaL_ref(L, LUA_REGISTRYINDEX);
			//lua_State *newL = lua_newthread(L);
			lua_State *newL = L;
			mthread *pm = new mthread();
			pm->ref = ref;
			pm->L = newL;
			pm->pthread = new std::thread(thread_func,pm);
		}
		return 0;
	}

	static void createmeta(lua_State *L)
	{
		luaL_newmetatable(L, LUA_MT_HANDLE);
		lua_pushliteral(L, "__index");
		lua_pushvalue(L, -2);
		lua_rawset(L, -3);
	}

	static const struct luaL_Reg lua_mt_methods[] =
	{
		{ NULL, NULL }
	};
	
	static const struct luaL_Reg tclib[] =
	{
		{ "new", new_thread },
		{ NULL, NULL }
	};

	static void set_info(lua_State *L)
	{
		lua_pushliteral(L, "_COPYRIGHT");
		lua_pushliteral(L, "Copyright (C) 2014");
		lua_settable(L, -3);
		lua_pushliteral(L, "_DESCRIPTION");
		lua_pushliteral(L, "LuaMultiThread is lua library.");
		lua_settable(L, -3);
		lua_pushliteral(L, "_VERSION");
		lua_pushliteral(L, "LuaMultiThread" VERSION);
		lua_settable(L, -3);
	}

	int luaopen_multithread(lua_State *L)
	{
		createmeta(L);
		luaL_openlib(L, 0, lua_mt_methods, 0);
		lua_newtable(L);
		luaL_newlib(L, tclib);
		set_info(L);
		return 1;
	}

#if __cplusplus
}
#endif
