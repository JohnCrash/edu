#include "ffdec.h"
#include "live.h"

#ifdef __ANDROID__
extern "C"
{
	int android_autoFoucs(int b);
}
#endif

namespace ff
{
#ifdef WIN32
	#define CAP_DEVICE_NAME "dshow"
#elif __ANDROID__
	#define CAP_DEVICE_NAME "android_camera"
#elif __APPLE__
	#define CAP_DEVICE_NAME "avfoundation2"
#endif

	static int open_audio(AVDecodeCtx *pec, AVCodecID audio_codec_id, AVDictionary *opt_arg)
	{
		AVCodecContext *c;
		int nb_samples;
		AVDictionary *opt = NULL;

		c = pec->_audio_st->codec;

		if(av_decode_init(c,audio_codec_id,opt_arg)!=0){
			av_log(NULL, AV_LOG_FATAL, "Could not init decoder '%s'\n", avcodec_get_name(audio_codec_id));
			return -1;
		}

		if (c->codec->capabilities & AV_CODEC_CAP_VARIABLE_FRAME_SIZE)
			nb_samples = 10000;
		else
			nb_samples = c->frame_size;

		pec->_actx.st = pec->_audio_st;

		pec->_actx.frame = alloc_audio_frame(c->sample_fmt, c->channel_layout,
			c->sample_rate, nb_samples);

		if (!pec->_actx.frame)
			return -1;
		av_frame_make_writable(pec->_actx.frame);
		return 0;
	}

	static int open_video(AVDecodeCtx *pec, AVCodecID video_codec_id, AVDictionary *opt_arg)
	{
		AVCodecContext *c = pec->_video_st->codec;
		AVDictionary *opt = NULL;

		if(av_decode_init(c,video_codec_id,opt_arg)!=0){
			av_log(NULL, AV_LOG_FATAL, "Could not init decoder '%s'\n", avcodec_get_name(video_codec_id));
			return -1;
		}

		pec->_vctx.st = pec->_video_st;
		/* allocate and init a re-usable frame */
		pec->_vctx.frame = alloc_picture(c->pix_fmt, c->width, c->height);
		if (!pec->_vctx.frame) {
			av_log(NULL, AV_LOG_FATAL, "Could not allocate video frame\n");
			return -1;
		}
		av_frame_make_writable(pec->_vctx.frame);
		return 0;
	}

