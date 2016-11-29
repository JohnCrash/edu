#ifndef __FFDEC__H__
#define __FFDEC__H__
#include <deque>
#include "ffcommon.h"
#include "ffraw.h"

namespace ff
{
#define TRANSCODE_MAXBUFFER_SIZE 64*1024

	struct AVDecodeCtx
	{
		const char * _fileName;
		//int _width;
		//int _height;
		AVFormatContext * _ctx;
		AVStream *_video_st;
		AVStream * _audio_st;

		int _video_st_index;
		int _audio_st_index;

		AVCtx _vctx;
		AVCtx _actx;

		int has_audio, has_video, encode_video, encode_audio, isopen;

		std::deque<AVRaw *> * perview_frames;
		mutex_t * preview_mutex;
		condition_t * preview_cond;
		std::thread * preview_thread;
		int preview_stop;

		unsigned int preview_textures[3];
	};

	/**
	 * 创建一个解码器上下文，对视频文件进行解码操作
	 */
	AVDecodeCtx *ffCreateDecodeContext(
		const char * filename, AVDictionary *opt_arg
		);

	void ffCloseDecodeContext(AVDecodeCtx *pdc);

	/**
	 * 创建一个设备解码器，通过设备名称
	 */
	AVDecodeCtx *ffCreateCapDeviceDecodeContext(
		const char *video_device, int w, int h, int fps, AVPixelFormat fmt,
		const char *audio_device, int chancel, int bit, int rate,
		AVDictionary * opt);

	void ffSetOESTexture(int txt);
	int ffAutoFocus(int b);
	/**
	 * 取得视频的帧率，宽度，高度
	 */
	AVRational ffGetFrameRate(AVDecodeCtx *pdc);
	int ffGetFrameWidth(AVDecodeCtx *pdc);
	int ffGetFrameHeight(AVDecodeCtx *pdc);

	/**
	 * 从视频文件中取得一帧，可以是图像帧，也可以是一个音频包
	 */
	AVRaw * ffReadFrame(AVDecodeCtx *pdc);

	/**
	 * 开始或者停止解码帧预视，调用返回一个gl texture id
	 */
	int ffStartPreview(AVDecodeCtx *pdc);
	void ffStopPreview(AVDecodeCtx *pdc);

	/**
	 * 设置俘获输出图像大小和格式
	 */
	int ffReadFrameFormat(AVDecodeCtx *pdc, 
		int w, int h, AVPixelFormat fmt,
		int ch, int sample_rate, AVSampleFormat sample_fmt);
}
#endif