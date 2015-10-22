#include "lua_thread.h"
#include "lua_ext.h"
#include <cocos2d.h>
#include "Cocos2dxLuaLoader.h"
#include <string>

UsingMySpace;
MySpaceBegin

static int executeFunction(lua_State *_state,int numArgs)
{
	int functionIndex = -(numArgs + 1);
	if (!lua_isfunction(_state, functionIndex))
	{
		CCLOG("value at stack [%d] is not function", functionIndex);
		lua_pop(_state, numArgs + 1); // remove function and arguments
		return 0;
	}

	int traceback = 0;
	lua_getglobal(_state, "__G__TRACKBACK__");                         /* L: ... func arg1 arg2 ... G */
	if (!lua_isfunction(_state, -1))
	{
		lua_pop(_state, 1);                                            /* L: ... func arg1 arg2 ... */
	}
	else
	{
		lua_insert(_state, functionIndex - 1);                         /* L: ... G func arg1 arg2 ... */
		traceback = functionIndex - 1;
	}

	int error = 0;
	//++_callFromLua;
	error = lua_pcall(_state, numArgs, 1, traceback);                  /* L: ... [G] ret */
	//--_callFromLua;
	if (error)
	{
		if (traceback == 0)
		{
			CCLOG("[LUA ERROR] %s", lua_tostring(_state, -1));        /* L: ... error */
			lua_pop(_state, 1); // remove error message from stack
		}
		else                                                            /* L: ... G error */
		{
			lua_pop(_state, 2); // remove __G__TRACKBACK__ and error message from stack
		}
		return 0;
	}

	// get return value
	int ret = 0;
	if (lua_isnumber(_state, -1))
	{
		ret = (int)lua_tointeger(_state, -1);
	}
	else if (lua_isboolean(_state, -1))
	{
		ret = (int)lua_toboolean(_state, -1);
	}
	// remove return value from stack
	lua_pop(_state, 1);                                                /* L: ... [G] */

	if (traceback)
	{
		lua_pop(_state, 1); // remove __G__TRACKBACK__ from stack      /* L: ... */
	}

	return ret;
}

int thread_proc(thread_t *pt)
{
	if (pt)
		pt->state = TS_RUNING;

	if (pt && pt->L)
	{
		/*
		 * 启动指定的文件
		 */
		std::string code("require \"");
		code.append(pt->thread_script);
		code.append("\"");
		luaL_loadstring(pt->L, code.c_str());
		executeFunction(pt->L,0);
	}

	if (pt)
		pt->state = TS_EXIT;
	return 0;
}

static void add_cc_lua_loader(lua_State *_state, lua_CFunction func)
{
	if (!func) return;

	// stack content after the invoking of the function
	// get loader table
	lua_getglobal(_state, "package");                                  /* L: package */
	lua_getfield(_state, -1, "loaders");                               /* L: package, loaders */

	// insert loader into index 2
	lua_pushcfunction(_state, func);                                   /* L: package, loaders, func */
	for (int i = (int)(lua_objlen(_state, -2) + 1); i > 2; --i)
	{
		lua_rawgeti(_state, -2, i - 1);                                /* L: package, loaders, func, function */
		// we call lua_rawgeti, so the loader table now is at -3
		lua_rawseti(_state, -3, i);                                    /* L: package, loaders, func */
	}
	lua_rawseti(_state, -2, 2);                                        /* L: package, loaders */

	// set loaders into package
	lua_setfield(_state, -2, "loaders");                               /* L: package */

	lua_pop(_state, 1);
}

thread_t * create_thread_t()
{
	thread_t * pt = NULL;
	
	pt = (thread_t *)malloc(sizeof(thread_t));
	if (pt)
	{
		memset(pt, 0, sizeof(thread_t));
		pt->L = luaL_newstate();
		if (pt->L)
		{
			/*
			 * 文件加载器
			 */
			add_cc_lua_loader(pt->L, cocos2dx_lua_loader);
			/*
			 * 为新环境注入库
			 */
			luaopen_lua_exts(pt->L);
			/*
			 * 启动线程代码
			 */
			pt->mutex = new std::mutex();
			pt->condition = new std::condition_variable();
			pt->thread = new std::thread(thread_proc, pt);
		}
	}
	return pt;
}

int  release_thread_t(thread_t *pt)
{

}

int retain_thread_t(thread_t * p)
{

}

MySpaceEnd