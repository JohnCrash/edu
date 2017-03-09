#include "ff.h"
#include "ffdepends.h"
#include "cocos2d.h"


namespace ff
{
/*
    static double cc_clock()
    {
        double clock;
#if CC_TARGET_PLATFORM == CC_PLATFORM_WIN32
        clock = (double)GetTickCount();
#else
        timeval tv;
        gettimeofday(&tv,NULL);
        clock = (double)tv.tv_sec*1000.0 + (double)(tv.tv_usec)/1000.0;
#endif
        return clock;
    }
*/
    VideoPixelFormat FFVideo::getPixelFormat()
    {
        return VIDEO_PIX_YUV420P;
    }

	FFVideo::FFVideo() :_ctx(nullptr)
	{
#if _LGH_TEST_
		_nb_min_threshold = 30;
		_nb_max_threshold = 60;
#else
		_nb_min_threshold = 0;
		_nb_max_threshold = 0;
#endif
			
		initFF();
	}

	FFVideo::~FFVideo()
	{
		close();
	}

	//获取内部状态对象
	int		FFVideo::getState(void*	pobjData)
	{
		int nRes = sizeof(VideoState) + sizeof(AVFormatContext);
		VideoState* _vs = (VideoState*)_ctx;
		if (pobjData)
		{
            memset(pobjData,0,nRes);
			memcpy(pobjData, _vs, nRes);
			AVFormatContext*	pobjIC = (AVFormatContext*)((char*)pobjData + sizeof(VideoState));
            if(_vs->ic)
                memcpy(pobjIC, _vs->ic, sizeof(AVFormatContext));
			((VideoState*)pobjData)->ic = pobjIC;
		}
		return nRes;
	}

	//设置内部状态对象
	void	FFVideo::setState(void*	pobjData, int nLen)
	{
		if (_ctx)
		{
			free(_ctx);
			_ctx = nullptr;
		}
		int nRes = sizeof(VideoState) + sizeof(AVFormatContext);
		if (pobjData)
		{
			if (nLen == nRes)
			{
				_ctx = malloc(nRes);
				memcpy(_ctx, pobjData, nRes);
				AVFormatContext*	pobjIC = (AVFormatContext*)((char*)_ctx + sizeof(VideoState));
				((VideoState*)_ctx)->ic = pobjIC;
			}
		}
	}

	bool FFVideo::open(const char *url)
	{
		_first = true;

		_cur = url;
        _ctx = stream_open(url, NULL);
		return _ctx != nullptr;
	}

	std::string FFVideo::currentOpen() const
	{
		return _cur;
	}

	void FFVideo::set_live_lagnb(int mi,int ma)
	{
		_nb_min_threshold = mi;
		_nb_max_threshold = ma;
	}

	void FFVideo::seek(double t)
	{
		VideoState* _vs = (VideoState*)_ctx;
		if (_vs)
		{
			if (t > length())
				t = length();
			if (t < 0)
				t = 0;
			double pos = cur_clock();
			int64_t ts = t * AV_TIME_BASE;
			int64_t ref = (int64_t)((t - pos) *AV_TIME_BASE);
			stream_seek(_vs, ts, ref, 0);
		}
	}

	bool FFVideo::isEnd() const
	{
		if (isOpen())
		{
			VideoState* is = (VideoState*)_ctx;
			if (is)
			{
				if (is && is->stream_resetting)return false;

				//直播时如果发生网络异常结束(eof=1),表示视频已经结束
				if (is->ic && is->eof && !strncmp(is->filename, "rtmp:", 5))
					return true;

				if (!is->paused && (!is->audio_st || (is->auddec.finished == is->audioq.serial && frame_queue_nb_remaining(&is->sampq) == 0)) &&
					((!is->video_st || (is->viddec.finished == is->videoq.serial && frame_queue_nb_remaining(&is->pictq) == 0)) || 
					(is->video_st && is->audio_st && is->video_st->codecpar->codec_id == AV_CODEC_ID_MJPEG && is->audio_st->codecpar->codec_id == AV_CODEC_ID_MP3)))
					return true;
			}
		}
		return false;
	}

