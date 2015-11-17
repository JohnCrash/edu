#ifndef _LUA_THREAD_H_
#define _LUA_THREAD_H_

#include "staticlib.h"

#include <thread>
#include <mutex>
#include <condition_variable>

#if __cplusplus
extern "C" {
#endif

#include <lua.h>
#include <lauxlib.h>

	void luaopen_lua_exts(lua_State *L);

#if __cplusplus
}
#endif

MySpaceBegin

enum thead_state
{
	TS_INIT = 0,
	TS_RUNING,
	TS_WAIT,
	TS_EXIT,
};

struct thread_t
{
	lua_State * L;
	std::thread * thread;
	std::mutex * mutex;
	std::mutex * mutex2;
	std::condition_variable * condition;
	char * thread_script;
	thead_state state;
	int notify_argn;
	int ref;
	int mainCallRef;
	int selfRef;
	int threadRef;
};

/*
 * 在另一个线程中执行脚本文件script
 */
int create_thread_t(thread_t * pt,const char * script);

int release_thread_t(thread_t * pt, bool in,bool must);

int retain_thread_t(thread_t * p);

void wait_thread_t(thread_t *pt);

void notify_thread_t(thread_t *pt);

int luaopen_thread(lua_State *L);

MySpaceEnd

#endif