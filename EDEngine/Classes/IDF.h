#ifndef __IDF_H__
#define __IDF_H__

#include "cocos2d.h"
#include "misc.h"

USING_NS_CC;

//JPG�ļ��ṹ˵��:
//
//	<Start Segment>	ff, d8
//
//	<Segment 1>
//	<Segment 2>
//	...
//	<Segment n>
//
//	ͼ��ѹ������
//
//	<End Segment>	ff, d9
//
//	����ÿ��segment:
//	0xff,<Segment ID>[,<Segment length>]
//		Segment ID:
//		SOI		D8		�ļ�ͷ
//		EOI		D9		�ļ�β
//		SOF0	C0		֡��ʼ����׼ JPEG��
//		SOF1	C1		ͬ��
//		DHT		C4		���� Huffman ����������
//		SOS		DA		ɨ���п�ʼ
//		DQT		DB		����������
//		DRI		DD		�������¿�ʼ���
//		APP0	E0		���彻����ʽ��ͼ��ʶ����Ϣ
//		COM		FE		ע��
//		����ʼ�ͽ����ζ��жγ���, motorola�ֽ�˳��, ���Ȱ��������ֶα���, ��������0xff�Ͷα�ʶ
//
//	IDF��Ϣ�θ�ʽ:
//		char		1		0xff
//		char		1		0xe1
//		uint16_t	2		wSegmentLength�����������ֶα���
//		char[6]		6		IDF,0,0
//		char[2]		2		II,Ϊtiff header��ʼ
//		uint16_t	2		0x2a,00
//		<IDF0>
//		<IDF1>
//		...
//
//	IDF��ʽ:
//		uint32_t			4		nOffset,��tiff headerΪ��ʼ��
//		uint16_t			2		cnRecord
//		<Record0>
//		<Record1>
//		...
//
//	Record��ʽ:
//		uint16_t			2		wID
//		uint16_t			2		wDataType
//							1		byte
//							2		string
//							3		ushort
//							4		ulong
//							5		urational		8
//							6		sbyte
//							7		undefined
//							8		sshort
//							9		slong
//							10		srational
//							11		single
//							12		double
//		uint32_t			4		nLength
//		uint32_t			4		nOffset,Ҳ����tiff headerΪ��ʼ���
//
//		#define M_SOF0  0xC0            // Start Of Frame N
//		#define M_SOF1  0xC1            // N indicates which compression process
//		#define M_SOF2  0xC2            // Only SOF0-SOF2 are now in common use
//		#define M_SOF3  0xC3
//		#define M_SOF5  0xC5            // NB: codes C4 and CC are NOT SOF markers
//		#define M_SOF6  0xC6
//		#define M_SOF7  0xC7
//		#define M_SOF9  0xC9
//		#define M_SOF10 0xCA
//		#define M_SOF11 0xCB
//		#define M_SOF13 0xCD
//		#define M_SOF14 0xCE
//		#define M_SOF15 0xCF
//		#define M_SOI   0xD8            // Start Of Image (beginning of datastream)
//		#define M_EOI   0xD9            // End Of Image (end of datastream)
//		#define M_SOS   0xDA            // Start Of Scan (begins compressed data)
//		#define M_JFIF  0xE0            // Jfif marker
//		#define M_EXIF  0xE1            // IDF marker
//		#define M_COM   0xFE            // COMment 
//
//		���� APP ��ʶ(SECTION)
//		#define M_APP0  0xE0
//		#define M_APP1  0xE1
//		#define M_APP2  0xE2
//		#define M_APP3  0xE3
//		#define M_APP4  0xE4
//		#define M_APP5  0xE5
//		#define M_APP6  0xE6
//		...
//
//		#define TAG_MAKE              0x010F    //���DC ������
//		#define TAG_MODEL             0x0110    //DC �ͺ�
//		#define TAG_ORIENTATION       0x0112    //����ʱ����������������תDC 90��������Ƭ
//		#define TAG_XRESOLUTION       0x011A    //X ��ֱ���
//		#define TAG_YRESOLUTION       0x011B    //Y ��ֱ���
//		#define TAG_RESOLUTIONUNIT    0x0128    //�ֱ��ʵ�λ������ inch, cm 
//		#define TAG_DATATIME          0x0132    //����ʱ��
//		#define TAG_YBCR_POSITION     0x0213    //YCbCr λ�ÿ��ƣ����� ����
//		#define TAG_COPYRIGHT         0x8298    //��Ȩ
//		#define TAG_EXIF_OFFSET       0x8769    //EXIF ƫ�ƣ���ʱ���൱�ڴ���һ���µ� EXIF ��Ϣ
//		#define TAG_IMAGEWIDTH        0x0001    //ͼ����
//		#define TAG_IMAGEHEIGHT       0x0101    //ͼ��߶�
//		#define TAG_EXPOSURETIME      0x829A    //�ع�ʱ�䣬���� 1/30 ��
//		#define TAG_FNUMBER           0x829D    //��Ȧ������ F2.8
//		#define TAG_EXIF_VERSION      0x9000    //EXIF ��Ϣ�汾
//		#define TAG_DATETIME_ORIGINAL 0x9003    //��Ƭ����ʱ�䣬���� 2005-10-13 11:09:35
//		#define TAG_DATATIME_DIGITIZED  0x9004  //��Ƭ������ͼ���޸�����޸ĺ��ʱ�䣬����  2005-10-13 11:36:35
//		#define TAG_COMPONCONFIG      0x9101    //ComponentsConfiguration ɫ�ʿռ�����
//		#define TAG_COMPRESS_BIT      0x9202    //ÿ����ѹ��λ��
//		#define TAG_SHUTTERSPEED      0x9201    //�����ٶȣ����� 1/30 ��
//		#define TAG_APERTURE          0x9202    //��Ȧֵ������ F2.8
//		#define TAG_BRIGHTNESS        0x9203    //����
//		#define TAG_EXPOSURE_BIAS     0x9204    //�عⲹ�������� EV0.0
//		#define TAG_MAXAPERTURE       0x9205    //����Ȧֵ������ F2.8
//		#define TAG_SUBJECT_DISTANCE  0x9206    //��������룬���� 3.11 ��
//		#define TAG_METERING_MODE     0x9207    //���ģʽ���������
//		#define TAG_WHITEBALANCE      0x9208    //LightSource ��ƽ��
//		#define TAG_FLASH             0x9209    //�Ƿ�ʹ�������
//		#define TAG_FOCALLENGTH       0x920A    //���࣬���� 7.09mm
//		#define TAG_USERCOMMENT       0x9286    //�û�ע��
//		#define TAG_MAKE_COMMENT      0x927C    //����ע�͡�����汾���ṩ(2005-10-13)
//		#define TAG_SUBSECTIME        0x9290    //SubSecTime
//		#define TAG_SUBTIME_ORIGINAL  0x9291    //SubSecTimeOriginal
//		#define TAG_SUBTIME_DIGITIZED 0x9292    //SubSecTimeDigitized
//		#define TAG_FLASHPIXVERSION   0x00A0    //Flash Pix �汾
//		#define TAG_COLORSPACE        0x01A0    //ɫ�ʿռ䣬���� sRGB
//		#define TAG_PIXEL_XDIMENSION  0x02A0    //
//		#define TAG_PIXEL_YDIMENSION  0x03A0    //
//		#define TAG_INTEROP_OFFSET    0xa005    //ƫ��
//		#define TAG_FOCALPLANEXRES    0xA20E    //��ƽ��X��ֱ��ʣ����� 1024000/278
//		#define TAG_FOCALPLANEYRES    0xA20F    //��ƽ��X��ֱ��ʣ����� 768000/209
//		#define TAG_FOCALPLANEUNITS   0xA210    //��ƽ��ֱ��ʵ�λ
//		#define TAG_EXIF_IMAGEWIDTH   0xA002    //EXIF ͼ����(�������� JPG ͼ��)
//		#define TAG_EXIF_IMAGELENGTH  0xA003    //EXIF ͼ��߶�
//		#define TAG_EXPOSURE_PROGRAM  0x8822    //
//		#define TAG_ISO_EQUIVALENT    0x8827    //
//		#define TAG_COMPRESSION_LEVEL 0x9102    //
//		#define TAG_THUMBNAIL_OFFSET  0x0201    //����ͼƫ��
//		#define TAG_THUMBNAIL_LENGTH  0x0202    //����ͼ��С
//		#define TAG_GPS_VERSIONID       0x0000  //GPS �汾
//		#define TAG_GPS_LATITUDEREF     0x0001  //γ�Ȳο���������γ
//		#define TAG_GPS_LATITUDE        0x0002  //γ��ֵ
//		#define TAG_GPS_LONGITUDEREF    0x0003  //���Ȳο������綫��
//		#define TAG_GPS_LONGITUDE       0x0004  //����ֵ
//		#define TAG_GPS_ALTITUDEREF     0x0005  //���θ߶Ȳο�
//		#define TAG_GPS_ALTITUDE        0x0006  //����
//		#define TAG_GPS_TIMESTAMP       0x0007  //ʱ���
//		#define TAG_GPS_SATELLITES      0x0008  //����
//		#define TAG_GPS_STATUS          0x0009  //״̬
//		#define TAG_GPS_MEASUREMODE     0x000A  //
//		#define TAG_GPS_DOP             0x000B  //
//		#define TAG_GPS_SPEEDREF        0x000C  //
//		#define TAG_GPS_SPEED           0x000D  //
//		#define TAG_GPS_TRACKREF        0x000E  //
//		#define TAG_GPS_TRACK           0x000F  //
//		#define TAG_GPS_IMGDIRECTIONREF 0x0010  //
//		#define TAG_GPS_IMGDIRECTION    0x0011  //
//		#define TAG_GPS_MAPDATUM        0x0012  //
//		#define TAG_GPS_DESTLATITUDEREF 0x0013  //
//		#define TAG_GPS_DESTLATITUDE    0x0014  //
//		#define TAG_GPS_DESTLONGITUDEREF  0x0015//
//		#define TAG_GPS_DESTLONGITUDE   0x0016  //
//		#define TAG_GPS_DESTBEARINGREF  0x0017  //
//		#define TAG_GPS_DESTBEARING     0x0018  //
//		#define TAG_GPS_DESTDISTANCEREF 0x0019  //
//		#define TAG_GPS_DESTDISTANCE    0x001A  //

