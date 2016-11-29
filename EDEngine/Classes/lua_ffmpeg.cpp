#include "lua_ffmpeg.h"
#include "cocos2d.h"
#include "ff.h"
#include "ffdec.h"
#include "ffenc.h"
#include "live.h"
#include "CCLuaStack.h"
#include "CCLuaEngine.h"

USING_NS_CC;


#define VERSION "1.0"
#if LUA_VERSION_NUM < 502
#  define luaL_newlib(L,l) (lua_newtable(L), luaL_register(L,NULL,l))
#endif

#define LUA_FFMPEG_HANDLE "lua_ffmpeg_t"

/*
namespace ff
{
	int CCLog(const char* fmt, ...)
	{
		va_list argp;
		va_start(argp, fmt);
		cocos2d::CCLog(fmt, argp);
		va_end(argp);
		return 1;
	}
}
*/
MySpaceBegin

#if __cplusplus
extern "C" {
#endif

	static void createmeta(lua_State *L)
	{
		luaL_newmetatable(L, LUA_FFMPEG_HANDLE);
		lua_pushliteral(L, "__index");
		lua_pushvalue(L, -2);
		lua_rawset(L, -3);
	}
	static ff::FFVideo *get_ff_video(lua_State *L)
	{
		ff::FFVideo ** pv = (ff::FFVideo**)luaL_checkudata(L, 1, LUA_FFMPEG_HANDLE);
		if (pv && *pv)
			return *pv;
		return nullptr;
	}
	static int lua_refresh(lua_State *L)
	{
		ff::FFVideo *pfv = get_ff_video(L);
		if (pfv)
		{
			void * p = pfv->refresh();
			if (p)
			{
				lua_pushlightuserdata(L, p);
				return 1;
			}
		}
		return 0;
	}
	static int lua_close(lua_State *L)
	{
		ff::FFVideo *pfv = get_ff_video(L);
		if (pfv)
		{
			pfv->close();
			lua_pushboolean(L, true);
			return 1;
		}
		return 0;
	}
	static int lua_seek(lua_State *L)
	{
		ff::FFVideo *pfv = get_ff_video(L);
		if (pfv)
		{
			if (lua_isnumber(L, 2))
			{
				double t = lua_tonumber(L, 2);
				pfv->seek(t);
				lua_pushboolean(L, true);
				return 1;
			}
		}
		return 0;
	}
	static int lua_play(lua_State *L)
	{
		ff::FFVideo *pfv = get_ff_video(L);
		if (pfv)
		{
			pfv->play(); 
			lua_pushboolean(L, true);
			return 1;
		}
		return 0;
	}
	static int lua_pause(lua_State *L)
	{
		ff::FFVideo *pfv = get_ff_video(L);
		if (pfv)
		{
			pfv->pause();
			lua_pushboolean(L, true);
			return 1;
		}
		return 0;
	}
	static int lua_setPreloadNB(lua_State *L)
	{
		ff::FFVideo *pfv = get_ff_video(L);
		if (pfv)
		{
			if (lua_isnumber(L, 2))
			{
				int nb = lua_tointeger(L, 2);
				pfv->set_preload_nb(nb);
				lua_pushboolean(L, true);
				return 1;
			}
		}
		return 0;
	}
	static int lua_setPreloadByTime(lua_State *L)
	{
		ff::FFVideo *pfv = get_ff_video(L);
		if (pfv)
		{
			if (lua_isnumber(L, 2))
			{
				double b = lua_tonumber(L, 2);
				pfv->set_preload_time(b);
				lua_pushboolean(L, true);
				return 1;
			}
		}
		return 0;
	}
	static int lua_ffmpeg_index(lua_State *L)
	{
		ff::FFVideo ** pv = (ff::FFVideo**)luaL_checkudata(L, 1, LUA_FFMPEG_HANDLE);
		while(pv && *pv)
		{
			ff::FFVideo * pfv = *pv;
			if (!lua_isstring(L, 2))
				break;
			const char *key = lua_tostring(L, 2);
			if (!key)
				break;
			if (key[0] == 'i')
			{
				if (strcmp(key, "isOpen") == 0)
				{
					lua_pushboolean(L, pfv->isOpen());
				}
				else if (strcmp(key, "isPause") == 0)
				{
					lua_pushboolean(L, pfv->isPause());
				}
				else if (strcmp(key, "isPlaying") == 0)
				{
					lua_pushboolean(L, pfv->isPlaying());
				}
				else if(strcmp(key, "isSeeking") == 0 )
				{
					lua_pushboolean(L,pfv->isSeeking());
				}
				else if (strcmp(key, "isEnd") == 0)
				{
					lua_pushboolean(L, pfv->isEnd());
				}
				else if (strcmp(key, "isError") == 0)
				{
					lua_pushboolean(L, pfv->isError());
				}
				else
					lua_pushnil(L);
			}
			else if (key[0] == 'r')
			{
				if (strcmp(key, "refresh") == 0)
				{
					lua_pushcfunction(L, lua_refresh);
				}else
					lua_pushnil(L);
			}
			else
			{
				if (strcmp(key, "current") == 0)
					lua_pushnumber(L, pfv->cur());
				else if (strcmp(key, "preload")==0)
					lua_pushinteger(L, pfv->preload_packet_nb());
				else if (strcmp(key, "width") == 0)
					lua_pushinteger(L, pfv->width());
				else if (strcmp(key, "height") == 0)
					lua_pushinteger(L, pfv->height());
				else if (strcmp(key, "hasVideo") == 0)
					lua_pushboolean(L, pfv->hasVideo());
				else if (strcmp(key, "hasAudio") == 0)
					lua_pushboolean(L, pfv->hasAudio());
				else if (strcmp(key, "errorMsg") == 0)
					lua_pushstring(L, pfv->errorMsg());
				else if (strcmp(key, "close") == 0)
					lua_pushcfunction(L, lua_close);
				else if (strcmp(key, "seek") == 0)
					lua_pushcfunction(L, lua_seek);
				else if (strcmp(key, "length") == 0)
					lua_pushnumber(L, pfv->length());
				else if (strcmp(key, "play") == 0)
					lua_pushcfunction(L, lua_play);
				else if (strcmp(key, "pause") == 0)
					lua_pushcfunction(L, lua_pause);
				else if (strcmp(key, "setPreloadNB"))
					lua_pushcfunction(L, lua_setPreloadNB);
				else if (strcmp(key, "getPreloadByTime"))
					lua_pushinteger(L, pfv->preload_time());
				else if (strcmp(key, "setPreloadByTime"))
					lua_pushcfunction(L, lua_setPreloadByTime);
				else
					lua_pushnil(L);
			}
			return 1;
		}
		lua_pushnil(L);
		return 1;
	}

	static int lua_ffmpeg_gc(lua_State *L)
	{
		ff::FFVideo ** pv = (ff::FFVideo**)luaL_checkudata(L, 1, LUA_FFMPEG_HANDLE);
		if (pv && *pv)
		{
			ff::FFVideo * pfv = *pv;
			delete pfv;
		}
		return 0;
	}

	static const struct luaL_Reg lua_ffmpeg_methods[] =
	{
		{ "__index", lua_ffmpeg_index },
		{ "__gc", lua_ffmpeg_gc },
		{ NULL, NULL }
	};
	/*
		local stream = ff.new( filename,ONLY_AUDIO )
	*/
	static int new_ffmpeg(lua_State *L)
	{
		if (lua_isstring(L, 1))
		{
			const char *filename = luaL_checkstring(L, 1);
			if (filename)
			{
				ff::FFVideo * pffv = new ff::FFVideo();
				if (pffv)
				{
					bool ret = pffv->open(filename);
					if (!ret)
					{
						lua_pushnil(L);
						lua_pushstring(L, "open stream fail");
					}
					else
					{
						ff::FFVideo** pv = (ff::FFVideo**)lua_newuserdata(L, sizeof(ff::FFVideo*));
						*pv = pffv;
						luaL_getmetatable(L, LUA_FFMPEG_HANDLE);
						lua_setmetatable(L, -2);
						lua_pushnil(L);
					}
					return 2;
				}
				lua_pushnil(L);
				lua_pushstring(L, "out of memory");
				return 2;
			}
		}

		lua_pushnil(L);
		lua_pushstring(L, "invalid arguments");
		return 2;
	}

	static const struct luaL_Reg tclib[] =
	{
		{ "new", new_ffmpeg },
		{ NULL, NULL }
	};

	static int _currentRef = LUA_REFNIL;
	static int _prevResult = 0;
	struct tcf{
		ff::TranCode tc;
		float p;
		tcf(ff::TranCode _tc, float _p) :tc(_tc), p(_p){}
	};
	static void mainThreadProc(void *ptr)
	{
		cocos2d::LuaEngine *pEngine = cocos2d::LuaEngine::getInstance();
		if (pEngine&&_currentRef != LUA_REFNIL&&ptr)
		{
			cocos2d::LuaStack *pLuaStack = pEngine->getLuaStack();
			if (pLuaStack)
			{
				lua_State *L = pLuaStack->getLuaState();
				if (L){
					tcf * pcf = (tcf*)ptr;
					lua_rawgeti(L, LUA_REGISTRYINDEX, _currentRef);
					lua_pushinteger(L, pcf->tc);
					lua_pushnumber(L, pcf->p);
					delete pcf;
					_prevResult = pLuaStack->executeFunction(2);
				}
			}
		}
	}
	
	static int tcbc(ff::TranCode tc, float p)
	{
		cocos2d::Director *pDirector = cocos2d::Director::getInstance();
		if (pDirector)
		{
			auto scheduler = cocos2d::Director::getInstance()->getScheduler();
			if (scheduler)
			{
				if (pDirector == cocos2d::Director::getInstance()){
					tcf * pcf = new tcf(tc, p);

					scheduler->performFunctionInCocosThread_ext(mainThreadProc, (void *)pcf);
				}
				return _prevResult;
			}
		}
		return _prevResult;
	}

	//lua调用ffmpeg命令行,注意：函数每次只能调用一个
	static int cc_ffmpeg(lua_State *L)
	{
		const char * cmd = luaL_checkstring(L, 1);
		
		if (_currentRef != LUA_REFNIL){
			lua_unref(L, _currentRef);
			_currentRef = LUA_REFNIL;
		}
		if (lua_isfunction(L, 2)){
			lua_pushvalue(L, 2);
			_currentRef = lua_ref(L, 1);
		}
		_prevResult = 0;

		int ret = ff::ffmpeg(cmd, tcbc);

		lua_pushinteger(L,ret);
		
		return 1;
	}
	
	static int cc_camdevices(lua_State *L)
	{
		ff::AVDevice caps[8];

		int count = ff::ffCapDevicesList(caps, 8);
		lua_newtable(L);
		for (int m = 0; m < count; m++){
			lua_newtable(L);
			lua_pushstring(L, "show_name");
			lua_pushstring(L, caps[m].name);
			lua_settable(L, -3);
			lua_pushstring(L, "name");
			lua_pushstring(L, caps[m].alternative_name);
			lua_settable(L, -3);
			lua_pushstring(L, "type");
			if (caps[m].type == ff::AV_DEVICE_VIDEO){
				lua_pushstring(L, "video");
				lua_settable(L, -3);
				lua_newtable(L);
				lua_pushstring(L,"capability");
				lua_pushvalue(L, -2);
				lua_settable(L, -4);
				for(int i = 0; i < caps[m].capability_count; i++){
					lua_newtable(L);
					lua_pushstring(L, "min_w");
					lua_pushinteger(L, caps[m].capability[i].video.min_w);
					lua_settable(L, -3);
					lua_pushstring(L, "min_h");
					lua_pushinteger(L, caps[m].capability[i].video.min_h);
					lua_settable(L, -3);
					lua_pushstring(L, "max_w");
					lua_pushinteger(L, caps[m].capability[i].video.max_w);
					lua_settable(L, -3);
					lua_pushstring(L, "max_h");
					lua_pushinteger(L, caps[m].capability[i].video.max_h);
					lua_settable(L, -3);
					lua_pushstring(L, "min_fps");
					lua_pushinteger(L, caps[m].capability[i].video.min_fps);
					lua_settable(L, -3);
					lua_pushstring(L, "max_fps");
					lua_pushinteger(L, caps[m].capability[i].video.max_fps);
					lua_settable(L, -3);
					lua_pushstring(L, "pix_format");
					lua_pushstring(L, caps[m].capability[i].video.pix_format);
					lua_settable(L, -3);
					lua_pushstring(L, "codec_name");
					lua_pushstring(L, caps[m].capability[i].video.codec_name);
					lua_settable(L, -3);
					lua_rawseti(L, -2, i + 1);
				}	
			}else{
				lua_pushstring(L, "audio");
				lua_settable(L, -3);
				lua_newtable(L);
				lua_pushstring(L, "capability");
				lua_pushvalue(L, -2);
				lua_settable(L, -4);
				for(int i = 0; i < caps[m].capability_count; i++){
					lua_newtable(L);
					lua_pushstring(L, "min_ch");
					lua_pushinteger(L, caps[m].capability[i].audio.min_ch);
					lua_settable(L, -3);
					lua_pushstring(L, "min_bit");
					lua_pushinteger(L, caps[m].capability[i].audio.min_bit);
					lua_settable(L, -3);
					lua_pushstring(L, "min_rate");
					lua_pushinteger(L, caps[m].capability[i].audio.min_rate);
					lua_settable(L, -3);
					lua_pushstring(L, "max_ch");
					lua_pushinteger(L, caps[m].capability[i].audio.max_ch);
					lua_settable(L, -3);
					lua_pushstring(L, "max_bit");
					lua_pushinteger(L, caps[m].capability[i].audio.max_bit);
					lua_settable(L, -3);
					lua_pushstring(L, "max_rate");
					lua_pushinteger(L, caps[m].capability[i].audio.max_rate);
					lua_settable(L, -3);
					lua_pushstring(L, "sample_format");
					lua_pushstring(L, caps[m].capability[i].audio.sample_format);
					lua_settable(L, -3);
					lua_pushstring(L, "codec_name");
					lua_pushstring(L, caps[m].capability[i].audio.codec_name);
					lua_settable(L, -3);
					lua_rawseti(L, -2, i + 1);
				}
			}
			lua_pop(L, 1); //pop capability table
			lua_rawseti(L,-2,m+1);
		}
		return 1;
	}

	static int _liveRef = LUA_REFNIL;
	static std::thread * _liveThread = NULL;
	static void liveProc(void *ptr)
	{
		cocos2d::LuaEngine *pEngine = cocos2d::LuaEngine::getInstance();
		if (pEngine&&_liveRef != LUA_REFNIL&&ptr)
		{
			cocos2d::LuaStack *pLuaStack = pEngine->getLuaStack();
			if (pLuaStack)
			{
				lua_State *L = pLuaStack->getLuaState();
				if (L){
					ff::liveState * pls = (ff::liveState *)ptr;
					lua_rawgeti(L, LUA_REGISTRYINDEX, _liveRef);
					lua_pushinteger(L, pls->state);
					lua_pushnumber(L, (double)pls->nframes);
					lua_pushnumber(L, (double)pls->ntimes);
					lua_pushinteger(L, pls->encodeBufferSize);
					lua_pushinteger(L, pls->writeBufferSize);
					if (pls->nerror > 0 && pls->nerror < MAX_ERRORMSG_COUNT){
						lua_newtable(L);
						int b = 0;
						int e = pls->nerror;
						if (e != MAX_ERRORMSG_COUNT - 1){
							if (pls->errorMsg[e][0]){
								b = e + 1;
								e = MAX_ERRORMSG_COUNT;
							}
						}
						int idx = 0;
						for (int i = b; i < e; i++){
							lua_pushstring(L, pls->errorMsg[i]);
							lua_rawseti(L, -2, ++idx);
						}
						for (int i = 0; i < b; i++){
							lua_pushstring(L, pls->errorMsg[i]);
							lua_rawseti(L, -2, ++idx);
						}
						_prevResult = pLuaStack->executeFunction(6);
					}
					else{
						_prevResult = pLuaStack->executeFunction(5);
					}
					
					if (pls->state == ff::LIVE_END){
						lua_unref(L, _liveRef);
						_liveRef = LUA_REFNIL;
						if (_liveThread){
							_liveThread->join();
							delete _liveThread;
							_liveThread = NULL;
						}
					}
					delete pls;
				}
			}
		}
	}
	static cocos2d::Director *_pDirector = NULL;
	static int liveCallback(ff::liveState *pls)
	{
		cocos2d::Director *pDirector = cocos2d::Director::getInstance();
		if (pDirector && pls && pDirector == _pDirector)
		{
			auto scheduler = cocos2d::Director::getInstance()->getScheduler();
			if (scheduler)
			{
				if (pDirector == cocos2d::Director::getInstance()){
					ff::liveState * pc = new ff::liveState();
					*pc = *pls;
					pls->nerror = 0;
					scheduler->performFunctionInCocosThread_ext(liveProc, (void *)pc);
				}
				return _prevResult;
			}
		}
		else{
			_prevResult = 0;
			_liveThread = NULL;
			_liveRef = LUA_REFNIL;
			return 1;
		}
		return _prevResult;
	}

	static int cc_live(lua_State *L)
	{
		int ret = 0;
		const char * errMsg = NULL;
		while (lua_istable(L, 1) && lua_isfunction(L, 2) && _liveRef==LUA_REFNIL){
			const char * file = NULL;
			const char * video_name = NULL;
			const char * audio_name = NULL;
			const char * pix_fmt = NULL;
			const char * sample_fmt = NULL;
			int w, h, fps,videoBitRate;
			int freq, audioBitRate;
			int ow, oh, ofps;

			lua_pushstring(L, "address");
			lua_gettable(L, 1);
			if (lua_isstring(L, -1))
				file = luaL_checkstring(L, -1);
			else{
				errMsg = "missing address";
				break;
			}
			lua_pop(L, 1);

			lua_pushstring(L, "cam_name");
			lua_gettable(L, 1);
			if (lua_isstring(L,-1))
				video_name = luaL_checkstring(L, -1);
			lua_pop(L, 1);

			lua_pushstring(L, "phone_name");
			lua_gettable(L, 1);
			if (lua_isstring(L, -1))
				audio_name = luaL_checkstring(L, -1);
			lua_pop(L, 1);
			if (video_name){
				lua_pushstring(L, "pix_fmt");
				lua_gettable(L, 1);
				if (lua_isstring(L, -1))
					pix_fmt = luaL_checkstring(L, -1);
				else{
					errMsg = "missing pix_fmt";
					break;
				}
				lua_pop(L, 1);

				lua_pushstring(L, "cam_w");
				lua_gettable(L, 1);
				if (lua_isnumber(L, -1))
					w = luaL_checkint(L, -1);
				else{
					errMsg = "missing cam_w";
					break;
				}
				lua_pop(L, 1);

				lua_pushstring(L, "cam_h");
				lua_gettable(L, 1);
				if (lua_isnumber(L, -1))
					h = luaL_checkint(L, -1);
				else{
					errMsg = "missing cam_h";
					break;
				}
				lua_pop(L, 1);

				lua_pushstring(L, "cam_fps");
				lua_gettable(L, 1);
				if (lua_isnumber(L, -1))
					fps = luaL_checkint(L, -1);
				else{
					errMsg = "missing cam_fps";
					break;
				}
				lua_pop(L, 1);

				lua_pushstring(L, "video_bitrate");
				lua_gettable(L, 1);
				if (lua_isnumber(L, -1))
					videoBitRate = luaL_checkint(L, -1);
				else{
					errMsg = "missing video_bitrate";
					break;
				}
				lua_pop(L, 1);
			}

			if (audio_name){
				lua_pushstring(L, "audio_bitrate");
				lua_gettable(L, 1);
				if (lua_isnumber(L, -1))
					audioBitRate = luaL_checkint(L, -1);
				else{
					errMsg = "missing audio_bitrate";
					break;
				}
				lua_pop(L, 1);

				lua_pushstring(L, "sample_freq");
				lua_gettable(L, 1);
				if (lua_isnumber(L, -1))
					freq = luaL_checkint(L, -1);
				else{
					errMsg = "missing sample_freq";
					break;
				}
				lua_pop(L, 1);

				lua_pushstring(L, "sample_fmt");
				lua_gettable(L, 1);
				if (lua_isstring(L, -1))
					sample_fmt = luaL_checkstring(L, -1);
				else{
					errMsg = "missing sample_fmt";
					break;
				}
				lua_pop(L, 1);
			}
			lua_pushstring(L, "live_w");
			lua_gettable(L, 1);
			if (lua_isnumber(L, -1))
				ow = luaL_checkint(L, -1);
			else{
				errMsg = "missing live_w";
				break;
			}
			lua_pop(L, 1);

			lua_pushstring(L, "live_h");
			lua_gettable(L, 1);
			if (lua_isnumber(L, -1))
				oh = luaL_checkint(L, -1);
			else{
				errMsg = "missing live_h";
				break;
			}
			lua_pop(L, 1);

			lua_pushstring(L, "live_fps");
			lua_gettable(L, 1);
			if (lua_isnumber(L, -1))
				ofps = luaL_checkint(L, -1);
			else{
				errMsg = "missing live_fps";
				break;
			}

			lua_pop(L, 1);

			lua_pushvalue(L, 2);
			_liveRef = lua_ref(L, 1);
			_prevResult = 0;

			_pDirector = cocos2d::Director::getInstance();
			
			_liveThread = new std::thread([](const char *file, const char *video_name, 
				int w, int h, int fps, const char *pix_fmt,int videoBitRate,
				const char *audio_name,int freq,const char* sample_fmt,int audioBitRate,
				int ow,int oh,int ofps){
				ff::liveOnRtmp(file,
					video_name, w, h, fps, pix_fmt, videoBitRate,
					audio_name, freq, sample_fmt, audioBitRate,
					ow, oh, ofps,
					liveCallback);
			}, file, video_name, w, h, fps, pix_fmt, videoBitRate,
				audio_name, freq, sample_fmt, audioBitRate,
				ow, oh, ofps);
			ret = 1;
			break;
		}

		lua_pushboolean(L, ret);
		if (errMsg){
			lua_pushstring(L, errMsg);
			return 2;
		}
		else{
			return 1;
		}
	}
	
	static int cc_autofocus(lua_State *L)
	{
		if (lua_isboolean(L, 1)){
			int b = lua_toboolean(L, 1);
			lua_pushboolean(L,ff::ffAutoFocus(b));
			return 1;
		}
		return 0;
	}

	static int cc_camopen(lua_State *L)
	{
		return 0;
	}

	static int cc_camclose(lua_State *L)
	{
		return 0;
	}

	static int cc_camrefresh(lua_State *L)
	{
		return 0;
	}

	void release_ffmpeg()
	{
		_prevResult = 0;
		_liveThread = NULL;
		_liveRef = LUA_REFNIL;
		_currentRef = LUA_REFNIL;
	}

	static void set_info(lua_State *L)
	{
		lua_pushliteral(L, "_COPYRIGHT");
		lua_pushliteral(L, "Copyright (C) 2015");
		lua_settable(L, -3);
		lua_pushliteral(L, "_DESCRIPTION");
		lua_pushliteral(L, "LuaFFMpeg is lua library.");
		lua_settable(L, -3);
		lua_pushliteral(L, "_VERSION");
		lua_pushliteral(L, "LuaFFMpeg" VERSION);
		lua_settable(L, -3);
	}

	int luaopen_ffmpeg(lua_State *L)
	{
		//全局函数
		lua_register(L, "cc_ffmpeg", cc_ffmpeg);
		lua_register(L, "cc_camdevices", cc_camdevices);
		lua_register(L, "cc_live", cc_live);
		lua_register(L, "cc_autofocus", cc_autofocus);
		lua_register(L, "cc_camopen", cc_camopen);
		lua_register(L, "cc_camclose", cc_camclose);
		lua_register(L, "cc_camrefresh", cc_camrefresh);

		createmeta(L);
		luaL_openlib(L, 0, lua_ffmpeg_methods, 0);
		lua_newtable(L);
		luaL_newlib(L, tclib);
		set_info(L);
		return 1;
	}

#if __cplusplus
}
MySpaceEnd
#endif