	AVDecodeCtx *ffCreateDecodeContext(
		const char * filename, AVDictionary *opt_arg
		)
	{
		int ret;
		AVInputFormat *file_iformat = NULL;
		AVDecodeCtx * pdc;
		AVDictionary * opt = NULL;

		ffInit();
		
		pdc = (AVDecodeCtx *)malloc(sizeof(AVDecodeCtx));
		while (pdc)
		{
			memset(pdc, 0, sizeof(AVDecodeCtx));
			pdc->_fileName = strdup(filename);
			pdc->_ctx = avformat_alloc_context();
			if (!pdc->_ctx)
			{
				av_log(NULL, AV_LOG_FATAL, "ffCreateDecodeContext : could not allocate context.\n");
				break;
			}

			if (filename && strstr(filename, "video=") == filename){
				file_iformat = av_find_input_format(CAP_DEVICE_NAME);
				if (!file_iformat){
					av_log(NULL, AV_LOG_FATAL, "Unknown input format: '%s'\n",CAP_DEVICE_NAME);
					break;
				}
			}
			av_dict_copy(&opt, opt_arg, 0);
			ret = avformat_open_input(&pdc->_ctx, filename, file_iformat, &opt);
			av_dict_free(&opt);
			opt = NULL;
			if (ret < 0)
			{
				char errmsg[ERROR_BUFFER_SIZE];
				av_strerror(ret, errmsg, ERROR_BUFFER_SIZE);
				av_log(NULL, AV_LOG_FATAL, "ffCreateDecodeContext %s.\n", errmsg);
				break;
			}
			av_format_inject_global_side_data(pdc->_ctx);

			av_dict_copy(&opt, opt_arg, 0);
			ret = avformat_find_stream_info(pdc->_ctx, NULL);
			av_dict_free(&opt);
			opt = NULL;
			if (ret < 0)
			{
				char errmsg[ERROR_BUFFER_SIZE];
				av_strerror(ret, errmsg, ERROR_BUFFER_SIZE);
				av_log(NULL, AV_LOG_FATAL, "ffCreateDecodeContext %s.\n", errmsg);
				break;
			}

			ret = av_find_best_stream(pdc->_ctx, AVMEDIA_TYPE_VIDEO, -1, -1, NULL, 0);
			if (ret >= 0)
			{
				pdc->has_video = 1;
				pdc->_video_st = pdc->_ctx->streams[ret];
				pdc->_video_st_index = ret;
			}
			ret = av_find_best_stream(pdc->_ctx, AVMEDIA_TYPE_AUDIO, -1, -1, NULL, 0);
			if (ret >= 0)
			{
				pdc->has_audio = 1;
				pdc->_audio_st = pdc->_ctx->streams[ret];
				pdc->_audio_st_index = ret;
			}
			if (pdc->has_video)
			{
				if (open_video(pdc, pdc->_video_st->codec->codec_id, NULL) < 0)
				{
					ffCloseDecodeContext(pdc);
					return NULL;
				}
				pdc->encode_video = 1;
			}
			if (pdc->has_audio)
			{
				if (open_audio(pdc, pdc->_audio_st->codec->codec_id, NULL) < 0)
				{
					ffCloseDecodeContext(pdc);
					return NULL;
				}
				pdc->encode_audio = 1;
			}
			pdc->preview_mutex = new mutex_t();
			return pdc;
		}

		ffCloseDecodeContext(pdc);
		return NULL;
	}

	static void ffFreeAVCtx(AVCtx *ctx)
	{
		if (ctx->frame)
			av_frame_free(&ctx->frame);
		if (ctx->swr_ctx)
			swr_free(&ctx->swr_ctx);
		if (ctx->sws_ctx)
			sws_freeContext(ctx->sws_ctx);
	}

	void ffCloseDecodeContext(AVDecodeCtx *pdc)
	{
		if (pdc)
		{
			if (pdc->_fileName)
				free((void*)pdc->_fileName);
			if (pdc->_ctx)
			{
				avformat_close_input(&pdc->_ctx);
			}

			ffFreeAVCtx(&pdc->_vctx);
			ffFreeAVCtx(&pdc->_actx);

			{
				mutex_lock_t lk(*pdc->preview_mutex);

			}
			delete pdc->preview_mutex;

			free(pdc);
		}
	}

	AVRational ffGetFrameRate(AVDecodeCtx *pdc)
	{
		if (pdc && pdc->_video_st&&pdc->_video_st->codec)
		{
			return pdc->_video_st->r_frame_rate;
		}
		AVRational ret;
		ret.den = 1;
		ret.num = 1;
		return ret;
	}

	int ffGetFrameWidth(AVDecodeCtx *pdc)
	{
		if (pdc && pdc->_video_st &&pdc->_video_st->codec)
		{
			return pdc->_video_st->codec->width;
		}
		return -1;
	}

	int ffGetFrameHeight(AVDecodeCtx *pdc)
	{
		if (pdc && pdc->_video_st &&pdc->_video_st->codec)
		{
			return pdc->_video_st->codec->height;
		}
		return -1;
	}