	void FFVideo::set_preload_nb(int n)
	{
		VideoState* is = (VideoState*)_ctx;
		if (is)
		{
			is->nMIN_FRAMES = n;
		}
	}

	int FFVideo::preload_packet_nb() const
	{
		VideoState* is = (VideoState*)_ctx;
		if (is)
		{
			if (hasVideo())
				return is->videoq.nb_packets;
			else if (hasAudio())
				return is->audioq.nb_packets;
		}
		return -1;
	}

	double FFVideo::cur_clock() const
	{
		VideoState* _vs = (VideoState*)_ctx;
		if (_vs)
		{
			double pos;
			pos = get_master_clock(_vs);
			if (isnan(pos))
				pos = (double)_vs->seek_pos / AV_TIME_BASE;
			return pos;
		}
		return -1;
	}

	double FFVideo::cur() const
	{
		VideoState* _vs = (VideoState*)_ctx;
		if (_vs)
		{
		//	if (_vs->current > 0)
		//		return _vs->current;
		//	else
			return FFMIN(FFMAX(cur_clock(),0),length());
		}
		return -1;
	}

	double FFVideo::length() const
	{
		VideoState* _vs = (VideoState*)_ctx;
		if (_vs && _vs->ic && isOpen() )
		{
			if (_vs->ic->duration == AV_NOPTS_VALUE || _vs->ic->duration < 0 )
				return 0;
			return (double)_vs->ic->duration / 1000000LL;
		}
		return 0;
	}

	bool FFVideo::hasVideo() const
	{
		VideoState* _vs = (VideoState*)_ctx;
		if (_vs)
		{
			return _vs->video_st ? true : false;
		}
		return false;
	}

	bool FFVideo::hasAudio() const
	{
		VideoState* _vs = (VideoState*)_ctx;
		if (_vs)
		{
			return _vs->audio_st ? true : false;
		}
		return false;
	}

	bool FFVideo::isPause() const
	{
		return isOpen() && is_stream_pause((VideoState*)_ctx);
	}

	bool FFVideo::isSeeking() const
	{
		if (!isOpen()) return false;

		VideoState* _vs = (VideoState*)_ctx;
		
		if (_vs && _vs->stream_resetting)return true;

		if (_vs == NULL) return false;
		return _vs->seek_req?true:false;
	}

	bool FFVideo::isPlaying() const
	{
		if (!isOpen()) return false;
		return !isPause();
	}

	bool FFVideo::isOpen() const
	{
		VideoState* _vs = (VideoState*)_ctx;
		if (_vs && !_vs->stream_resetting)
			return  (_vs && (_vs->audio_st || _vs->video_st));
		else if (_vs && _vs->stream_resetting)
			return true;
		else
			return false;
	}

	int FFVideo::codec_width() const
	{
		if (!isOpen())return -1;
		VideoState* _vs = (VideoState*)_ctx;
		if (!_vs->video_st)return -1;
		if (!_vs->video_st->codec)return -1;
		return _vs->video_st->codec->width;
	}

	int FFVideo::codec_height() const
	{
		if (!isOpen())return -1;
		VideoState* _vs = (VideoState*)_ctx;
		if (!_vs->video_st)return -1;
		if (!_vs->video_st->codec)return -1;
		return _vs->video_st->codec->height;
	}

	int FFVideo::width() const
	{
		if (!isOpen())return -1;
		VideoState* _vs = (VideoState*)_ctx;
		return _vs->width;
	}

	int FFVideo::height() const
	{
		if (!isOpen())return -1;
		VideoState* _vs = (VideoState*)_ctx;
		return _vs->height;
	}

