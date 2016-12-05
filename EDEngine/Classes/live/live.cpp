#include "ffcommon.h"
#include "live.h"
#include "ffenc.h"
#include "ffdec.h"

namespace ff
{
#define AUDIO_CHANNEL 2
#define AUDIO_CHANNELBIT 16
#define MAX_NSYN 120
#define MAX_ASYN 5
	static const char * preset[] = {
		"placebo",
		"veryslow",
		"slower",
		"slow",
		"medium",
		"fast",
		"faster",
		"veryfast",
		"superfast",
		"ultrafast", //9
	};
	
	static const enum AVPixelFormat libx264_fmts[] = {
		AV_PIX_FMT_YUV420P,
		AV_PIX_FMT_YUVJ420P,
		AV_PIX_FMT_YUV422P,
		AV_PIX_FMT_YUVJ422P,
		AV_PIX_FMT_YUV444P,
		AV_PIX_FMT_YUVJ444P,
		AV_PIX_FMT_NV12,
		AV_PIX_FMT_NV16,
		AV_PIX_FMT_NV21
	};
	
#ifdef _NSY_DEBUG
	#define	NSY_DEBUG DEBUG
#else
	#define	NSY_DEBUG
#endif

	static void liveLoop(AVDecodeCtx * pdc, AVEncodeContext * pec, liveCB cb, liveState* pls)
	{
		int ret, nsyn,ncsyn,nsynacc;
		AVRational audio_time_base, video_time_base;
		AVRaw * praw = NULL;
		int64_t ctimer; 
		int64_t nsamples = 0; 
		int64_t nframe = 0; 
		int64_t begin_pts = 0; 
		int64_t nsyndt = 0;
		int64_t nsynbt = 0;
		int64_t stimer = av_gettime_relative(); 
		nsyn = 0;
		ncsyn = 0;
		nsynacc = 0;
		if (pdc->has_audio)
			audio_time_base = pdc->_audio_st->codec->time_base;
		if (pdc->has_video)
			video_time_base = pdc->_video_st->codec->time_base;
		while (1){
			ctimer = av_gettime_relative();
			praw = ffReadFrame(pdc);

			if (!praw){
				av_log(NULL, AV_LOG_ERROR, "liveLoop break : praw = NULL\n");
				break;
			}
			if (!pdc->has_audio && begin_pts == 0){
				begin_pts = praw->pts;
				stimer = av_gettime_relative();
			}

			if (praw->type == RAW_IMAGE && pdc->has_video){
				if (!pdc->has_audio){
					int64_t bf = av_rescale_q(ctimer - stimer, AVRational{1,AV_TIME_BASE},video_time_base);
					ncsyn = bf - nframe;
					if (abs(ncsyn) > MAX_NSYN){
						av_log(NULL, AV_LOG_ERROR, "liveLoop break : liveLoop video frame synchronize error, nsyn > MAX_NSYN , nsyn = %d\n", nsyn);
						break;
					}
				}
				else if ( nsyndt>0 && nsynbt!=0 ){
					int nsynp = (int)(nsyn*(ctimer - nsynbt) / nsyndt);
					
					ncsyn = nsynp - nsynacc;
					nsynacc += ncsyn;
				}
				else
					ncsyn = 0;

				if (ncsyn >= 0 && ncsyn < MAX_NSYN ){
					praw->recount += ncsyn;
					nframe += praw->recount;
					if (ret = ffAddFrame(pec, praw) < 0){
						av_log(NULL, AV_LOG_ERROR, "liveLoop break : ret < 0 , ret = %d\n",ret);
						break;
					}
					NSY_DEBUG("[V] ncsyn:%d timestrap:%" PRId64" time: %.4fs\n",
								ncsyn, praw->pts, (double)(ctimer - stimer) / (double)AV_TIME_BASE);
				}
				else if (ncsyn > MAX_NSYN){
					av_log(NULL, AV_LOG_ERROR, "liveLoop break : video frame make up error, nsyn > MAX_NSYN , ncsyn = %d\n", ncsyn);
					break;
				}
				else{
					NSY_DEBUG("discard video frame\n");
				}
				NSY_DEBUG("[V] ncsyn:%d timestrap:%" PRId64" time: %.4fs\n",
					ncsyn, praw->pts, (double)(ctimer - stimer) / (double)AV_TIME_BASE);
			}
			else if (praw->type == RAW_AUDIO && pdc->has_audio){
				if (begin_pts == 0){
					begin_pts = praw->pts;
					stimer = av_gettime_relative();
				}
				nsamples += praw->samples;
				if( ret=ffAddFrame(pec, praw) < 0 )
					break;

				int64_t at = av_rescale_q(nsamples, audio_time_base, AVRational{ 1, AV_TIME_BASE });
				int64_t vt = av_rescale_q(nframe, video_time_base, AVRational{ 1, AV_TIME_BASE });
				nsyndt = av_rescale_q(praw->samples, audio_time_base, AVRational{ 1, AV_TIME_BASE });
				nsyn = (int)av_rescale_q((at - vt), AVRational{ 1, AV_TIME_BASE }, video_time_base);
				nsynbt = ctimer;
				nsyn += nsynacc;
				if (abs(nsyn) > MAX_NSYN || abs(nsynacc) > MAX_NSYN ){
					av_log(NULL, AV_LOG_ERROR, "liveLoop break : video frame synchronize error, nsyn > MAX_NSYN , nsyn = %d nsynacc = %d\n", nsyn, nsynacc);
					if (cb && pls){
						pls->state = LIVE_ERROR;
						cb(pls);
					}
					break;
				}

				double dsyn = (double)abs(ctimer - stimer - at)/(double)AV_TIME_BASE;
				if (dsyn > MAX_ASYN){
					av_log(NULL, AV_LOG_ERROR, "liveLoop break : audio frame synchronize error, dsyn > MAX_ASYN , nsyn = %.4f\n", dsyn);
					if (cb && pls){
						pls->state = LIVE_ERROR;
						cb(pls);
					}
					break;
				}
				NSY_DEBUG("[A] nsyn:%d dsyn:%.4fs acc=%d timestrap:%" PRId64" time: %.4fs bs:%.2fmb\n",
					nsyn, dsyn, nsynacc, praw->pts, (double)(ctimer - stimer) / (double)AV_TIME_BASE, (double)ffGetBufferSizeKB(pec) / 1024.0);

				nsynacc = 0;
			}

			if (pls && pls->quit)break;
			if (nframe % 2 == 0){
				if (cb && pls){
					pls->nframes = nframe;
					pls->ntimes = ctimer - stimer;
					pls->encodeBufferSize = ffGetBufferSizeKB(pec);
					pls->writeBufferSize = ffGetWriteBufferSizeKB(pec);
					if (cb(pls)){
						av_log(NULL, AV_LOG_ERROR, "liveLoop break : nframe % 2 == 0 ,nframe = %d\n",nframe);
						break;
					}
				}
			}
			free_raw(praw);
		} //while
		free_raw(praw);
	}
	static liveState state;
    #if defined(_LIVE_DEBUG)
	static void to_cclog(const char *format, va_list arg)
	{
        //simple fix x264_close log format error
        if(format[0]=='m'&&format[1]=='b'&&format[2]==' '&&format[3]=='B')
            return;
		char szLine[1024 * 8];
		vsnprintf(szLine, sizeof(szLine), format, arg);
		cocos2d::CCLog(szLine, "");
	}
    #endif
	static void log_callback(void * acl, int level, const char *format, va_list arg)
	{
		if (level == AV_LOG_ERROR || level == AV_LOG_FATAL){
			if (state.nerror > MAX_ERRORMSG_COUNT)
				state.nerror = 0;
			vsnprintf(state.errorMsg[state.nerror++], MAX_ERRORMSG_LENGTH, format, arg);
		}
		av_log_default_callback(acl, level, format, arg);
    #if defined(_LIVE_DEBUG)
	//	to_cclog(format,arg);
	#endif
	}

