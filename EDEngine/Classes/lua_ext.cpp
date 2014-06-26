#include "lua_ext.h"
#include "lua_thread_curl.h"
#include "tolua++.h"

#if __cplusplus
extern "C" {
#endif

static luaL_Reg luax_exts[] = {
    {"mt", luaopen_threadcurl},
    {NULL, NULL}
};

static int cc_gettype(lua_State *L)
{
	if( lua_isuserdata(L,1) )
	{
		lua_pushstring(L,tolua_typename(L,1));
		return 1;
	}
	lua_pushnil(L);
	return 1;
}

static int cc_istype(lua_State *L)
{
	if( lua_isuserdata(L,1) && lua_isstring(L,2))
	{ 
		tolua_Error tolua_err;
		lua_pushboolean(L,tolua_isusertable(L,1,lua_tostring(L,2),0,&tolua_err));
		return 1;
	}
	lua_pushnil(L);
	return 1;
}

void luaopen_lua_exts(lua_State *L)
{
    luaL_Reg* lib = luax_exts;

	lua_register( L,"cc_type",cc_gettype);
	lua_register( L,"cc_istype",cc_istype);

    lua_getglobal(L, "package");
    lua_getfield(L, -1, "preload");
    for (; lib->func; lib++)
    {
        lua_pushcfunction(L, lib->func);
        lua_setfield(L, -2, lib->name);
    }
    lua_pop(L, 2);
}

#if __cplusplus
}
#endif