	static void put_tp(AVRaw * praw, double pt0, double pt1, double pt2)
	{
		PUT_TPS_BY_VALUE(praw, TP_CAPTURE,pt0);
		PUT_TPS_BY_VALUE(praw, TP_DECODE, pt1);
		PUT_TPS_BY_VALUE(praw, TP_SWS1, pt2);
		PUT_TPS(praw, TP_READFRAME_RETURN);
	}
	/*
	 * 从文件或者设备中解码帧数据 
	 */
	AVRaw * ffReadFrame(AVDecodeCtx *pdc)
	{
		int ret;
		AVPacket pkt;
		AVCodecContext *ctx;
		AVFrame * frame;
		double pt0, pt1,pt2;
		while (true)
		{
			pt0 = clock();
			ret = av_read_frame(pdc->_ctx, &pkt);

			if (ret < 0)
			{
				char errmsg[ERROR_BUFFER_SIZE];
				av_strerror(ret, errmsg, ERROR_BUFFER_SIZE);
				av_log(NULL, AV_LOG_FATAL, "ffReadFrame av_read_frame : %s.\n", errmsg);
				return NULL;
			}
			if (pkt.stream_index == pdc->_video_st_index)
			{
				ctx = pdc->_video_st->codec;
				frame = pdc->_vctx.frame;

				pt1 = clock();
				ret = avcodec_send_packet(ctx, &pkt);
				if (ret == AVERROR_EOF || ret == AVERROR(EINVAL)){
					return NULL;
				}
				ret = avcodec_receive_frame(ctx, frame);
				if (ret==0)
				{
					AVRaw * praw;
					AVCtx * avctx = &pdc->_vctx;
					pt2 = clock();
					if (avctx->sws_ctx){
						praw = make_image_raw(avctx->sws_out_fmt, avctx->sws_out_w, avctx->sws_out_h);
						if (avctx->isyv12){
							uint8_t * data[NUM_DATA_POINTERS];
							data[0] = praw->data[0];
							data[1] = praw->data[2];
							data[2] = praw->data[1];
							sws_scale(avctx->sws_ctx,
								(const uint8_t * const *)frame->data, frame->linesize,
								0, frame->height,
								praw->data, praw->linesize);
						}
						else{
							sws_scale(avctx->sws_ctx,
								(const uint8_t * const *)frame->data, frame->linesize,
								0, frame->height,
								praw->data, praw->linesize);
						}
					}
					else{
						praw = make_image_from_frame(frame);
					}
					praw->time_base = ctx->pkt_timebase;
					av_packet_unref(&pkt);
					av_frame_unref(frame);
					
					put_tp(praw, pt0, pt1, pt2);
					addPreviewFrame(praw);
					return praw;
				}
				else if (ret == AVERROR_EOF || ret == AVERROR(EINVAL)){
					return NULL;
				}
			}
			else if (pkt.stream_index == pdc->_audio_st_index)
			{
				ctx = pdc->_audio_st->codec;
				frame = pdc->_actx.frame;

				pt1 = clock();

				ret = avcodec_send_packet(ctx, &pkt);
				if (ret == AVERROR_EOF || ret == AVERROR(EINVAL)){
					return NULL;
				}
				ret = avcodec_receive_frame(ctx, frame);
				if (ret == 0){
					AVRaw * praw;
					AVCtx * avctx = &pdc->_actx;

					pt2 = clock();
					//设置了输出格式转换
					if (avctx->swr_ctx){
						praw = make_audio_raw(avctx->swr_out_sample_fmt, avctx->swr_out_channel, avctx->swr_out_sample_rate);
						/* convert to destination format */
						ret = swr_convert(avctx->swr_ctx,
							praw->data, praw->samples, (const uint8_t**)frame->data, frame->nb_samples);
						if (ret < 0) {
							av_log(NULL, AV_LOG_FATAL, "ffReadFrame @swr_convert error while converting\n");
							return NULL;
						}
					}
					else{
						praw = make_audio_from_frame(frame);
					}
					praw->time_base = ctx->pkt_timebase;
					av_packet_unref(&pkt);
					av_frame_unref(frame);

					put_tp(praw, pt0, pt1, pt2);
					return praw;
				}
				else if (ret == AVERROR_EOF || ret == AVERROR(EINVAL)){
					return NULL;
				}
			}

			av_packet_unref(&pkt);
		} //while
		return NULL;
	}

