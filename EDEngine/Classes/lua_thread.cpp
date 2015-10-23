#include "lua_thread.h"
#include "lua_ext.h"
#include <cocos2d.h>
#include "Cocos2dxLuaLoader.h"
#include <string>

UsingMySpace;
MySpaceBegin

#define VERSION "1.0"
#if LUA_VERSION_NUM < 502
#  define luaL_newlib(L,l) (lua_newtable(L), luaL_register(L,NULL,l))
#endif

#define LUA_THREAD_HANDLE "lua_thread_t"

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
	if (!pt)return -1;

	pt->state = TS_RUNING;

	if (pt->L)
	{
		/*
		 * 启动指定的文件
		 */
		std::string code("require \"");
		code.append(pt->thread_script);
		code.append("\"");
		int ret = luaL_loadstring(pt->L, code.c_str());
		if (ret == 0)
		{
			executeFunction(pt->L, 0);
		}
		else
		{
			if (lua_isstring(pt->L, 1))
			{
				CCLOG(lua_tostring(pt->L,1));
			}
		}
	}

	pt->state = TS_EXIT;

	release_thread_t(pt,true);
	return 0;
}

static int lua_print(lua_State * luastate)
{
	int nargs = lua_gettop(luastate);

	std::string t;
	for (int i = 1; i <= nargs; i++)
	{
		if (lua_istable(luastate, i))
			t += "table";
		else if (lua_isnone(luastate, i))
			t += "none";
		else if (lua_isnil(luastate, i))
			t += "nil";
		else if (lua_isboolean(luastate, i))
		{
			if (lua_toboolean(luastate, i) != 0)
				t += "true";
			else
				t += "false";
		}
		else if (lua_isfunction(luastate, i))
			t += "function";
		else if (lua_islightuserdata(luastate, i))
			t += "lightuserdata";
		else if (lua_isthread(luastate, i))
			t += "thread";
		else
		{
			const char * str = lua_tostring(luastate, i);
			if (str)
				t += lua_tostring(luastate, i);
			else
				t += lua_typename(luastate, lua_type(luastate, i));
		}
		if (i != nargs)
			t += "\t";
	}
	CCLOG("[LUA-print] %s", t.c_str());

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

static thread_t * current_thread(lua_State *L)
{
	thread_t * pt = NULL;
	lua_getglobal(L, "_current_thread");
	if (lua_islightuserdata(L, -1))
	{
		pt = (thread_t *)lua_topointer(L, -1);
	}
	lua_pop(L, 1);
	return pt;
}

/*
 * 等待直到其他线程调用notify唤醒
 */
int lua_thread_wait(lua_State * luastate)
{
	thread_t * pt = current_thread(luastate);
	const char *errmsg = "could not find _current_thread";
	if (pt)
	{
		pt->state = TS_WAIT;
		if (pt->mutex&&pt->thread)
		{
			pt->notify_argn = 0;
			lua_pushboolean(luastate, true);
			std::unique_lock<std::mutex> lk(*pt->mutex);
			pt->condition->wait(lk);
			pt->state = TS_RUNING;
			return pt->notify_argn+1;
		}
		else
			errmsg = "thread state error";
		pt->state = TS_RUNING;
	}
	lua_pushboolean(luastate, false);
	lua_pushstring(luastate, errmsg);
	return 2;
}

int lua_thread_sleep(lua_State * luastate)
{
	if (lua_isnumber(luastate, 1))
	{
		int ms = (int)lua_tonumber(luastate, 1);
		std::this_thread::sleep_for(std::chrono::milliseconds(ms));
		lua_pushboolean(luastate, true);
		return 1;
	}
	else
	{
		lua_pushboolean(luastate, false);
		lua_pushstring(luastate, "invalid argument"); 
		return 2;
	}
}

int create_thread_t(thread_t * pt,const char * script)
{
	if (pt)
	{
		memset(pt, 0, sizeof(thread_t));
		pt->L = luaL_newstate();
		if (pt->L)
		{
			luaL_openlibs(pt->L);
			lua_register(pt->L, "print", lua_print);
			lua_register(pt->L, "wait", lua_thread_wait);
			lua_register(pt->L, "sleep", lua_thread_sleep);
			/*
			* 为新环境注入库
			*/
			luaopen_lua_exts(pt->L);
			/*
			 * 文件加载器
			 */
			add_cc_lua_loader(pt->L, cocos2dx_lua_loader);
			pt->thread_script = strdup(script);
			/*
			 * 启动线程代码
			 */
			pt->mutex = new std::mutex();
			pt->condition = new std::condition_variable();
			pt->thread = new std::thread(thread_proc, pt);
			/*
			 * 线程句柄写入到当前环境中
			 */
			lua_pushlightuserdata(pt->L, pt);
			lua_setglobal(pt->L, "_current_thread");
			return 0;
		}
	}

	return -1;
}

int  release_thread_t(thread_t *pt,bool in)
{
	if (pt)
	{
		if (pt->ref <= 0)
		{
			if (!in&&pt->thread &&pt->thread->joinable())
			{
				pt->thread->join();
				delete pt->thread;
				pt->thread = NULL;
			}
			if (pt->condition)
			{
				delete pt->condition;
				pt->condition = NULL;
			}
			if (pt->mutex)
			{
				delete pt->mutex;
				pt->mutex = NULL;
			}
			if (pt->L)
			{
				lua_close(pt->L);
				pt->L = NULL;
			}
			if (pt->thread_script)
			{
				free(pt->thread_script);
				pt->thread_script = NULL;
			}
		}
		else
		{
			pt->ref--;
			return pt->ref;
		}
	}
	return -1;
}

int retain_thread_t(thread_t * p)
{
	if (p)
	{
		p->ref++;
		return p->ref;
	}
	return -1;
}

/*
 * lua中的代码类似于这样
 * thread.new("revice",function(t)
 *			
 * 	end)
 */
static int new_thread(lua_State *L)
{
	if (lua_isstring(L, 1))
	{
		thread_t * pt = (thread_t *)lua_newuserdata(L, sizeof(thread_t));
		int ret = create_thread_t(pt, lua_tostring(L, 1));
		if (ret == 0)
		{
			luaL_getmetatable(L, LUA_THREAD_HANDLE);
			lua_setmetatable(L, -2);
			return 1;
		}
		else
		{
			lua_pop(L,1);
			lua_pushnil(L);
			lua_pushstring(L, "create_thread_t failed");
			return 2;
		}
	}

	lua_pushnil(L);
	lua_pushstring(L, "invalid arguments");
	return 2;
}

/*
 * local b,... = t.notify(...)
 * notify和wait交换两个线程的数据
 * local b,... = wait(...)
 */
static int lua_thread_t_notify(lua_State *L)
{
	thread_t * c = (thread_t *)luaL_checkudata(L, 1, LUA_THREAD_HANDLE);
	const char  *msg = "thread state error";
	if (c&&c->condition&&c->state==TS_WAIT)
	{
		/*
		 * 从一个线程堆栈向另一个线程堆栈搬运参数
		 */
		lua_pushboolean(L, true); //准备返回值
		c->notify_argn = 0;
		int nargs = lua_gettop(L);
		int wait_nargs = lua_gettop(c->L);
		int wait_argn = wait_nargs > 1 ? wait_nargs - 1 : 0; //wait端有多少参数要复制到本线程
		c->notify_argn = nargs > 2 ? nargs - 2 : 0; //本线程有多少参数要复制到wait线程
		/*
		 * 第一步将本线程参数向wait线程复制
		 */
		if (c->notify_argn > 0)
		{
			for (int i = nargs-1; i > 1; i--) //跳过true直到堆栈位置1(obj)
				lua_pushvalue(L, i);
			lua_xmove(L, c->L, c->notify_argn);
		}
		/*
		 * 将wait线程参数线本线程复制
		 */
		if (wait_argn > 0)
		{
			for (int i = wait_argn - 1; i > 1; i--)
				lua_pushvalue(c->L, i);
			lua_xmove(c->L, L, wait_argn); 
		}
		c->condition->notify_one();
		return wait_argn+1;
	}
	lua_pushboolean(L, false);
	lua_pushstring(L, msg);
	return 2;
}

static int lua_thread_t_close(lua_State *L)
{
	thread_t * c = (thread_t *)luaL_checkudata(L, 1, LUA_THREAD_HANDLE);
	if (c)
	{
		release_thread_t(c,false);
	}
	return 0;
}

static int lua_thread_t_index(lua_State *L)
{
	thread_t * c = (thread_t *)luaL_checkudata(L, 1, LUA_THREAD_HANDLE);
	if (c)
	{
		if (lua_isstring(L, 2))
		{
			const char *key = lua_tostring(L, 2);
			if (strcmp(key, "notify") == 0)
			{
				lua_pushcfunction(L, lua_thread_t_notify);
			}
			else if (strcmp(key, "state") == 0)
			{
				const char * r = "unknow";
				switch (c->state)
				{
				case TS_INIT:
					r = "init";
					break;
				case TS_RUNING:
					r = "run";
					break;
				case TS_WAIT:
					r = "wait";
					break;
				case TS_EXIT:
					r = "exit";
					break;
				}
				lua_pushstring(L, r);
			}
			else if (strcmp(key, "join") == 0)
			{
				lua_pushcfunction(L, lua_thread_t_close);
			}
			else
				lua_pushnil(L);

			return 1;
		}
	}
	lua_pushnil(L);
	return 1;
}

static int lua_thread_t_gc(lua_State *L)
{
	thread_t * c = (thread_t *)luaL_checkudata(L, 1, LUA_THREAD_HANDLE);
	if (c)
	{
		release_thread_t(c,false);
	}
	return 0;
}

static void createmeta(lua_State *L)
{
	luaL_newmetatable(L, LUA_THREAD_HANDLE);
	lua_pushliteral(L, "__index");
	lua_pushvalue(L, -2);
	lua_rawset(L, -3);
}

static void set_info(lua_State *L)
{
	lua_pushliteral(L, "_COPYRIGHT");
	lua_pushliteral(L, "Copyright (C) 2015");
	lua_settable(L, -3);
	lua_pushliteral(L, "_DESCRIPTION");
	lua_pushliteral(L, "LuaThread is lua Thread library.");
	lua_settable(L, -3);
	lua_pushliteral(L, "_VERSION");
	lua_pushliteral(L, "LuaThread" VERSION);
	lua_settable(L, -3);
}

static const struct luaL_Reg lua_thread_methods[] =
{
	{ "__index", lua_thread_t_index },
	{ "__gc", lua_thread_t_gc },
	{ NULL, NULL }
};

static const struct luaL_Reg tclib[] =
{
	{ "new", new_thread },
	{ NULL, NULL }
};

int luaopen_thread(lua_State *L)
{
	createmeta(L);
	luaL_openlib(L, 0, lua_thread_methods, 0);
	lua_newtable(L);
	luaL_newlib(L, tclib);
	set_info(L);
	return 1;
}
MySpaceEnd