#define	IDF_NO_EXIF			0x8769
#define	IDF_NO_GPS			0x8825

typedef struct
{
	uint16_t wID;
	uint16_t wDataType;
	int cnVar;							//������Ŀ
	int nOffset;						//��������λ��ƫ�ƣ��������ݳ����Ƿ����4�ֽ�
}IDFINFO,*PIDFINFO;

//ԭ����nOffset�ĸ��ֽڿ������ɾͲ��ٵ���
#define FMT_BYTE		1				//nLenΪ�ֽ�����<=4ƫ��ֱ�Ӿ�������
#define FMT_STRING		2				//nLenΪ���ȣ�<=4ƫ��ֱ�Ӿ�������
#define FMT_USHORT		3				//nLenΪushort����<=2ƫ��ֱ�Ӿ�������
#define FMT_ULONG		4				//nLenΪulong����<=1ƫ��ֱ�Ӿ�������
#define FMT_URATIONAL	5				//�̶�8�ֽ�һ��������ulong,���Ϊa/b
#define FMT_SBYTE		6				//nLenΪ�ֽ�����<=4ƫ��ֱ�Ӿ�������
#define FMT_UNDEFINED	7				//δ���壬��BYTE����
#define FMT_SSHORT		8				//nLenΪsshort����<=2ƫ��ֱ�Ӿ�������
#define FMT_SLONG		9				//nLenΪulong����<=1ƫ��ֱ�Ӿ�������
#define FMT_SRATIONAL	10				//�̶�8�ֽڣ�����slong,���Ϊa/b
#define FMT_SINGLE		11				//4�ֽڸ�����
#define FMT_DOUBLE		12				//8�ֽڸ�����

