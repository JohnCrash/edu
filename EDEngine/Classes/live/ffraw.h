#ifndef _FFRAW_H_
#define _FFRAW_H_

#include <inttypes.h>
#include "ffcommon.h"

namespace ff
{
#define NUM_DATA_POINTERS 8
	enum AVRawType
	{
		RAW_IMAGE,
		RAW_AUDIO,
	};
	enum TimePts
	{
		TP_CAPTURE = 0,
		TP_DECODE,
		TP_SWS1,
		TP_READFRAME_RETURN,
		TP_ADDFRAME,
		TP_POPFRAME,
		TP_SWS2,
		TP_ENCODE,
		TP_FREE,
		TP_TYPE,
		TP_COUNT,
	};
	struct AVRaw
	{
		uint8_t *data[NUM_DATA_POINTERS];
		int linesize[NUM_DATA_POINTERS];
		AVBufferRef *buf[NUM_DATA_POINTERS];
		int width;
		int height;
		int channels;
		int samples;
		int format;
		int seek_sample;
		int size;
		int ref;
		int recount;
		int64_t pts;
		AVRational time_base;
		AVRawType type;
		AVRaw *next;
#ifdef _LIVE_DEBUG
		double *timePts;
#endif
	};
#ifdef _LIVE_DEBUG
#define PUT_TPS(raw,tps) raw->timePts[tps] = clock()
#define PUT_TPS_BY_VALUE(raw,tps,v) raw->timePts[tps] = v
#define PUT_TPS_TYPE(raw,type) raw->timePts[TP_TYPE] = (double)type
#else
#define PUT_TPS
#define PUT_TPS_BY_VALUE
#define PUT_TPS_TYPE
#endif
	/*
	* 分配或者释放图像和音频数据
	*/
	AVRaw *make_image_raw(int format, int w, int h);
	AVRaw *make_audio_raw(int format, int channel, int samples);
	AVRaw *make_image_from_frame(AVFrame * frame);
	AVRaw *make_audio_from_frame(AVFrame * frame);
	AVRaw *raw_ref(AVRaw * praw);
	void free_raw(AVRaw * praw);
	int frame_ref_raw(AVRaw * praw, AVFrame * frame);
	
	void list_push_raw(AVRaw ** head, AVRaw ** tail, AVRaw *praw);
	AVRaw * list_pop_raw(AVRaw ** head, AVRaw **tail);
}
#endif