	static AVDevice * s_pdevices = NULL;
	static int s_i = 0;
	AVDeviceType s_type = AV_DEVICE_NONE;
	static int s_nmax = 0;
#ifdef __APPLE__
    static void log_callback(void * acl, int level, const char *format, va_list arg)
    {
        AVDevice * pdevices = s_pdevices;
        
        if (pdevices && level == AV_LOG_INFO && s_i < s_nmax){
            if (strstr(format, "AVFoundation video devices:\n") == format){
                s_type = AV_DEVICE_VIDEO;
            }
            else if (strstr(format, "AVFoundation audio devices:\n") == format){
                s_type = AV_DEVICE_AUDIO;
            }
            else if(strstr(format,"[%d] %s\n") == format ){
                if(pdevices[s_i].capability_count>0)
                    s_i++;
                snprintf(pdevices[s_i].alternative_name,MAX_DEVICE_NAME_LENGTH,"%d",va_arg(arg,int));
                strcpy(pdevices[s_i].name, va_arg(arg, char*));
                pdevices[s_i].type = s_type;
            }
            else if(strstr(format,"AVFoundation list_devices end") == format ){
                s_i++;
            }
            else if(strstr(format,"%s %dx%d %f-%f\n") == format ){
                int index = pdevices[s_i].capability_count;
                if (index < MAX_CAPABILITY_COUNT && index >= 0){
                    char * pixfmt = va_arg(arg,char *);
                    int w = va_arg(arg,int);
                    int h = va_arg(arg,int);
                    double min_framerate = va_arg(arg,double);
                    double max_framerate = va_arg(arg,double);
                    pdevices[s_i].capability[index].video.min_w = w;
                    pdevices[s_i].capability[index].video.min_h = h;
                    pdevices[s_i].capability[index].video.min_fps = min_framerate;
                    pdevices[s_i].capability[index].video.max_w = w;
                    pdevices[s_i].capability[index].video.max_h = h;
                    pdevices[s_i].capability[index].video.max_fps = max_framerate;
                    strcpy(pdevices[s_i].capability[index].video.pix_format,pixfmt);
                    pdevices[s_i].capability_count++;
                }
            }
            else if(strstr(format,"format:%s chanel:%d bits:%d samples:(%d-%d)\n")== format ){
                int index = pdevices[s_i].capability_count;
                if (index < MAX_CAPABILITY_COUNT && index >= 0){
                    char * fmt = va_arg(arg,char *);
                    int ch = va_arg(arg,int);
                    int bits = va_arg(arg,int);
                    int min_samples = va_arg(arg,int);
                    int max_samples = va_arg(arg,int);
                    pdevices[s_i].capability[index].audio.min_ch = ch;
                    pdevices[s_i].capability[index].audio.min_bit = bits;
                    pdevices[s_i].capability[index].audio.min_rate = min_samples;
                    pdevices[s_i].capability[index].audio.max_ch = ch;
                    pdevices[s_i].capability[index].audio.max_bit = bits;
                    pdevices[s_i].capability[index].audio.max_rate = max_samples;
                    strcpy(pdevices[s_i].capability[index].audio.sample_format,fmt);
                    pdevices[s_i].capability_count++;
                }
            }
        }
    }
#else
	static void log_callback(void * acl, int level, const char *format, va_list arg)
	{
		AVDevice * pdevices = s_pdevices;
		
		if (pdevices && level == AV_LOG_INFO && s_i < s_nmax){
			if (strstr(format, "DirectShow video devices") == format ||
				strstr(format, "Android camera devices") == format ){
				s_type = AV_DEVICE_VIDEO;
			}
			else if (strstr(format, "DirectShow audio devices") == format ||
					 strstr(format, "Android audio devices") == format ){
				s_type = AV_DEVICE_AUDIO;
			}
			else if (strstr(format, " \"%s\"\n") == format){
				strcpy(pdevices[s_i].name, va_arg(arg, char*));
				pdevices[s_i].type = s_type;
			}
			else if (strstr(format, "    Alternative name \"%s\"\n") == format){
				strcpy(pdevices[s_i].alternative_name, va_arg(arg, char*));
				s_i++;
			}
			else if (strstr(format, "  min s=") == format){
				int index = pdevices[s_i].capability_count;
				if (index < MAX_CAPABILITY_COUNT && index >= 0){
					pdevices[s_i].capability[index].video.min_w = va_arg(arg, int);
					pdevices[s_i].capability[index].video.min_h = va_arg(arg, int);
					pdevices[s_i].capability[index].video.min_fps = va_arg(arg, double);
					pdevices[s_i].capability[index].video.max_w = va_arg(arg, int);
					pdevices[s_i].capability[index].video.max_h = va_arg(arg, int);
					pdevices[s_i].capability[index].video.max_fps = va_arg(arg, double);
					pdevices[s_i].capability_count++;
				}
			}
			else if (strstr(format, "  min ch=") == format){
				int index = pdevices[s_i].capability_count;
				if (index < MAX_CAPABILITY_COUNT && index >= 0){
					pdevices[s_i].capability[index].audio.min_ch = va_arg(arg, int);
					pdevices[s_i].capability[index].audio.min_bit = va_arg(arg, int);
					pdevices[s_i].capability[index].audio.min_rate = va_arg(arg, int);
					pdevices[s_i].capability[index].audio.max_ch = va_arg(arg, int);
					pdevices[s_i].capability[index].audio.max_bit = va_arg(arg, int);
					pdevices[s_i].capability[index].audio.max_rate = va_arg(arg, int);
					pdevices[s_i].capability_count++;
				}
			}
			else if (strstr(format, "  pixel_format=") == format){
				int index = pdevices[s_i].capability_count;
				if (index < MAX_CAPABILITY_COUNT && index >= 0){
					char * pf = va_arg(arg, char*);
					if (strlen(pf) < MAX_FORMAT_LENGTH)
						strcpy(pdevices[s_i].capability[index].video.pix_format, pf);
					else
						strcpy(pdevices[s_i].capability[index].video.pix_format, "overflow");
				}
			}
			else if (strstr(format, "  vcodec=") == format){
				int index = pdevices[s_i].capability_count;
				if (index < MAX_CAPABILITY_COUNT && index >= 0){
					char * pf = va_arg(arg, char*);
					if (strlen(pf) < MAX_FORMAT_LENGTH)
						strcpy(pdevices[s_i].capability[index].video.codec_name, pf);
					else
						strcpy(pdevices[s_i].capability[index].video.codec_name, "overflow");
				}
			}
		}
	}
#endif
    