class CIDFList  
{
public:
	CIDFList();
	virtual ~CIDFList();

public:
	void Free();
	static int GetIDFDataLen(PIDFINFO pii);

	int GetCount(){return m_listIDF.size();}
	PIDFINFO FindIDF(uint16_t wID,char **ppData=NULL);
	bool DeleteIDF(uint16_t wID);
	bool AddIDF(PIDFINFO pei,const char *pData);
	bool AddIDF(uint16_t wID,uint16_t wDataType,int cnVar,const char *pData);
	bool AddIDF(uint16_t wID,const char *pszStr);
	int GetIDFTableLen();
	void PutIDFTable(char *pTiffHeader,char *pIDF);

private:
	std::vector<IDFINFO> m_listIDF;

	char *m_pBuf;
	int m_lenBuf;
	int m_lenBufAlloc;
};

class CIDF  
{
public:
	CIDF();
	virtual ~CIDF();

public:
	bool LoadIDF(char *pBuf,int lenBuf);
	PIDFINFO FindIDF(uint16_t wMainID,uint16_t wID,char **ppData=NULL);
	bool AddIDF(uint16_t wMainID,uint16_t wID,uint16_t wDataType,int cnVar,const char *pData);
	bool SaveFile();
	CIDFList *GetIDFList(uint16_t wMainID);
	bool AddGPSInfo(double dLatitude,double dLongitude,double nAltitude);

	uint16_t GetWord(uint16_t *pw);
	void PutWord(uint16_t *pw,uint16_t w);
	uint32_t GetDword(uint32_t *pdw);
	void PutDword(uint32_t *pdw,uint32_t dw);

private:
	CIDFList m_listIDF;
	CIDFList m_listIDFExif;
	CIDFList m_listIDFGPS;

private:
	void Free();
	bool LoadIDFTable(uint16_t wMainID,int nOffset);

	uint16_t XchgByteOrder(uint16_t w);
	uint32_t XchgByteOrder(uint32_t dw);

	void DoubleToDMS(double d,int &nDegree,int &nMinute,int &nSecond100);

private:
	char *m_pIDFHeader;
	int m_lenIDF;
	char *m_pTiffHeader;

	bool m_bXchg;
	bool m_bModified;
};

#endif // __IDF_H__
