#include "ffraw.h"
#include "ffenc.h"

namespace ff
{
	double clock()
	{
		double clock;
#if CC_TARGET_PLATFORM == CC_PLATFORM_WIN32
		clock = (double)GetTickCount()/1000.0;
#else
		timeval tv;
		gettimeofday(&tv, NULL);
		clock = (double)tv.tv_sec*1000.0 + (double)(tv.tv_usec) / 1000.0;
#endif
		return clock;
	}

	static int n_images = 0;
	static int n_audios = 0;
/* 这里显示帧的全生存周期的时间分布情况 */
#define _FRAME_LOG 0

	static void buffer_free(void * opaque, uint8_t *data)
	{
#if defined(_LIVE_DEBUG) && _FRAME_LOG==1
		if (opaque){
			double * pt = (double *)opaque;
			double po = pt[0];
			AVRawType type = (AVRawType)((int)pt[TP_TYPE]);
			pt[TP_FREE] = clock();
#define PTT(tp) (int)((pt[tp] - po)*1000)
#define PTS(tp) (int)((pt[tp+1] - pt[tp])*1000)
			if (type == RAW_IMAGE){
				DEBUG("cap	decode	sws1	read	add	pop	sws2	encode	free");
	//			DEBUG("%d	%d	%d	%d	%d	%d	%d	%d	%d",
	//				0, PTT(TP_DECODE), PTT(TP_SWS1), PTT(TP_READFRAME_RETURN), PTT(TP_ADDFRAME),
	//				PTT(TP_POPFRAME), PTT(TP_SWS2), PTT(TP_ENCODE), PTT(TP_FREE));
				DEBUG("%d	%d	%d	%d	%d	%d	%d	%d",
					PTS(TP_CAPTURE), PTS(TP_DECODE), PTS(TP_SWS1), PTS(TP_READFRAME_RETURN), PTS(TP_ADDFRAME),
					PTS(TP_POPFRAME), PTS(TP_SWS2), PTS(TP_ENCODE));
			}
		}
#endif

#ifdef _LIVE_DEBUG
		av_free(opaque);
#endif
		av_free(data);
	}

	static AVRaw *make_from_frame(AVFrame * frame, AVRawType type)
	{
		AVRaw * praw = (AVRaw*)malloc(sizeof(AVRaw));

		if(praw){
			memset(praw, 0, sizeof(AVRaw));
			praw->type = type;

			praw->width = frame->width;
			praw->height = frame->height;
			praw->pts = frame->pts;
			praw->format = frame->format;

			praw->channels = frame->channels;
			praw->samples = frame->nb_samples;

			praw->ref = 1;
#ifdef _LIVE_DEBUG
			praw->timePts = (double*)av_mallocz(sizeof(double)*TP_COUNT);
#endif			
			PUT_TPS_TYPE(praw, type);

			if (av_frame_is_writable(frame)){
				for (int i = 0; i < FF_ARRAY_ELEMS(frame->buf); i++){
					praw->data[i] = frame->data[i];
					praw->linesize[i] = frame->linesize[i];
					if (frame->buf[i]){
						praw->buf[i] = av_buffer_ref(frame->buf[i]);
						praw->size += praw->buf[i]->size;
					}
				}
				n_images++;
			}
			else{
				int ret;
				if (type == RAW_IMAGE){
					ret = av_image_alloc(praw->data, praw->linesize, praw->width, praw->height, (AVPixelFormat)praw->format, 32);
					if (ret < 0){
						free(praw);
						av_log(NULL, AV_LOG_FATAL, "make_from_frame out of memory. @av_image_alloc\n");
						return NULL;
					}
					praw->size = ret;
#ifdef _LIVE_DEBUG
					praw->buf[0] = av_buffer_create(praw->data[0], ret, buffer_free, praw->timePts, AV_BUFFER_FLAG_READONLY);
#else
					praw->buf[0] = av_buffer_create(praw->data[0], ret, buffer_free, NULL, AV_BUFFER_FLAG_READONLY);
#endif
					av_image_copy(praw->data, praw->linesize, (const uint8_t **)frame->data, frame->linesize, (AVPixelFormat)praw->format, praw->width, praw->height);
				}
				else if (type == RAW_AUDIO){
					ret = av_samples_alloc(praw->data, praw->linesize, praw->channels, praw->samples, (AVSampleFormat)praw->format, 0);
					if (ret < 0){
						free(praw);
						av_log(NULL, AV_LOG_FATAL, "make_from_frame out of memory. @av_samples_alloc\n");
						return NULL;
					}
					praw->size = ret;
#ifdef _LIVE_DEBUG
					praw->buf[0] = av_buffer_create(praw->data[0], ret, buffer_free, praw->timePts, AV_BUFFER_FLAG_READONLY);
#else
					praw->buf[0] = av_buffer_create(praw->data[0], ret, buffer_free, NULL, AV_BUFFER_FLAG_READONLY);
#endif
					av_samples_copy(praw->data, frame->data, 0, 0, praw->samples, praw->channels, (AVSampleFormat)praw->format);
				}
			}
			return praw;
		}
		av_log(NULL, AV_LOG_FATAL, "make_from_frame out of memory.\n");
		return NULL;
	}

