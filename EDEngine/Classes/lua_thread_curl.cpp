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
					ptc->this_ref != LUA_REFNIL &&
					L == (lua_State *)ptc->user_data )
				{
					lua_rawgeti(L, LUA_REGISTRYINDEX, ptc->ref);
					lua_rawgeti(L, LUA_REGISTRYINDEX, ptc->this_ref);
					pLuaStack->executeFunction(1);
					//lua_call(L,1,0);
					if( ptc->state == kits::OK ||  ptc->state == kits::FAILED ||
						ptc->state == kits::CANCEL )
					{//进度函数将不再被调用,释放引用
						lua_unref( L,ptc->this_ref );
						ptc->this_ref = LUA_REFNIL;
					}
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

/*
	{
		[1] = {
			copyname,
			copycontents,
			filename,
			contents,
		}
		....
	}
*/
static void httppost_param(lua_State *L,int i,kits::curl_t *pct)
{
	if(lua_istable(L,i))
	{
		kits::post_t item;

		lua_pushstring(L,"copyname");
		lua_gettable(L,i);
		if( lua_isstring(L,-1) )
		{
			item.copyname = lua_tostring(L,-1);
		}
		lua_pop(L,1);
		lua_pushstring(L,"copycontents");
		lua_gettable(L,i);
		if( lua_isstring(L,-1))
		{
			size_t len;
			const char *str = lua_tolstring(L,-1,&len);
			if( len > 0 && str )
			{
				item.copycontents.reserve(len);
				memcpy((void*)item.copycontents.c_str(),str,len);
			}
		}
		lua_pop(L,1);
		lua_pushstring(L,"filename");
		lua_gettable(L,i);
		if( lua_isstring(L,-1))
		{
			item.filename = lua_tostring(L,-1);
		}
		lua_pop(L,1);
		lua_pushstring(L,"filecontents");
		lua_gettable(L,i);
		if( lua_isstring(L,-1))
		{
			size_t len;
			const char *str = lua_tolstring(L,-1,&len);
			if( len > 0 && str )
			{
				item.filecontents.resize(len);
				memcpy((void*)item.filecontents.c_str(),str,len);
			}
		}
		lua_pop(L,1);
		pct->posts.push_back(item);
	}
}
static void httppost_params(lua_State *L,int i,kits::curl_t *pct)
{
	if( lua_istable(L,i) )
	{
		lua_pushnil(L);
		while( lua_next(L,i) != 0 )
		{
			//key -2,value -1
			httppost_param(L,lua_gettop(L),pct);
			lua_pop(L,1); //pop value
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
			{
				m = kits::POST;
			}
			else if(strcmp("HTTPPOST",method) == 0 )
			{
				m = kits::HTTPPOST;
			}
			else
				m = kits::GET;
			std::string cookie;
			if( lua_isstring(L,3) )
				cookie = luaL_checkstring(L,3);
			
			kits::curl_t *pct = new kits::curl_t(m,url,cookie);
			pct->retain();
			if( m == kits::POST )
			{ //post form
				if( lua_isstring(L,5) )
				{
					pct->post_form = lua_tostring(L,5);
				}
			}else if( m == kits::HTTPPOST )
			{
				httppost_params(L,5,pct);
			}
			pct->ref = LUA_REFNIL;
			if( lua_isfunction(L,4) )
			{
				lua_pushvalue(L, 4);                                  
				pct->ref = luaL_ref(L, LUA_REGISTRYINDEX);
			}
			pct->progressFunc = lua_progressFunc;
			pct->user_data = (void *)L;
			lua_curl_t * plct = (lua_curl_t *)lua_newuserdata(L,sizeof(lua_curl_t));
			//如果有函数，做自身的引用.没有函数就不用做自身引用
			if( pct->ref != LUA_REFNIL )
			{
				lua_pushvalue(L, -1);
				pct->this_ref = luaL_ref(L, LUA_REGISTRYINDEX);
			}
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
static int lua_pushState(lua_State *L,kits::curl_t *ptc)
{
	switch(ptc->state)
	{
	case kits::INIT:
		lua_pushstring(L,"INIT");
		break;
	case kits::FAILED:
		lua_pushstring(L,"FAILED");
		break;
	case kits::LOADING:
		lua_pushstring(L,"LOADING");
		break;
	case kits::CANCEL:
		lua_pushstring(L,"CANCEL");
		break;
	case kits::OK:
		lua_pushstring(L,"OK");
		break;
	default:
		lua_pushnil(L);
	}
	return 1;
}

//中断下载
static int lua_curl_cancel(lua_State *L)
{
	lua_curl_t* c = (lua_curl_t *)luaL_checkudata(L, 1, LUA_CURL_HANDLE);
	if( c && c->ptc )
	{
		c->ptc->bfastEnd = true;
	}
	return 0;
}
//继续下载
static int lua_curl_restart(lua_State *L)
{
	lua_curl_t* c = (lua_curl_t *)luaL_checkudata(L, 1, LUA_CURL_HANDLE);
	if( c && c->ptc )
	{
		if( c->ptc->state != kits::LOADING &&
			c->ptc->bfastEnd == true && 
			c->ptc->size < c->ptc->usize &&
			c->ptc->usize > 0 )
		{
			c->ptc->pthread->join();
			delete c->ptc->pthread;
			c->ptc->pthread = nullptr;
			c->ptc->bfastEnd = false;
			c->ptc->state = kits::INIT;
			kits::do_thread_curl( c->ptc );
			lua_pushboolean(L,true);
			return 1;
		}
	}
	lua_pushboolean(L,false);
	return 1;
}

static int lua_curl_index(lua_State *L)
{
	lua_curl_t* c = (lua_curl_t *)luaL_checkudata(L, 1, LUA_CURL_HANDLE);
	if( c && c->ptc )
	{
		kits::curl_t *ptc = (kits::curl_t *)c->ptc;
		if( c )
		{
			if( lua_isstring(L,2) )
			{
				const char *key = lua_tostring(L,2);
				if( key )
				{
					if( strcmp( key,"state") == 0 )
					{
						lua_pushState( L,ptc );
					}
					else if(strcmp( key,"progress")==0 )
					{
						lua_pushnumber(L,ptc->progress);
					}
					else if(strcmp( key,"url")==0 )
					{
						lua_pushstring(L,ptc->url.c_str());
					}
					else if(strcmp(key,"cookie")==0 )
					{
						lua_pushstring(L,ptc->cookie.c_str());
					}
					else if(strcmp(key,"errmsg")==0 )
					{
						lua_pushstring(L,ptc->err.c_str());
					}
					else if(strcmp(key,"errcode")==0 )
					{
						lua_pushinteger(L,ptc->errcode);
					}
					else if(strcmp(key,"size")==0 )
					{
						lua_pushinteger(L,(lua_Integer)ptc->size);
					}
					else if(strcmp(key,"data")==0 )
					{
						if( ptc->size > 0 && ptc->data )
							lua_pushlstring(L,(const char *)ptc->data,ptc->size);
						else
							lua_pushnil(L);
					}
					else if(strcmp(key,"method")==0 )
					{
						switch( ptc->method )
						{
						case kits::GET:
							lua_pushstring(L,"GET");
							break;
						case kits::POST:
							lua_pushstring(L,"POST");
							break;
						default:
							lua_pushnil(L);
							;
						}
					}
					else if(strcmp(key,"code")==0 )
					{
						lua_pushinteger(L,ptc->retcode);
					}
					else if(strcmp(key,"usize")==0)
					{
						lua_pushnumber(L,ptc->usize);
					}
					else if(strcmp(key,"cancel")==0)
					{
						lua_pushcfunction(L,lua_curl_cancel);
					}
					else if(strcmp(key,"restart")==0)
					{
						lua_pushcfunction(L,lua_curl_restart);
					}
				}
				return 1;
			}
		}
	}
	lua_pushnil(L);
	return 1;
}
static int lua_curl_gc(lua_State *L)
{
	lua_curl_t* c = (lua_curl_t *)luaL_checkudata(L, 1, LUA_CURL_HANDLE);
	if( c && c->ptc )
	{
		if( c->ptc->ref != LUA_REFNIL )
		{
			lua_unref(L,c->ptc->ref);
			c->ptc->ref = LUA_REFNIL;
		}
		if( c->ptc->this_ref != LUA_REFNIL )
		{
			lua_unref(L,c->ptc->this_ref);
			c->ptc->this_ref = LUA_REFNIL;
		}
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