#include "lua_thread_curl.h"
#include "thread_curl.h"
#include "cocos2d.h"
#include "CCLuaStack.h"
#include "CCLuaEngine.h"

#if __cplusplus
extern "C" {
#endif

#define VERSION "1.0"
#if LUA_VERSION_NUM < 502
#  define luaL_newlib(L,l) (lua_newtable(L), luaL_register(L,NULL,l))
#endif

#define LUA_CURL_HANDLE "lua_curl_t"
struct lua_curl_t
{
	kits::curl_t *ptc;
};

static void lua_mainThread_progressFunc( void *ptr )
{
	cocos2d::LuaEngine *pEngine = cocos2d::LuaEngine::getInstance();
	if( pEngine )
	{
		cocos2d::LuaStack *pLuaStack = pEngine->getLuaStack();
		if( pLuaStack )
		{
			lua_State *L = pLuaStack->getLuaState();
			if( L )
			{
				kits::curl_t *ptc = (kits::curl_t *)ptr;
				if( ptc && ptc->ref != LUA_REFNIL && 
					L == (lua_State *)ptc->user_data )
				{
					lua_rawgeti(L, LUA_REGISTRYINDEX, ptc->ref);
					lua_call(L,0,0);
					ptc->release();
					return;
				}
			}
		}
	}
	//if L==nillptr?
	kits::curl_t *ptc = (kits::curl_t *)ptr;
	if( ptc )
		ptc->release();
}

static void lua_progressFunc( kits::curl_t * ptc )
{
	//call lua progress function
	cocos2d::Director *pDirector = cocos2d::Director::getInstance();
	if( pDirector )
	{
		auto scheduler = cocos2d::Director::getInstance()->getScheduler();
		if( scheduler )
		{
			ptc->retain();
			scheduler->performFunctionInCocosThread_ext(lua_mainThread_progressFunc,(void *)ptc);
		}
	}
}

/* mt.do_curl(mothed,url,cookie,progressFunc)
	mothed "GET" , "POST" ...
	progressFunc progress callback
	return userdata
*/
static int do_curl(lua_State *L)
{
	if( lua_isstring(L,1) && lua_isstring(L,2) )
	{
		const char *method = luaL_checkstring(L,1);
		const char *url = luaL_checkstring(L,2);
		
		if( method && url )
		{
			kits::CURL_METHOD m;
			if( strcmp("GET",method)==0 )
				m = kits::GET;
			else if( strcmp("POST",method)==0 )
				m = kits::POST;
			else
				m = kits::GET;
			std::string cookie;
			if( lua_isstring(L,3) )
				cookie = luaL_checkstring(L,3);
			
			kits::curl_t *pct = new kits::curl_t(m,url,cookie);
			pct->retain();
			pct->ref = LUA_REFNIL;
			if( lua_isfunction(L,4) )
			{
				lua_pushvalue(L, 4);                                  
				pct->ref = luaL_ref(L, LUA_REGISTRYINDEX);
			}
			pct->progressFunc = lua_progressFunc;
			pct->user_data = (void *)L;
			lua_curl_t * plct = (lua_curl_t *)lua_newuserdata(L,sizeof(lua_curl_t));
			plct->ptc = pct;
			luaL_getmetatable(L,LUA_CURL_HANDLE);
			lua_setmetatable(L,-2);
			kits::do_thread_curl( pct );
		}else
		{
			lua_pushnil(L);
		}

		lua_pushstring(L,"OK");
	}
	else
	{
		lua_pushnil(L);
		lua_pushstring(L,"invalid arguments");
	}
	return 2;
}
static int lua_curl_index(lua_State *L)
{
	return 0;
}
static int lua_curl_gc(lua_State *L)
{
	lua_curl_t* c = (lua_curl_t *)luaL_checkudata(L, 1, LUA_CURL_HANDLE);
	if( c && c->ptc )
	{
		lua_unref(L,c->ptc->ref);
		c->ptc->ref = LUA_REFNIL;
		c->ptc->release();
	}
	return 0;
}
static void createmeta(lua_State *L)
{
	luaL_newmetatable(L, LUA_CURL_HANDLE);
	lua_pushliteral(L, "__index");
	lua_pushvalue(L, -2);
	lua_rawset(L, -3);
}
static const struct luaL_Reg lua_curl_methods[] = 
{
	{"__index",lua_curl_index},
	{"__gc",lua_curl_gc},
	{NULL,NULL}
};
static const struct luaL_Reg tclib[] = 
{
	{"new",do_curl},
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
	createmeta(L);
	luaL_openlib (L, 0, lua_curl_methods, 0);
	lua_newtable(L);
	luaL_newlib(L,tclib);
	set_info( L );
	return 1;
}
#if __cplusplus
}
#endif