/*
*/
#ifndef _MY_THREAD_CURL_H_
#define _MY_THREAD_CURL_H_
#include <string>

namespace kits
{
enum CURL_METHOD{
	GET,
	POST
};

void do_thread_curl( CURL_METHOD,
					const std::string url,
					const std::string cookie );

}

#endif