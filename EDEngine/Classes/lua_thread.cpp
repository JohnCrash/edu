#include "lua_thread.h"
#include "lua_ext.h"
#include <pthread.h>
#include <cocos2d.h>
#include "Cocos2dxLuaLoader.h"
#include "CCLuaStack.h"
#include "CCLuaEngine.h"
#include <string>
#include "tolua_fix.h"

/*
#include "Lua_web_socket.h"
*/

extern "C"
{
#include "luasocket/luasocket.h"
#include "luasocket/mime.h"
#include "luafilesystem/src/lfs.h"
#include "luaexpat-1.3.0/src/lxplib.h"
#include "luacurl/luacurl.h"
#include "luamd5/src/md5.h"
}

UsingMySpace;
MySpaceBegin
static luaL_Reg luax_exts[] = {
	{ "socket.core", luaopen_socket_core },
	{ "mime.core", luaopen_mime_core },
	{ "lfs", luaopen_lfs },
	{ "lxp", luaopen_lxp },
	{ "curl", luaopen_luacurl },
	{ "md5.core", luaopen_md5_core },
	{ NULL, NULL }
};

static void luaopen_exts(lua_State *L)
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

#define VERSION "1.0"
#if LUA_VERSION_NUM < 502
#  define luaL_newlib(L,l) (lua_newtable(L), luaL_register(L,NULL,l))
#endif

#define LUA_THREAD_HANDLE "lua_thread_t"

static void lua_push_table(lua_State *dst, lua_State * src, int index);

/*
 * 将src堆栈index位置的数据压入dst的栈顶，不能转换的数据压入nil
 */
static void lua_push_value(lua_State *dst, lua_State *src, int index)
{
	int type = lua_type(src, index);
	switch (type)
	{
		case LUA_TSTRING:
			if (lua_isnumber(src,index))
				lua_pushnumber(dst, lua_tonumber(src, index));
			else
				lua_pushstring(dst, lua_tostring(src, index));
			break;
		case LUA_TBOOLEAN:
			lua_pushboolean(dst, lua_toboolean(src, index));
			break;
		case LUA_TNUMBER:
			lua_pushnumber(dst, lua_tonumber(src, index));
			break;
		case LUA_TTABLE:
			lua_push_table(dst, src, index);
			break;
		default:
			lua_pushnil(dst);
			break;
	}
}

/*
 * 当src堆栈index位置是一个table才能调用该函数，函数将src位于index的表复制到
 * dst的栈顶
 */
static void lua_push_table(lua_State *dst, lua_State * src, int index)
{
	lua_newtable(dst);
	lua_pushnil(src);
	while (lua_next(src, index-1) != 0)
	{
		lua_push_value(dst, src, -2);
		lua_push_value(dst,src, -1);
		lua_settable(dst, -3);
		lua_pop(src, 1);
	}
}

/*
 * 将从src向dst搬运数据，仿照lua_xmov操作。
 */
static int luax_copy(lua_State * src, lua_State * dst, int n)
{
	for (int i = -n; i < 0; i++)
	{
		lua_push_value(dst, src, i);
	}
	lua_pop(src, n);
	return 0;
}

static int executeFunction(lua_State *_state,int numArgs,int nResult,char ** errmsg)
{
	//初始化错误指针
	if (errmsg)
		*errmsg = NULL;

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
	error = lua_pcall(_state, numArgs, nResult, traceback);                  /* L: ... [G] ret */
	//--_callFromLua;
	if (error)
	{
		const char * msg = lua_tostring(_state, -1);
		if (errmsg&&msg)
			*errmsg = strdup(msg);
		if (traceback == 0)
		{
			CCLOG("[LUA ERROR] %s", msg?msg:"");        /* L: ... error */
			lua_pop(_state, 1); // remove error message from stack
		}
		else                                                            /* L: ... G error */
		{
			lua_pop(_state, 2); // remove __G__TRACKBACK__ and error message from stack
		}
		return -1;
	}

	if (traceback)
	{
		//lua_pop(_state, 1); // remove __G__TRACKBACK__ from stack      /* L: ... */
		lua_remove(_state, -nResult - 1);
	}

	return error;
}

static pthread_key_t g_key;

static void set_current_thread_handle(thread_t * p)
{
	pthread_setspecific(g_key, p);
}

static thread_t * current_thread(lua_State *L)
{
	thread_t * pt = NULL;
	pt = (thread_t *)pthread_getspecific(g_key);
	return pt;
}