	static void callbc(liveCB cb, cbType t,const char *errMsg){
		if (cb){
			state.state = t;
			cb(&state);
		}
	}
	void liveOnRtmp(
		const char * rtmp_publisher,
		const char * camera_name, int w, int h, int fps, const char * pix_fmt_name, int vbitRate,
		const char * phone_name, int rate, const char * sample_fmt_name, int abitRate,
		int ow, int oh, int ofps,
		liveCB cb)
	{
		AVDecodeCtx * pdc = NULL;
		AVEncodeContext * pec = NULL;
		AVDictionary *opt = NULL;
		AVCodecID vid, aid;
		AVPixelFormat pixFmt = pix_fmt_name ? av_get_pix_fmt(pix_fmt_name) : AV_PIX_FMT_NONE;
		AVSampleFormat sampleFmt = sample_fmt_name ? av_get_sample_fmt(sample_fmt_name) : AV_SAMPLE_FMT_NONE;
		
		const char *outFmt;

		/*
		 * android 系统的相机系统有一个独特的格式'yv12',数据和AV_PIX_FMT_YUV420P都相同
		 * 但是要交换u和v的数据区,AV_PIX_FMT_YVU420P是自定义的图像类型
		 */
		if (pixFmt == AV_PIX_FMT_NONE && pix_fmt_name){
			if (strcmp(pix_fmt_name, "yv12") == 0){
				pixFmt = AV_PIX_FMT_YVU420P;
			}
		}

		DEBUG("liveOnRtmp rtmp_publisher:%s\ncamera_name = %s,w=%d h=%d fps=%d,pix_fmt_name=%s,vbitRate=%d,\n\
						phone_name = %s , rate=%d sample_fmt_name=%s abitRate=%d\n\
						ow = %d,oh = %d,ofps = %d",
						rtmp_publisher ? rtmp_publisher:"", camera_name ? camera_name : "", 
						w, h, fps, pix_fmt_name ? pix_fmt_name : "", vbitRate,
						phone_name ? phone_name:"", rate, sample_fmt_name ? sample_fmt_name : "", 
						abitRate,ow,oh,ofps);

		memset(&state, 0, sizeof(state));

		callbc(cb, LIVE_BEGIN, NULL);

		av_log_set_callback(log_callback);

		ffInit();

		av_dict_set(&opt, "strict", "-2", 0);
		av_dict_set(&opt, "threads", "4", 0);

		av_dict_set(&opt, "crf", "22", 0);

		av_dict_set(&opt, "preset", preset[9], 0);

		//av_dict_set(&opt, "tune", "zerolatency", 0);

		//av_dict_set(&opt, "opencl", "true", 0);

		while (1){
			/*
			 * 直播,FIXME:忽略直播的独立帧率，目前和输入帧率相同
			 */
			vid = camera_name ? AV_CODEC_ID_H264 : AV_CODEC_ID_NONE;
			aid = phone_name ? AV_CODEC_ID_AAC : AV_CODEC_ID_NONE;
			if ((rtmp_publisher[0] == 'R' || rtmp_publisher[0] == 'r') &&
				(rtmp_publisher[1] == 'T' || rtmp_publisher[1] == 't') &&
				(rtmp_publisher[2] == 'M' || rtmp_publisher[2] == 'm') &&
				(rtmp_publisher[3] == 'P' || rtmp_publisher[3] == 'p')){
				outFmt = "flv";
			}
			else{
				outFmt = "mp4";
			}
			pec = ffCreateEncodeContext(rtmp_publisher, outFmt, ow, oh, AVRational{ fps, 1 }, vbitRate, vid,
				rate, abitRate, aid,opt);
			if (!pec){
				callbc(cb, LIVE_ERROR, "ffCreateEncodeContext failed");
				break;
			}

            /*
             * 这里打开捕获设备，并马上进入直播循环
             */
            pdc = ffCreateCapDeviceDecodeContext(camera_name, w, h, fps, pixFmt,
				phone_name, AUDIO_CHANNEL, AUDIO_CHANNELBIT, rate, opt);
            if (!pdc || !pdc->_video_st || !pdc->_video_st->codec){
				callbc(cb, LIVE_ERROR, "ffCreateCapDeviceDecodeContext failed");
                break;
            }
			
			if (ffReadFrameFormat(pdc, ow, oh, AV_PIX_FMT_YUV420P,
				AUDIO_CHANNEL, rate, sampleFmt) < 0){
				callbc(cb, LIVE_ERROR, "ffReadFrameFormat failed");
				break;
			}
			if (ffAddFrameFormat(pec, ow, oh, AV_PIX_FMT_YUV420P,
				AUDIO_CHANNEL, rate, sampleFmt) < 0){
				callbc(cb, LIVE_ERROR, "ffAddFrameFormat failed");
				break;
			}
            state.state = LIVE_FRAME;
			liveLoop(pdc,pec,cb,&state);
			break;
		}

		DEBUG("=================liveOnRtmp be close==================");
		//马上把俘获设备关闭
		if (pdc){
			ffCloseDecodeContext(pdc);
		}
		//将未发送的数据发送出去然后关闭
		if (pec){
			ffFlush(pec);
			ffCloseEncodeContext(pec);
		}
        DEBUG("=================liveOnRtmp closed==================");
		//通知回调，直播结束
		if (state.nerror)
			callbc(cb, LIVE_ERROR, NULL);
			
		callbc(cb, LIVE_END, NULL);

		av_log_set_callback(av_log_default_callback);
		//DEBUG("=================liveOnRtmp free opt==================");
		//av_dict_free(&opt);
		DEBUG("=================liveOnRtmp end==================");
	}

