#include "ffdec.h"
#include "sharegl.h"

namespace ff{
	AVRaw * popARaw(AVDecodeCtx *pdc)
	{
		mutex_lock_t lock(*pdc->preview_mutex);

		while (!pdc->preview_stop && pdc->perview_frames->empty()){
			pdc->preview_cond->wait(lock);
		}

		if (pdc->perview_frames->empty())
			return NULL;

		AVRaw * raw = pdc->perview_frames->back();
		pdc->perview_frames->pop_back();
		return raw;
	}
	static int check_gl_state()
	{
		GLenum r = glGetError();
		if (r == GL_NO_ERROR)return 1;
		char * errmsg = "Unknow opengl error value";
		switch (r){
		case GL_INVALID_ENUM:
			errmsg = "An unacceptable value is specified for an enumerated argument.";
			break;
		case GL_INVALID_VALUE:
			errmsg = "A numeric argument is out of range. ";
			break;
		case GL_INVALID_OPERATION:
			errmsg = "The specified operation is not allowed in the current state.";
			break;
		case GL_STACK_OVERFLOW:
			errmsg = "This function would cause a stack overflow. ";
			break;
		case GL_STACK_UNDERFLOW:
			errmsg = "This function would cause a stack underflow. ";
			break;
		case GL_OUT_OF_MEMORY:
			errmsg = "The specified operation is not allowed in the current state. ";
			break;
		}
		cocos2d::log("opengl: %s", errmsg);
		return 0;
	}
	static int update_thread_proc(AVDecodeCtx * pdc)
	{
		AVRaw * raw;

		ffShareMakeCurrent();
		glGenTextures(3, pdc->preview_textures);
		check_gl_state();
		for (int i = 0; i < 3; i++){
			glBindTexture(GL_TEXTURE_2D, pdc->preview_textures[i]);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		}
		check_gl_state();
		while (raw = popARaw(pdc)){
			//update texture
			if (raw->format == AV_PIX_FMT_YUV420P || raw->format == AV_PIX_FMT_YVU420P){
				glBindTexture(GL_TEXTURE_2D, pdc->preview_textures[0]);
				glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, raw->linesize[0], raw->height, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, raw->data[0]);

				if (raw->format == AV_PIX_FMT_YUV420P)
					glBindTexture(GL_TEXTURE_2D, pdc->preview_textures[1]);
				else
					glBindTexture(GL_TEXTURE_2D, pdc->preview_textures[2]);
				glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, raw->linesize[1], raw->height, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, raw->data[1]);

				if (raw->format == AV_PIX_FMT_YUV420P)
					glBindTexture(GL_TEXTURE_2D, pdc->preview_textures[2]);
				else
					glBindTexture(GL_TEXTURE_2D, pdc->preview_textures[1]);
				glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, raw->linesize[2], raw->height, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, raw->data[2]);
				check_gl_state();
			}
			else{
				DEBUG("Preview only support yuv420p or yv12 format.");
			}
			free_raw(raw);
		}
		
		glDeleteTextures(3, pdc->preview_textures);

		ffShareMakeCurrentClear();
		return 0;
	}

	int ffStartPreview(AVDecodeCtx *pdc)
	{
		if (pdc->preview_thread)return 0;

		if (!ffInitShare())
			return -1;

		pdc->preview_cond = new condition_t();
		pdc->preview_mutex = new mutex_t();
		pdc->perview_frames = new std::deque<AVRaw *>();
		pdc->preview_thread = new std::thread(update_thread_proc,pdc);

		return 0;
	}

	void ffStopPreview(AVDecodeCtx *pdc)
	{
		if (pdc->preview_thread){
			pdc->preview_stop = 1;
			pdc->preview_cond->notify_one();
			pdc->preview_thread->join();
			delete pdc->preview_thread;
			delete pdc->preview_cond;
			delete pdc->preview_mutex;
			delete pdc->perview_frames;

			ffReleaseShare();
		}
		pdc->preview_thread = NULL;
	}
}