#include "lua_thread_curl.h"
#include "thread_curl.h"
#if __cplusplus
extern "C" {
#endif

#define VERSION "1.0"
#if LUA_VERSION_NUM < 502
#  define luaL_newlib(L,l) (lua_newtable(L), luaL_register(L,NULL,l))
#endif

static int do_curl(lua_State *L)
{
	return 0;
}
static const struct luaL_Reg tclib[] = 
{
	{"do_curl",do_curl},
	{NULL,NULL}
};
static void set_info(lua_State *L) 
{
	lua_pushliteral (L, "_COPYRIGHT");
	lua_pushliteral (L, "Copyright (C) 2014");
	lua_settable (L, -3);
	lua_pushliteral (L, "_DESCRIPTION");
	lua_pushliteral (L, "LuaThreadCurl is lua library.");
	lua_settable (L, -3);
	lua_pushliteral (L, "_VERSION");
	lua_pushliteral (L, "LuaThreadCurl "VERSION);
	lua_settable (L, -3);
}

int luaopen_threadcurl( lua_State *L )
{
	lua_newtable(L);
	luaL_newlib(L,tclib);
	set_info( L );
	return 1;
}
#if __cplusplus
}
#endif