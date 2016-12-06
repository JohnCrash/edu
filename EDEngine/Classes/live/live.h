#ifndef _PUBLISHER_H_
#define _PUBLISHER_H_

namespace ff
{
	enum cbType{
		LIVE_BEGIN, //��ʼֱ������¼��
		LIVE_END,   //ֱֹͣ������¼��
		LIVE_ERROR, //����
		LIVE_FRAME, //֡��Ϣ
		LIVE_INFO, 
		LIVE_OPEN, //����Ƶ�豸
		LIVE_CLOSE, //�ر���Ƶ�豸
	};
#define MAX_ERRORMSG_COUNT 8
#define MAX_ERRORMSG_LENGTH 256

	struct liveState
	{
		cbType state; 
		int64_t nframes; //���͵�֡��
		int64_t ntimes; //ֱ����ʱ�䵥λns
		int encodeBufferSize; //ѹ����������λkb
		int writeBufferSize; //���ͻ�������λkb
		int nerror; //��������
		int quit;
		char errorMsg[MAX_ERRORMSG_COUNT][MAX_ERRORMSG_LENGTH]; //������Ϣ
	};

	typedef int(*liveCB)(liveState * pls);

	/**
	 * ѡ����Ƶ����Ƶ�����豸����ֱ��
	 */
	void liveOnRtmp(
		const char * rtmp_publisher,
		const char * camera_name, int w, int h, int fps, const char * pix_fmt_name,int vbitRate,
		const char * phone_name, int rate, const char * sample_fmt_name, int abitRate,
		int ow, int oh, int ofps,
		liveCB cb);

	/**
	 * ����Ƶ��Ƶ�����豸,�ɹ�����1ʧ�ܷ���0
	 */
	int liveOpenCapDevices(
		const char * camera_name, int w, int h, int fps, const char * pix_fmt_name, 
		const char * phone_name, int rate, const char * sample_fmt_name);
	/**
	 * ��ʼֱֹͣ��
	 */
	int liveStart(const char * filename, int w, int h, int fps, int vbitRate, int abitRate);
	int liveStop();
	/**
	* �ر���Ƶ��Ƶ�����豸
	*/
	int liveCloseCapDevices();
	void setLiveCB(liveCB cb);

#define MAX_DEVICE_NAME_LENGTH 256
#define MAX_FORMAT_LENGTH 32
#define MAX_CAPABILITY_COUNT 128

	enum AVDeviceType{
		AV_DEVICE_NONE = 0,
		AV_DEVICE_VIDEO = 1,
		AV_DEVICE_AUDIO = 2,
	};
	enum AVDeviceFace{
		AV_FACE_UNKNOW = 0,
		AV_FACE_FRONT = 1,
		AV_FACE_BACK = 2,
	};
	union AVDeviceCap{
		struct {
			int min_w, min_h;
			int max_w, max_h;
			double min_fps, max_fps;
			char pix_format[MAX_FORMAT_LENGTH];
			char codec_name[MAX_FORMAT_LENGTH];
		} video;
		struct {
			int min_ch, min_bit, min_rate;
			int max_ch, max_bit, max_rate;
			char sample_format[MAX_FORMAT_LENGTH];
			char codec_name[MAX_FORMAT_LENGTH];
		} audio;
	};

	struct AVDevice{
		char name[MAX_DEVICE_NAME_LENGTH];
		char alternative_name[MAX_DEVICE_NAME_LENGTH];
		AVDeviceType type;
		AVDeviceFace face;
		int orientation;
		AVDeviceCap capability[MAX_CAPABILITY_COUNT];
		int capability_count;
	};

	/**
	* �г������豸
	* �ɹ������豸������ʧ�ܷ���-1
	*/
	int ffCapDevicesList(AVDevice *pdevices, int nmax);
}
#endif