	void *FFVideo::refresh()
	{
		VideoState* _vs = (VideoState*)_ctx;
		if (_vs && !_vs->stream_resetting)
		{
			/*
			 * 在直播时当缓冲区大于阀值，导致延时明显时。清空缓冲区(可能导致同步问题?)
			 */
			double r = 1.0 / 30.0;
			if (!is_stream_pause((VideoState*)_ctx))
			{
				video_refresh(_vs, &r);
			}
			if (_vs->pyuv420p.w > 0 && _vs->pyuv420p.h > 0 )
			{
				if (_first && !_vs->realtime)
				{
					pause();
					_first = false;
				}
				return &_vs->pyuv420p;
			}
		}
		return nullptr;
	}

	bool FFVideo::isReconnect() const
	{
		VideoState* _vs = (VideoState*)_ctx;
		if (_vs){
			return _vs->stream_resetting ? true : false;
		}
		return false;
	}

    void *FFVideo::allocRgbBufferFormYuv420p(void *pyuv)
    {
		return yuv420pToRgb((yuv420p *)pyuv);
    }
    
    void FFVideo::freeRgbBuffer(void * prgb)
    {
        freeRgb(prgb);
    }

	void FFVideo::pause()
	{
		if (isOpen() && !is_stream_pause((VideoState*)_ctx) && !isSeeking())
		{
			_first = false;
			toggle_pause((VideoState*)_ctx);
		}
	}

	void FFVideo::play()
	{
		if (isOpen() && is_stream_pause((VideoState*)_ctx) && !isSeeking())
		{
			_first = false;
			toggle_pause((VideoState*)_ctx);
		}
	}

	void FFVideo::close()
	{
		if (_ctx)
		{
			stream_close((VideoState*)_ctx);
			_ctx = nullptr;
		}
	}

	bool FFVideo::isError() const
	{
		VideoState* _vs = (VideoState*)_ctx;
		if (_vs && !_vs->stream_resetting)
		{
			return _vs->errcode != 0;
		}
		return false;
	}

	const char * FFVideo::errorMsg() const
	{
		VideoState* _vs = (VideoState*)_ctx;
		if (_vs)
		{
			return _vs->errmsg;
		}
		return nullptr;
	}

	static double calc_avg_pocket_rate(AVStream *st)
	{
		if (st){
			if (st->avg_frame_rate.den>0 && st->avg_frame_rate.num>0) 
				return (double)st->avg_frame_rate.num / (double)st->avg_frame_rate.den;

			if (st->time_base.den > 0){
				double tt = st->duration* (double)st->time_base.num / (double)st->time_base.den;
				if ( tt > 0 )
					return (double)st->nb_frames / tt;
			}
		}
		return -1;
	}

	static double calc_stream_preload_time(PacketQueue *pq, AVStream *st)
	{
		if (pq && pq->last_pkt && pq->first_pkt && st && st->time_base.den > 0){
			if (pq->last_pkt->pkt.buf != NULL){
				return (double)(pq->last_pkt->pkt.pts - pq->first_pkt->pkt.pts) *(double)st->time_base.num / (double)st->time_base.den;
			}
			else{
				MyAVPacketList *last = NULL;
				for (MyAVPacketList *it = pq->first_pkt; it != NULL; it = it->next){
					if (it->pkt.buf != NULL)
						last = it;
					else
						break;
				}
				if (last){
					return (double)(last->pkt.pts - pq->first_pkt->pkt.pts) *(double)st->time_base.num / (double)st->time_base.den;
				}
			}
		}
		return 0;
	}

	double FFVideo::preload_time()
	{
		VideoState* is = (VideoState*)_ctx;
		if (is)
		{
			return FFMAX(calc_stream_preload_time(&is->videoq,is->video_st),calc_stream_preload_time(&is->audioq,is->audio_st));
		}
		return -1;
	}

	bool FFVideo::set_preload_time(double t)
	{
		VideoState* is = (VideoState*)_ctx;
		if (is && t>=0 )
		{
			if (!is->video_st)return false;
			double apr = calc_avg_pocket_rate(is->video_st);
			if (apr > 0){
				set_preload_nb((int)(apr*t));
				return true;
			}
			apr = calc_avg_pocket_rate(is->audio_st);
			if (apr > 0){
				set_preload_nb((int)(apr*t));
				return true;
			}
			set_preload_nb(150);
		}
		return false;
	}
}
