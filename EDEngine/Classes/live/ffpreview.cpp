#include "ffcommon.h"
#include "ffdec.h"
#include "ffpreview.h"

namespace ff{
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

	static mutex_t *_preview_mutex = NULL;
	static AVRaw * _preview_frame = NULL;
	static GLuint _preview_textures[3];
	static AVRaw * _prev_frame = NULL;

	void addPreviewFrame(AVRaw * praw)
	{
		if (_preview_mutex){
			mutex_lock_t lk(*_preview_mutex);
			if (_preview_frame){
				if (_preview_frame != praw){
					free_raw(_preview_frame);
					_preview_frame = raw_ref(praw);
				}
			}else
				_preview_frame = raw_ref(praw);
		}
	}
	int ffStartPreview()
	{
		if (_preview_mutex)return 1;

		glGenTextures(3, _preview_textures);

		if (check_gl_state()){
			for (int i = 0; i < 3; i++){
				glBindTexture(GL_TEXTURE_2D, _preview_textures[i]);
				glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
				glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
				glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
				glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
			}
			if (check_gl_state()){
				_preview_mutex = new mutex_t();
				_preview_frame = NULL;
				_prev_frame = NULL;
				return 1;
			}
		}
		return 0;
	}
	/**
	* È¡Ô¤ÊÓÍ¼
	*/
	int ffGetPreviewFrame(GLuint yuv[3], int *pw, int *ph)
	{
		if (_preview_mutex && _preview_frame){
			mutex_lock_t lk(*_preview_mutex);
			AVRaw * raw = _preview_frame;

			yuv[0] = _preview_textures[0];
			yuv[1] = _preview_textures[1];
			yuv[2] = _preview_textures[2];
			if (raw == _prev_frame){
				*pw = raw->width;
				*ph = raw->height;
				return 1;
			}
			//update textures
			if (raw->format == AV_PIX_FMT_YUV420P || raw->format == AV_PIX_FMT_YVU420P){
				glBindTexture(GL_TEXTURE_2D, _preview_textures[0]);
				if (!check_gl_state())return 0;

				glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, raw->linesize[0], raw->height, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, raw->data[0]);

				if (raw->format == AV_PIX_FMT_YUV420P)
					glBindTexture(GL_TEXTURE_2D, _preview_textures[1]);
				else
					glBindTexture(GL_TEXTURE_2D, _preview_textures[2]);
				glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, raw->linesize[1], raw->height, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, raw->data[1]);

				if (raw->format == AV_PIX_FMT_YUV420P)
					glBindTexture(GL_TEXTURE_2D, _preview_textures[2]);
				else
					glBindTexture(GL_TEXTURE_2D, _preview_textures[1]);
				glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, raw->linesize[2], raw->height, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, raw->data[2]);
				
				if (!check_gl_state())return 0;

				_prev_frame = raw;
				*pw = raw->width;
				*ph = raw->height;
			}
			else{
				DEBUG("Preview only support yuv420p or yv12 format.");
				return 0;
			}
			free_raw(raw);
			_preview_frame = NULL;
			return 1;
		}return 0;
	}

	void ffStopPreview()
	{
		if (_preview_mutex){
			if (_preview_frame)
				free_raw(_preview_frame);
			delete _preview_mutex;
			glDeleteTextures(3, _preview_textures);
		}
		_preview_mutex = NULL;
		_preview_frame = NULL;
		_prev_frame = NULL;
	}
}