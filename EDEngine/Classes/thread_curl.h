/*
*/
#ifndef _MY_THREAD_CURL_H_
#define _MY_THREAD_CURL_H_
#include <string>
#include <thread>

namespace kits
{
enum CURL_METHOD
{
	GET,
	POST
};

enum CURL_STATE
{
	INIT,
	FAILED,
	LOADING,
	OK
};

#ifndef byte
	typedef unsigned char byte;
#endif

struct curl_t
{
	CURL_METHOD method;
	CURL_STATE state;
	std::string url;
	std::string cookie;
	std::string err;
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

	curl_t(CURL_METHOD m,std::string u,std::string c):
		method(m),state(INIT),url(u),cookie(c),
		err(),errcode(0),progress(0),
		progressFunc(nullptr),pthread(nullptr),
		size(0),data(nullptr),ref(0),user_data(nullptr),
		refcount(0),bfastEnd(false)
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

}

#endif