	int ffCapDevicesList(AVDevice *pdevices, int nmax)
	{
		int i, count, ret;
		AVInputFormat *file_iformat = NULL;
		AVDictionary *opt = NULL;
		const char * filename = "dummy";
		AVFormatContext * ctx = NULL;
		
		ffInit();
 
		while (true)
		{

			memset(pdevices, 0, nmax*sizeof(AVDevice));

			ctx = avformat_alloc_context();
			if (!ctx)
			{
				av_log(NULL, AV_LOG_FATAL, "ffCreateDecodeContext : could not allocate context.\n");
				break;
			}
			file_iformat = av_find_input_format(CAP_DEVICE_NAME);
			if (!file_iformat){
				av_log(NULL, AV_LOG_FATAL, "Unknown input format: %s \n",CAP_DEVICE_NAME);
				break;
			}

			av_dict_set(&opt, "list_devices", "true", 0);

			i = 0;
			s_i = 0;
			s_type = AV_DEVICE_NONE;
			s_nmax = nmax;
			s_pdevices = pdevices;
			av_log_set_callback( log_callback );
			
			ret = avformat_open_input(&ctx, filename, file_iformat, &opt);

			av_dict_set(&opt, "list_devices", "false", 0);
            
            count = s_i;
#ifndef __APPLE__
			av_dict_set(&opt, "list_options", "true", 0);
			for (i = 0; i < count; i++){
                char filename[512];

				if (pdevices[i].type == AV_DEVICE_VIDEO)
					snprintf(filename, 512, "video=%s", pdevices[i].alternative_name);
				else if (pdevices[i].type == AV_DEVICE_AUDIO)
					snprintf(filename, 512, "audio=%s", pdevices[i].alternative_name);
				else{
					printf("Unknow device type\n");
					continue;
				}
				s_i = i;
				ret = avformat_open_input(&ctx, filename, file_iformat, &opt);
			}
#endif
			av_log_set_callback(av_log_default_callback);
			s_pdevices = NULL;
			s_nmax = 0;
			s_type = AV_DEVICE_NONE;
			av_dict_free(&opt);
			avformat_close_input(&ctx);

			return count;
		}

		if (ctx)
			avformat_close_input(&ctx);
		return -1;
	}
#ifdef __ANDROID__
	static int _oesTex = -1;
	void ffSetOESTexture(int txt)
	{
		_oesTex = txt;
	}
#else
	void ffSetOESTexture(int txt)
	{
	}
#endif
	/*
	//在android操作系统下需要先创建一个OES材质
	//你需要要在OpenGL线程调用下面的函数用来创建或者删除OES材质
	//然后在开始调用视频库前调用ffSetOESTexture设置OES材质
	//当然也可以使用AndroidDemuxer.java中的函数requestGLThreadProcess
	int createOESTexture(){
		int textures[1];
		glGenTextures(1,textures);
		glBindTexture(GL_TEXTURE_EXTERNAL_OES, textures[0]);
		glTexParameterf(GL_TEXTURE_EXTERNAL_OES,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
		glTexParameterf(GL_TEXTURE_EXTERNAL_OES,GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_EXTERNAL_OES,GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_EXTERNAL_OES,GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

		return glGetError() == GL_NO_ERROR ? textures[0]: -1;
	}
	void ffReleaseAndroidOESTexture(int txt){
		if (txt>=0){
			int textures[1];
			textures[0] = txt;
			glDeleteTextures(1,textures);
		}
	}
	*/
	AVDecodeCtx *ffCreateCapDeviceDecodeContext(
		const char *video_device, int w, int h, int fps,AVPixelFormat fmt,
		const char *audio_device, int chancel, int bit, int rate, AVDictionary * opt)
	{
		char buf[32];
		char filename[2 * MAX_DEVICE_NAME_LENGTH];

		ffInit();
        
		if (video_device){

			strcpy(filename, "video=");
			strcat(filename, video_device);

			if (audio_device){
				strcat(filename, ":audio=");
				strcat(filename, audio_device);
			}
		}
		else if (audio_device){
			strcat(filename, "audio=");
			strcat(filename, audio_device);
		}
		else return NULL;

		if (video_device){
			snprintf(buf, 32, "%dx%d", w, h);
			av_dict_set(&opt, "video_size", buf, 0);
			snprintf(buf, 32, "%d", fps);
			av_dict_set(&opt, "framerate", buf, 0);

#ifdef __ANDROID__
			snprintf(buf, 32, "%d", _oesTex);
			av_dict_set(&opt, "oes_texture", buf, -1);
			//open debug info
			#ifdef _DEBUG
				av_dict_set(&opt, "debug", "1", 0);
			#endif
#endif
            
#ifdef __APPLE__
            av_dict_set(&opt,"video_device_index",video_device,-1);
#endif            
		}
		if (audio_device){
			snprintf(buf, 32, "%d", chancel);
			av_dict_set(&opt, "channels", buf, 0);
			snprintf(buf, 32, "%d", bit);
			av_dict_set(&opt, "sample_size", buf, 0);
			snprintf(buf, 32, "%d", rate);
			av_dict_set(&opt, "sample_rate", buf, 0);
#ifdef __APPLE__
            av_dict_set(&opt,"audio_device_index",audio_device,-1);
#endif            
		}
		snprintf(buf, 32, "%d", fmt);
		av_dict_set(&opt, "pixel_format", buf, 0);

		return ffCreateDecodeContext(filename, opt);
	}