	/*
	 * 新的直播接口
	 */
	static AVDecodeCtx * _openingDC = NULL;
	static AVEncodeContext * _openingEC = NULL;
	static std::thread * _liveLoopThread = NULL;
	static liveCB _liveCB = NULL;
	static int _liveLoopStop = 0;
	static int _liveLoopState = 0;
	static void live_loop_proc()
	{
		AVRaw * praw;
		while (!_liveLoopStop){
			_liveLoopState = 0;
			if (_openingDC){
				if (!_openingEC){
					praw = ffReadFrame(_openingDC);
					if (praw){
						free_raw(praw);
					}
					else break;
				}
				else{
					_liveLoopState = 1;
					liveLoop(_openingDC, _openingEC, _liveCB, &state);
					ffFlush(_openingEC);
					ffCloseEncodeContext(_openingEC);
					callbc(_liveCB, LIVE_END, NULL);
					_openingEC = NULL;
				}
			}
			else break;
		}

		callbc(_liveCB, LIVE_CLOSE, NULL);
		if (_openingDC){
			ffCloseDecodeContext(_openingDC);
			_openingDC = NULL;
		}
		av_log_set_callback(av_log_default_callback);
		
		_liveLoopState = 2;
	}
	void setLiveCB(liveCB cb)
	{
		_liveCB = cb;
	}
	int liveOpenCapDevices(
		const char * camera_name, int w, int h, int fps, const char * pix_fmt_name,
		const char * phone_name, int rate, const char * sample_fmt_name)
	{
		AVDecodeCtx * pdc = NULL;
		AVDictionary *opt = NULL;
		AVCodecID vid, aid;
		AVPixelFormat pixFmt = pix_fmt_name ? av_get_pix_fmt(pix_fmt_name) : AV_PIX_FMT_NONE;
		AVSampleFormat sampleFmt = sample_fmt_name ? av_get_sample_fmt(sample_fmt_name) : AV_SAMPLE_FMT_NONE;

		const char *outFmt;

		if (_openingDC || _liveLoopThread)return 1;

		_liveLoopStop = 0;
		_liveLoopState = 0;
		/*
		* android 系统的相机系统有一个独特的格式'yv12',数据和AV_PIX_FMT_YUV420P都相同
		* 但是要交换u和v的数据区,AV_PIX_FMT_YVU420P是自定义的图像类型
		*/
		if (pixFmt == AV_PIX_FMT_NONE && pix_fmt_name){
			if (strcmp(pix_fmt_name, "yv12") == 0){
				pixFmt = AV_PIX_FMT_YVU420P;
			}
		}

		memset(&state, 0, sizeof(state));

		av_log_set_callback(log_callback);

		ffInit();

		av_dict_set(&opt, "strict", "-2", 0);
		av_dict_set(&opt, "threads", "4", 0);

		av_dict_set(&opt, "crf", "22", 0);

		av_dict_set(&opt, "preset", preset[9], 0);

		while (1){
			/*
			* 这里打开捕获设备，并马上进入直播循环
			*/
			pdc = ffCreateCapDeviceDecodeContext(camera_name, w, h, fps, pixFmt,
				phone_name, AUDIO_CHANNEL, AUDIO_CHANNELBIT, rate, opt);
			if (!pdc || !pdc->_video_st || !pdc->_video_st->codec){
				callbc(_liveCB, LIVE_ERROR, "ffCreateCapDeviceDecodeContext failed");
				if (pdc){
					ffCloseDecodeContext(pdc);
				}
				return 0;
			}
			if (ffReadFrameFormat(pdc, w, h, AV_PIX_FMT_YUV420P,
				AUDIO_CHANNEL, rate, sampleFmt) < 0){
				callbc(_liveCB, LIVE_ERROR, "ffReadFrameFormat failed");
				ffCloseDecodeContext(pdc);
				return 0;
			}
			break;
		}
		_openingDC = pdc;
		callbc(_liveCB, LIVE_OPEN, NULL);
		_liveLoopThread = new std::thread(live_loop_proc);
		return 1;
	}

