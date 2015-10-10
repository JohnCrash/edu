/*
*/
#ifndef _MY_THREAD_CURL_H_
#define _MY_THREAD_CURL_H_
#include "staticlib.h"

#include <string>
#include <vector>
#include <thread>

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
	void * _curl;

	curl_t(CURL_METHOD m,std::string u,std::string c):
		method(m),state(INIT),url(u),cookie(c),
		err(),errcode(0),progress(0),
		progressFunc(nullptr),pthread(nullptr),
		size(0),data(nullptr),ref(0),user_data(nullptr),
		refcount(0),bfastEnd(false),this_ref(0),usize(0),
		retcode(0), connect_timeout(60), option_timeout(60), 
		lua_state(INIT), iskeep_alive(false),_curl(nullptr)
	{
	}
	void retain()
	{
		refcount++;
	}
	void release()
	{
		refcount--;
		if( refcount == 0 )
		{
			if( pthread )
			{
				bfastEnd = true;
				pthread->join();
				delete pthread;
			}
			if(data)delete [] data;
			data = nullptr;
			size = 0;
			pthread = nullptr;
		}
	}
};

void do_thread_curl( curl_t *pct );

MySpaceEnd

#endif