	int ffAutoFocus(int b)
	{
#ifdef __ANDROID__
		return android_autoFoucs(b);
#else
		return 0;
#endif
	}

	int ffReadFrameFormat(AVDecodeCtx *pdc,
		int w, int h, AVPixelFormat fmt,
		int ch, int sample_rate,AVSampleFormat sample_fmt)
	{
		if (pdc && pdc->_video_st && pdc->_video_st->codec){
			AVCodecContext *c = pdc->_video_st->codec;
			if (c->width != w || c->height != h || fmt != c->pix_fmt){
				AVPixelFormat infmt;

				if (fmt == AV_PIX_FMT_YVU420P){
					infmt = AV_PIX_FMT_YUV420P;
					pdc->_vctx.isyv12 = 1;
				}
				else{
					infmt = fmt;
					pdc->_vctx.isyv12 = 0;
				}
				if (pdc->_vctx.sws_ctx)
					sws_freeContext(pdc->_vctx.sws_ctx);
				pdc->_vctx.sws_ctx = av_sws_alloc(c->width, c->height, c->pix_fmt,
					w, h, infmt);
				if (!pdc->_vctx.sws_ctx){
					av_log(NULL, AV_LOG_FATAL, "@ffReadFrameFormat : Could not initialize the conversion context,in_w=%d,in_h=%d,in_fmt=%d\n", w, h, infmt);
					return -1;
				}
				pdc->_vctx.sws_in_w = c->width;
				pdc->_vctx.sws_in_h = c->height;
				pdc->_vctx.sws_in_fmt = c->pix_fmt;
				pdc->_vctx.sws_out_w = w;
				pdc->_vctx.sws_out_h = h;
				pdc->_vctx.sws_out_fmt = infmt;
				DEBUG("ReadFrameFormat video scale:(%dx%d %s)->(%dx%d %s)\n", 
					c->width, c->height, av_get_pix_fmt_name(c->pix_fmt),
					w, h, av_get_pix_fmt_name(infmt));
			}
			else{
				if (pdc->_vctx.sws_ctx)
					sws_freeContext(pdc->_vctx.sws_ctx);
				pdc->_vctx.sws_ctx = NULL;
			}
		}
		
		if (pdc && pdc->_audio_st && pdc->_audio_st->codec ){
			AVCodecContext *c = pdc->_audio_st->codec;

			if (c->channels !=ch || c->sample_rate !=sample_rate || c->sample_fmt != sample_fmt){
				if (pdc->_actx.swr_ctx)
					swr_free(&pdc->_actx.swr_ctx);
				/* create resampler context */
				pdc->_actx.swr_ctx = av_swr_alloc(c->channels, c->sample_rate, c->sample_fmt,
					ch, sample_rate, sample_fmt);
				if (!pdc->_actx.swr_ctx){
					av_log(NULL, AV_LOG_FATAL, "@ffReadFrameFormat Failed to initialize the resampling context\n");
					return -1;
				}
				pdc->_actx.swr_in_channel = c->channels;
				pdc->_actx.swr_in_sample_rate = c->sample_rate;
				pdc->_actx.swr_in_sample_fmt = c->sample_fmt;
				pdc->_actx.swr_out_channel = ch;
				pdc->_actx.swr_out_sample_rate = sample_rate;
				pdc->_actx.swr_out_sample_fmt = sample_fmt;

				DEBUG("ReadFrameFormat audio convert:(%d %d %s)->(%d %d %s)\n",
					c->channels, c->sample_rate, av_get_sample_fmt_name(c->sample_fmt),
					ch, sample_rate, av_get_sample_fmt_name(sample_fmt));
			}
			else{
				if (pdc->_actx.swr_ctx)
					swr_free(&pdc->_actx.swr_ctx);
				pdc->_actx.swr_ctx = NULL;
			}
		}
		return 0;
	}
}