static void mainThreadProc(void *ptr)
{
	thread_t *pt = (thread_t *)ptr;
	cocos2d::LuaEngine *pEngine = cocos2d::LuaEngine::getInstance();
	if (pEngine)
	{
		cocos2d::LuaStack *pLuaStack = pEngine->getLuaStack();
		if (pLuaStack)
		{
			lua_State *L = pLuaStack->getLuaState();
			if (L&&pt&&pt->mainCallRef != LUA_REFNIL&&pt->L&&pt->condition)
			{
				if (pt->state == TS_WAIT)
				{
					/*
					 * 调用主线程中的回调函数，首先从线程调用中复制出参数
					 */
					int n = lua_gettop(L);
					lua_rawgeti(L, LUA_REGISTRYINDEX, pt->mainCallRef);
					int wait_argn = lua_gettop(pt->L);
					if (wait_argn > 0)
					{
						for (int i = 1; i <= wait_argn; i++)
						{
							lua_pushvalue(pt->L, i);
						}
						luax_copy(pt->L, L, wait_argn);
					}
					char *errmsg = NULL;
					int ret = executeFunction(L, wait_argn, 5, &errmsg);
					if (ret)
					{
						lua_pushboolean(pt->L, false);
						lua_pushstring(pt->L, errmsg ? errmsg : "");
						if (errmsg)
							free(errmsg);
						pt->notify_argn = 2;
					}
					else
					{
						lua_pushboolean(pt->L, true);
						int n2 = lua_gettop(L);
						pt->notify_argn = n2 - n;
						if (pt->notify_argn > 0)
							luax_copy(L, pt->L, pt->notify_argn);
						pt->notify_argn++;
					}
					pt->condition->notify_one();
				}
				else if (L&&pt->state == TS_EXIT&&pt->mainCallRef != LUA_REFNIL&&pt->selfRef != LUA_REFNIL)
				{
					/*
					* 线程已经退出
					*/
					lua_unref(L, pt->mainCallRef);
					lua_unref(L, pt->selfRef);
					lua_unref(L, pt->threadRef);
					pt->mainCallRef = LUA_REFNIL;
					pt->selfRef = LUA_REFNIL;
					pt->threadRef = LUA_REFNIL;
				}
			}
		}
	}
	release_thread_t(pt,false,false);
}

static int postMain(thread_t *pt)
{
	cocos2d::Director *pDirector = cocos2d::Director::getInstance();
	if (pDirector)
	{
		auto scheduler = cocos2d::Director::getInstance()->getScheduler();
		if (scheduler)
		{
			retain_thread_t(pt);
			if (pDirector == cocos2d::Director::getInstance())
				scheduler->performFunctionInCocosThread_ext(mainThreadProc, (void *)pt);
			return 0;
		}
	}
	return -1;
}

static const char * launch1 = "local script = require \"";
static const char * launch2 = "\"\nif script and type(script) == \"function\" then\nscript(__wait_args())\nend\n";

