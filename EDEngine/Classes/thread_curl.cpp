#include "thread_curl.h"

#include <vector>
#include "cocos2d.h"

#if CC_TARGET_PLATFORM == CC_PLATFORM_WIN32
#include "curl/include/win32/curl/curl.h"
#elif CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID
#include "curl/include/android/curl/curl.h"
#elif CC_TARGET_PLATFORM == CC_PLATFORM_IOS
#include "curl/include/ios/curl/curl.h"
#endif

namespace kits
{
	typedef std::pair<size_t ,byte *> pair_t;
	typedef std::vector<pair_t > vector_t;

	//合并碎片内存
	static pair_t vector_t_merge( vector_t& v )
	{
		size_t len = 0;
		pair_t bs;
		for( auto it=v.begin();it!=v.end();++it )
			len += it->first;
		if( len > 0 )
		{
			bs.second = new byte[len];
			bs.first = len;
			if( bs.second )
			{
				size_t offset = 0;
				for( auto it=v.begin();it!=v.end();++it )
				{
					memcpy(bs.second+offset,it->second,it->first);
					offset += it->first;
				}
				return bs;
			}
		}
		CCLOG("kits::vector_t_merge alloc error! %d\n",len );
		return pair_t(0,nullptr);
	}
	//清理碎片内存
	static void clean_vector_t( vector_t& v )
	{
		for( auto it=v.begin();it!=v.end();++it )
		{
			delete [] it->second;
		}
		v.clear();
	}
	//重组碎片
	static void rebuild_vector_t( vector_t& v )
	{
		pair_t pt = vector_t_merge( v );
		if( pt.second )
		{
			clean_vector_t( v );
			v.push_back( pt );
		}
	}

	static int progressCallback(void *clientp, double dltotal, double dlnow, double ultotal, double ulnow)
	{
		curl_t *ptc = (curl_t *)clientp;
		if( ptc  )
		{
			if( ptc->bfastEnd )
			{
				ptc->state = CANCEL;
				return -1; //close
			}
			if( dltotal  != 0 )
				ptc->progress = dlnow/dltotal;
			if( ptc->progressFunc )
				ptc->progressFunc(ptc);
		}
		return 0;
	}
	static size_t writerCallback(void *ptr, size_t size, size_t nmemb, void *stream)
	{
		vector_t *vecs = (vector_t *)stream;
		size_t len = 0;
		if( vecs )
		{
			len = size*nmemb;
			byte *bs = new byte[len];
			if( bs )
			{
				vecs->push_back( std::pair<size_t,byte *>(len,bs) );
				memcpy( bs,ptr,len );
			}
			else
			{
				CCLOG("kits::writerCallback alloc error! %d\n",size*nmemb);
				return 0; //?
			}
			if( vecs->size() > 128 )rebuild_vector_t( *vecs );
		}
		return len;
	}
	static size_t readerCallback( void *ptr, size_t size, size_t nmemb, void *stream)
	{
		return 0;
	}
	static size_t headerCallback(void *ptr, size_t size, size_t nmemb, void *stream)
	{
		return 0;
	}
	//thread function
	void curl_thread_method( curl_t *pct )
	{
		//do something
		CURL *curl;
		CURLcode res;
		vector_t bufs;

		if( !pct ){ return ; }

		curl = curl_easy_init();
		if( curl )
		{
			//set timeout
			curl_easy_setopt(curl,CURLOPT_TIMEOUT,60);
			curl_easy_setopt(curl,CURLOPT_CONNECTTIMEOUT,5);
			//set url
			curl_easy_setopt(curl,CURLOPT_URL,pct->url.c_str());
			//?
			curl_easy_setopt(curl,CURLOPT_FOLLOWLOCATION,1L);
			//progress enable
			curl_easy_setopt(curl,CURLOPT_NOPROGRESS, 0L);
			curl_easy_setopt(curl,CURLOPT_PROGRESSDATA,pct);
			curl_easy_setopt(curl,CURLOPT_PROGRESSFUNCTION, progressCallback);
			//write data
			curl_easy_setopt(curl,CURLOPT_WRITEDATA,&bufs);
			curl_easy_setopt(curl,CURLOPT_WRITEFUNCTION, writerCallback);

			switch( pct->method )
			{
			case GET:
				
				break;
			case POST:
				break;
			default:;
			}
			pct->state = LOADING;
			res = curl_easy_perform(curl);
			if(res == CURLE_OK){
				pair_t result = vector_t_merge( bufs );
				pct->size = result.first;
				pct->data = result.second;
				if( pct->state == LOADING ) //maybe CANCEL?
					pct->state = OK;
			}
			else
			{ //fails
				pct->err = curl_easy_strerror(res);
				pct->errcode = (int)res;
				if( pct->state == LOADING ) //maybe CANCEL?
					pct->state = FAILED;
			}
			//end
			if( pct->progressFunc )
				pct->progressFunc( pct );
			clean_vector_t( bufs );
		}
		curl_easy_cleanup(curl);
	}

	static bool g_bCurlInit = false;

	void do_thread_curl( curl_t *pct )
	{
		if( !g_bCurlInit )
		{
			curl_global_init(CURL_GLOBAL_ALL);
			//curl_global_cleanup(); --?
			g_bCurlInit = true;
		}
		pct->pthread = new std::thread(curl_thread_method,pct);
	}
}