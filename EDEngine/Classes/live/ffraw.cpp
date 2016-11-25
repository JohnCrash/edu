#include "ffraw.h"
#include "ffenc.h"

namespace ff
{
	static void buffer_free(void * opaque, uint8_t *data)
	{
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

			for (int i = 0; i < FF_ARRAY_ELEMS(frame->buf); i++){
				if ( frame->buf[i] && frame->data[i] ){
					praw->buf[i] = av_buffer_ref(frame->buf[i]);
					if (!praw->buf[i]){
						av_log(NULL, AV_LOG_FATAL, "make_from_frame av_buffer_ref return NULL\n");
						free(praw);
						return NULL;
					}
					praw->data[i] = frame->data[i];
					praw->linesize[i] = frame->linesize[i];
					praw->size += praw->buf[i]->size;
				}
				else if (frame->data[i]){
					int ret;
					//没有使用缓冲区对象，这里创建缓冲区对象并做(复制操作)
					if (type == RAW_IMAGE){
						ret = av_image_alloc(praw->data, praw->linesize, praw->width, praw->height, (AVPixelFormat)praw->format, 32);
						if (ret < 0){
							free(praw);
							av_log(NULL, AV_LOG_FATAL, "make_from_frame out of memory. @av_image_alloc\n");
							return NULL;
						}
						praw->size = ret;
						for (int i = 0; i < NUM_DATA_POINTERS; i++){
							if (praw->data[i])
								praw->buf[i] = av_buffer_create(praw->data[i], praw->linesize[i]*praw->height, buffer_free, NULL, AV_BUFFER_FLAG_READONLY);
						}
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
						for (int i = 0; i < NUM_DATA_POINTERS; i++){
							if (praw->data[i])
								praw->buf[i] = av_buffer_create(praw->data[i], praw->linesize[i], buffer_free, NULL, AV_BUFFER_FLAG_READONLY);
						}
						av_samples_copy(praw->data, frame->data, 0, 0, praw->samples, praw->channels,(AVSampleFormat)praw->format);
					}
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

		while (praw)
		{
			memset(praw, 0, sizeof(AVRaw));
			praw->type = RAW_IMAGE;
			praw->format = format;
			praw->width = w;
			praw->height = h;
			praw->ref = 1;
			praw->recount = 1;
			int ret = av_image_alloc(praw->data, praw->linesize, w, h, (AVPixelFormat)format, 32);
			if (ret < 0)
			{
				char errmsg[ERROR_BUFFER_SIZE];
				av_strerror(ret, errmsg, ERROR_BUFFER_SIZE);
				av_log(NULL, AV_LOG_FATAL, "make_image_raw av_image_alloc : %s \n", errmsg);
				break;
			}
			praw->size = ret;
			for (int i = 0; i < NUM_DATA_POINTERS; i++){
				if (praw->data[i]){
					praw->buf[i] = av_buffer_create(praw->data[i], praw->linesize[i]*h, buffer_free, NULL, AV_BUFFER_FLAG_READONLY);
				}
			}
			return praw;
		}

		if (praw)
		{
			free(praw);
		}
		else
		{
			av_log(NULL, AV_LOG_FATAL, "make_image_raw out of memory.\n");
		}
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
			int ret = av_samples_alloc(praw->data, praw->linesize, channel, samples, (AVSampleFormat)format, 0);
			if (ret < 0)
			{
				char errmsg[ERROR_BUFFER_SIZE];
				av_strerror(ret, errmsg, ERROR_BUFFER_SIZE);
				av_log(NULL, AV_LOG_FATAL, "make_audio_raw av_samples_alloc : %s \n", errmsg);
				break;
			}
			praw->size = ret;
			for (int i = 0; i < NUM_DATA_POINTERS; i++){
				if (praw->data[i]){
					praw->buf[i] = av_buffer_create(praw->data[i], praw->linesize[i], buffer_free, NULL, AV_BUFFER_FLAG_READONLY);
				}
			}
			return praw;
		}

		if (praw)
		{
			free(praw);
		}
		else
		{
			av_log(NULL, AV_LOG_FATAL, "make_audio_raw out of memory.\n");
		}
		praw = NULL;
		return praw;
	}
}