#include "lua_ext.h"
#include "lua_thread_curl.h"

#if __cplusplus
extern "C" {
#endif

static luaL_Reg luax_exts[] = {
    {"mt", luaopen_threadcurl},
    {NULL, NULL}
};

void luaopen_lua_exts(lua_State *L)
{
    luaL_Reg* lib = luax_exts;
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