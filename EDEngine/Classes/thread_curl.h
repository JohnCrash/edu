/*
*/
#ifndef _MY_THREAD_CURL_H_
#define _MY_THREAD_CURL_H_
#include "staticlib.h"

#include <string>
#include <vector>
#include <thread>
#include <mutex>
#include <condition_variable>

MySpaceBegin

enum CURL_METHOD
{
	GET,
	POST,
	HTTPPOST
};

enum CURL_STATE
{
	INIT,
	FAILED,
	LOADING,
	CANCEL,
	OK
};

#ifndef byte
	typedef unsigned char byte;
#endif

struct post_t
{
	std::string copyname;
	std::string copycontents;
	std::string filename;
	std::string filecontents;
};

struct curl_t
{
	CURL_METHOD method;
	CURL_STATE state;
	std::string url;
	std::string cookie;
	std::string err;
	std::string post_form;
	std::string content_type;
	std::vector<post_t> posts;
	int errcode;
	float progress;// 0-1
	void (* progressFunc)(curl_t *t);
	std::thread *pthread;
	size_t size;
	byte *data;
	int ref;
	void *user_data;
	long refcount;
	bool bfastEnd;
	int this_ref;
	double usize;
	long retcode;
	int connect_timeout;
	int option_timeout;
	CURL_STATE lua_state;
	bool iskeep_alive;
	std::mutex * _mutex;
	std::condition_variable * _cond;
	std::mutex * _mutex2;
	int _eof;
	int _busy;
	bool isthread_exit;

	curl_t(CURL_METHOD m,std::string u,std::string c):
		method(m),state(INIT),url(u),cookie(c),
		err(),errcode(0),progress(0),
		progressFunc(nullptr),pthread(nullptr),
		size(0),data(nullptr),ref(0),user_data(nullptr),
		refcount(0),bfastEnd(false),this_ref(0),usize(0),
		retcode(0), connect_timeout(60), option_timeout(60), 
		lua_state(INIT), iskeep_alive(false), _eof(0), _busy(false), isthread_exit(false)
	{
		_mutex = new std::mutex();
		_mutex2 = new std::mutex();
		_cond = new std::condition_variable();
	}
	void retain();

	void release();
};

void do_thread_curl( curl_t *pct );

MySpaceEnd

#endif