static int thread_proc(thread_t *pt)
{
	if (!pt)return -1;

	/*
	* 使用线程本地存储来和本线程关联的句柄pt
	*/
	set_current_thread_handle(pt);

	if (pt->L)
	{
		/*
		 * 启动指定的文件
		 */
		std::string code(launch1);
		code.append(pt->thread_script);
		code.append(launch2);
		int ret = luaL_loadstring(pt->L, code.c_str());
		if (ret == 0)
		{
			executeFunction(pt->L, 0,0,NULL);
		}
		else
		{
			if (lua_isstring(pt->L, 1))
			{
				CCLOG("%s\n",lua_tostring(pt->L,1));
			}
		}
	}

	pt->state = TS_EXIT;
	/*
	 * 通知主线程线程已经退出可以做清理工作
	 */
	if (pt->L)
	{
		/*
		 * 再也不需要pt->L了
		 */
		lua_close(pt->L);
		pt->L = NULL;
		postMain(pt);
		release_thread_t(pt, true,false);
	}
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

/*
 * 等待直到其他线程调用notify唤醒
 */
int lua_thread_wait(lua_State * luastate)
{
	thread_t * pt = current_thread(luastate);
	const char *errmsg = "could not find _current_thread";
	if (pt)
	{
		if (pt->mutex&&pt->condition)
		{
			std::unique_lock<std::mutex> lk(*pt->mutex);
			pt->state = TS_WAIT;
			pt->notify_argn = 0;
			lua_pushboolean(luastate, true);
			if (pt->condition)
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

int lua_thread_wait_args(lua_State * luastate)
{
	thread_t * pt = current_thread(luastate);
	const char *errmsg = "could not find _current_thread";
	if (pt)
	{
		if (pt->mutex&&pt->condition)
		{
			std::unique_lock<std::mutex> lk(*pt->mutex);
			pt->state = TS_WAIT;
			pt->notify_argn = 0;
			if (pt->condition)
				pt->condition->wait(lk);
			pt->state = TS_RUNING;
			return pt->notify_argn;
		}
		else
			errmsg = "thread state error";
		pt->state = TS_RUNING;
	}
	lua_pushboolean(luastate, false);
	lua_pushstring(luastate, errmsg);
	return 2;
}

/*
 * 向主线程的回调函数发送参数，并接收回调的返回函数
 */
static int lua_thread_post(lua_State *L)
{
	const char * msg;
	thread_t * pt = current_thread(L);
	if (!pt)
	{
		lua_pushboolean(L, false);
		lua_pushstring(L, "lua script is not running on thread");
		return 2;
	}
	if (pt->mainCallRef == LUA_REFNIL)
	{
		lua_pushboolean(L, false);
		lua_pushstring(L, "main thread have not callback");
		return 2;
	}
	
	if (pt->mutex&&pt->condition)
	{
		std::unique_lock<std::mutex> lk(*pt->mutex);
		pt->notify_argn = 0;
		pt->state = TS_WAIT;
		if (postMain(pt) == 0)
		{
			if (pt->condition)
				pt->condition->wait(lk);
			pt->state = TS_RUNING;
			return pt->notify_argn;
		}
		else
			msg = "main thread is not cocos2d-x thread";
	}
	else msg = "thread exited";

	pt->state = TS_RUNING;
	lua_pushboolean(L, false);
	lua_pushstring(L, msg);
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

int create_thread_t(thread_t * pt,const char * script,lua_State *L)
{
	if (pt)
	{
		memset(pt, 0, sizeof(thread_t));
		pt->mainCallRef = LUA_REFNIL;
		pt->selfRef = LUA_REFNIL;
		pt->threadRef = LUA_REFNIL;
		pt->L = luaL_newstate();
		/*
		 * 因为有数据共享，多个线程在lua内部执行中会出现异常
		 * 问题主要集中在对字符串的访问上，因为字符串在lua内部是共享的
		 */
//		pt->L = lua_newthread(L);
//		pt->threadRef = luaL_ref(L, LUA_REGISTRYINDEX);
		if (pt->L)
		{
			toluafix_open(pt->L);
			luaL_openlibs(pt->L);
			lua_register(pt->L, "print", lua_print);
			lua_register(pt->L, "wait", lua_thread_wait);
			lua_register(pt->L, "__wait_args", lua_thread_wait_args);
			lua_register(pt->L, "sleep", lua_thread_sleep);
			lua_register(pt->L, "post", lua_thread_post);
			/*
			* 为新环境注入库
			*/
			luaopen_lua_exts(pt->L);
			luaopen_exts(pt->L);

			//tolua_web_socket_open(pt->L);
			//register_web_socket_manual(pt->L);

			/*
			 * 文件加载器
			 */
			add_cc_lua_loader(pt->L, cocos2dx_lua_loader);
			pt->thread_script = strdup(script);
			/*
			* 线程句柄写入到当前环境中
			*/
			lua_pushlightuserdata(pt->L, pt);
			lua_setglobal(pt->L, "_current_thread");
			/*
			 * 启动线程代码
			 */
			pt->mutex = new std::mutex();
			pt->mutex2 = new std::mutex();
			pt->condition = new std::condition_variable();
			pt->thread = new std::thread(thread_proc, pt);
			return 0;
		}
	}

	return -1;
}

int  release_thread_t(thread_t *pt,bool in,bool must)
{
	if (pt)
	{
		std::mutex * mux = NULL;
		if (pt->mutex2)
		{
			std::unique_lock<std::mutex> lk(*pt->mutex2);
			if (pt->ref <= 0||must)
			{
				mux = pt->mutex2;
				pt->mutex2 = NULL;

				/* 让thread lua环境停止继续工作 */
				set_current_thread_handle(NULL);

				if (!in&&pt->thread &&pt->thread->joinable())
				{
					/*
					 * 如果线程没有进入wait,就设置pt->condition=null禁止等待
					 * 如果已经在等待就通知退出
					 */
					auto tmp = pt->condition;
					if (pt->state == TS_WAIT)
					{
						while (pt->state == TS_WAIT)
						{
							pt->condition->notify_one();
							std::this_thread::sleep_for(std::chrono::milliseconds(1));
						}
					}
					else
					{
						pt->condition = NULL;
					}
					pt->thread->join();
					delete pt->thread;
					pt->thread = NULL;
					pt->condition = tmp;
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
				if (pt->thread_script)
				{
					free(pt->thread_script);
					pt->thread_script = NULL;
				}
			}
		}
		if (mux)
			delete mux;

		/*
		 * 如果Lua已经不持有本对象，并且引用计数归零就直接释放
		 */
		if (pt->ref <= 0&&pt->L==NULL)
		{
		//	delete pt;
			return -1;
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
		if (p->mutex2)
		{
			std::unique_lock<std::mutex> lk(*p->mutex2);
			p->ref++;
			return p->ref;
		}
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
		int argn = lua_gettop(L);
		int calln = 1;
		//thread_t * pt = (thread_t *)lua_newuserdata(L, sizeof(thread_t));
		thread_t *pt = new thread_t();
		thread_t ** ppt = (thread_t**)lua_newuserdata(L, sizeof(thread_t*));
		*ppt = pt;

		int ret = create_thread_t(pt, lua_tostring(L, 1),L);

		if (ret == 0)
		{
			if (lua_isfunction(L, 2))
			{
				lua_pushvalue(L, 2);
				pt->mainCallRef = luaL_ref(L, LUA_REGISTRYINDEX);
				calln++;
			}
			/*
			 * 将其他参数传递给等待参数的线程
			 */
			while (pt->state != TS_WAIT)
			{
				std::this_thread::sleep_for(std::chrono::milliseconds(1));
				if (pt->state != TS_INIT)
					break;
			}

			pt->notify_argn = argn-calln; //本线程有多少参数要复制到wait线程
			if (pt->notify_argn > 0)
			{
				for (int i = calln+1; i <= argn; i++) //跳过true直到堆栈位置1(obj)
					lua_pushvalue(L, i);
				luax_copy(L, pt->L, pt->notify_argn);
			}

			if (pt->condition){
				std::lock_guard<std::mutex> lk(*pt->mutex);
				pt->condition->notify_one();
			}

			/*
			 * thread_t对象pt在L中如果没有引用将被释放，但是如果新的线程还存在
			 * 它在调用current_thread就返回一个失效的指针。这里确保只要线程存在
			 * 对象就不能被释放
			 */
			lua_pushvalue(L, -1);
			pt->selfRef = luaL_ref(L, LUA_REGISTRYINDEX);
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

static thread_t * lua_toThreadObject(lua_State *L, int n)
{
	thread_t ** ppt = (thread_t **)luaL_checkudata(L, 1, LUA_THREAD_HANDLE);
	return *ppt;
}
/*
 * local b,... = t.notify(...)
 * notify和wait交换两个线程的数据
 * local b,... = wait(...)
 */
static int lua_thread_t_notify(lua_State *L)
{
	thread_t * c = lua_toThreadObject(L, 1);
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
			for (int i = 2; i < nargs; i++) //跳过true直到堆栈位置1(obj)
				lua_pushvalue(L, i);
			luax_copy(L, c->L, c->notify_argn);
		}
		/*
		 * 将wait线程参数线本线程复制
		 */
		if (wait_argn > 0)
		{
			for (int i = 1; i <wait_nargs; i++)
				lua_pushvalue(c->L, i);
			luax_copy(c->L, L, wait_argn); 
		}
		if (c->condition){
			std::lock_guard<std::mutex> lk(*c->mutex);
			c->condition->notify_one();
		}
		return wait_argn+1;
	}
	lua_pushboolean(L, false);
	lua_pushstring(L, msg);
	return 2;
}

static int lua_thread_t_close(lua_State *L)
{
	thread_t * c = lua_toThreadObject(L, 1);
	if (c)
	{
		release_thread_t(c,false,false);
	}
	return 0;
}

static int lua_thread_t_index(lua_State *L)
{
	thread_t * c = lua_toThreadObject(L, 1);
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
	thread_t * c = lua_toThreadObject(L, 1);
	if (c)
	{
		c->closeit = c->L;
		c->L = NULL;
		release_thread_t(c,false,true);
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
	pthread_key_create(&g_key, NULL);

	lua_register(L, "wait", lua_thread_wait);
	lua_register(L, "__wait_args", lua_thread_wait_args);
	lua_register(L, "sleep", lua_thread_sleep);
	lua_register(L, "post", lua_thread_post);

	createmeta(L);
	luaL_openlib(L, 0, lua_thread_methods, 0);
	lua_newtable(L);
	luaL_newlib(L, tclib);
	set_info(L);
	return 1;
}
MySpaceEnd