	/**
	* \brief 从一个帧创建一个视频AVRaw数据
	*/
	AVRaw *make_image_from_frame(AVFrame * frame)
	{
		return make_from_frame(frame, RAW_IMAGE);
	}

	/**
	* \brief 从一个帧创建一个音频AVRaw数据
	*/
	AVRaw *make_audio_from_frame(AVFrame * frame)
	{
		return make_from_frame(frame, RAW_AUDIO);
	}

	AVRaw *raw_ref(AVRaw * praw)
	{
		praw->ref++;
		return praw;
	}

	void free_raw(AVRaw * praw)
	{
		praw->ref--;
		if (praw->ref <= 0){
			for (int i = 0; i < NUM_DATA_POINTERS; i++){
				if (praw->buf[i])
					av_buffer_unref(&praw->buf[i]);
			}
			free(praw);
		}
	}

	AVRaw *make_image_raw(int format, int w, int h)
	{
		AVRaw * praw = (AVRaw*)malloc(sizeof(AVRaw));

		while (praw){
			memset(praw, 0, sizeof(AVRaw));
			praw->type = RAW_IMAGE;
			praw->format = format;
			praw->width = w;
			praw->height = h;
			praw->ref = 1;
			praw->recount = 1;
#ifdef _LIVE_DEBUG
			praw->timePts = (double*)av_mallocz(sizeof(double)*TP_COUNT);
#endif
			PUT_TPS_TYPE(praw, RAW_IMAGE);

			int ret = av_image_alloc(praw->data, praw->linesize, w, h, (AVPixelFormat)format, 32);
			if (ret < 0){
				char errmsg[ERROR_BUFFER_SIZE];
				av_strerror(ret, errmsg, ERROR_BUFFER_SIZE);
				av_log(NULL, AV_LOG_FATAL, "make_image_raw av_image_alloc : %s \n", errmsg);
				break;
			}
			praw->size = ret;
#ifdef _LIVE_DEBUG
			praw->buf[0] = av_buffer_create(praw->data[0], ret, buffer_free, praw->timePts, AV_BUFFER_FLAG_READONLY);
#else
			praw->buf[0] = av_buffer_create(praw->data[0], ret, buffer_free, NULL, AV_BUFFER_FLAG_READONLY);
#endif
			return praw;
		}

		if (praw)
			free(praw);
		else
			av_log(NULL, AV_LOG_FATAL, "make_image_raw out of memory.\n");

		praw = NULL;
		return praw;
	}

	AVRaw *make_audio_raw(int format, int channel, int samples)
	{
		AVRaw * praw = (AVRaw*)malloc(sizeof(AVRaw));
		while (praw)
		{
			memset(praw, 0, sizeof(AVRaw));
			praw->type = RAW_AUDIO;
			praw->format = format;
			praw->channels = channel;
			praw->samples = samples;
			praw->ref = 1;
#ifdef _LIVE_DEBUG
			praw->timePts = (double*)av_mallocz(sizeof(double)*TP_COUNT);
#endif
			PUT_TPS_TYPE(praw, RAW_AUDIO);

			int ret = av_samples_alloc(praw->data, praw->linesize, channel, samples, (AVSampleFormat)format, 0);
			if (ret < 0){
				char errmsg[ERROR_BUFFER_SIZE];
				av_strerror(ret, errmsg, ERROR_BUFFER_SIZE);
				av_log(NULL, AV_LOG_FATAL, "make_audio_raw av_samples_alloc : %s \n", errmsg);
				break;
			}
			praw->size = ret;
#ifdef _LIVE_DEBUG
			praw->buf[0] = av_buffer_create(praw->data[0], ret, buffer_free, praw->timePts, AV_BUFFER_FLAG_READONLY);
#else
			praw->buf[0] = av_buffer_create(praw->data[0], ret, buffer_free, NULL, AV_BUFFER_FLAG_READONLY);
#endif
			return praw;
		}

		if (praw)
			free(praw);
		else
			av_log(NULL, AV_LOG_FATAL, "make_audio_raw out of memory.\n");

		praw = NULL;
		return praw;
	}

	int frame_ref_raw(AVRaw * praw, AVFrame * frame)
	{
		if (praw->type == RAW_IMAGE){
			av_frame_unref(frame);

			frame->width = praw->width;
			frame->height = praw->height;
			frame->format = praw->format;

			for (int i = 0; i < NUM_DATA_POINTERS; i++){
				frame->data[i] = praw->data[i];
				frame->linesize[i] = praw->linesize[i];
				if (praw->buf[i]){
					frame->buf[i] = av_buffer_ref(praw->buf[i]);
				}
			}
		}
		else{
			av_frame_unref(frame);

			frame->sample_rate = praw->samples;
			frame->channels = praw->channels;
			frame->format = praw->format;

			for (int i = 0; i < NUM_DATA_POINTERS; i++){
				frame->data[i] = praw->data[i];
				frame->linesize[i] = praw->linesize[i];
				if (praw->buf[i]){
					frame->buf[i] = av_buffer_ref(praw->buf[i]);
				}
			}
		}
		return 0;
	}
}