	int liveStart(const char * rtmp_publisher, int w, int h, int fps, int vbitRate, int abitRate)
	{
		if (!_openingDC)return 0;
		if (_openingEC)return 1;

		AVEncodeContext * pec = NULL;
		AVDictionary *opt = NULL;
		AVCodecID vid, aid;
		int rate;
		AVSampleFormat sampleFmt;
		const char *outFmt;

		memset(&state, 0, sizeof(state));

		if (_openingDC->_audio_st && _openingDC->_audio_st->codecpar){
			rate = _openingDC->_audio_st->codecpar->sample_rate;
			sampleFmt = (AVSampleFormat)_openingDC->_audio_st->codecpar->format;
		}
		else{
			rate = _openingDC->_actx.swr_out_sample_rate;
			sampleFmt = _openingDC->_actx.swr_out_sample_fmt;
		}
		callbc(_liveCB, LIVE_BEGIN, NULL);

		av_dict_set(&opt, "strict", "-2", 0);
		av_dict_set(&opt, "threads", "4", 0);

		av_dict_set(&opt, "crf", "22", 0);

		av_dict_set(&opt, "preset", preset[9], 0);

		while (1){
			if ((rtmp_publisher[0] == 'R' || rtmp_publisher[0] == 'r') &&
				(rtmp_publisher[1] == 'T' || rtmp_publisher[1] == 't') &&
				(rtmp_publisher[2] == 'M' || rtmp_publisher[2] == 'm') &&
				(rtmp_publisher[3] == 'P' || rtmp_publisher[3] == 'p')){
				outFmt = "flv";
			}
			else{
				outFmt = "mp4";
			}
			vid = AV_CODEC_ID_H264;
			aid = AV_CODEC_ID_AAC;
			pec = ffCreateEncodeContext(rtmp_publisher, outFmt, w, h, AVRational{ fps, 1 }, vbitRate, vid,
				rate, abitRate, aid, opt);
			if (!pec){
				callbc(_liveCB, LIVE_ERROR, "ffCreateEncodeContext failed");
				return 0;
			}

			if (ffReadFrameFormat(_openingDC, w, h, AV_PIX_FMT_YUV420P,
				AUDIO_CHANNEL, rate, sampleFmt) < 0){
				callbc(_liveCB, LIVE_ERROR, "ffReadFrameFormat failed");
				ffCloseEncodeContext(pec);
				return 0;
			}
			if (ffAddFrameFormat(pec, w, h, AV_PIX_FMT_YUV420P,
				AUDIO_CHANNEL, rate, sampleFmt) < 0){
				callbc(_liveCB, LIVE_ERROR, "ffAddFrameFormat failed");
				ffCloseEncodeContext(pec);
				return 0;
			}
			break;
		}
		_openingEC = pec;
		callbc(_liveCB, LIVE_BEGIN, NULL);
		return 1;
	}

	int liveStop()
	{
		if (_openingEC){
			state.quit = 1;
		}
		return 1;
	}

	int liveCloseCapDevices()
	{
		if (_liveLoopThread){
			liveStop();
			_liveLoopStop = 1; //结束直播循环
			_liveLoopThread->join();
			delete _liveLoopThread;
			_liveLoopThread = NULL;
		}
		return 1;
	}
}
