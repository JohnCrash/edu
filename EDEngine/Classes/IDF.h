#ifndef __IDF_H__
#define __IDF_H__

#include "cocos2d.h"
#include "misc.h"

USING_NS_CC;

//JPG文件结构说明:
//
//	<Start Segment>	ff, d8
//
//	<Segment 1>
//	<Segment 2>
//	...
//	<Segment n>
//
//	图像压缩数据
//
//	<End Segment>	ff, d9
//
//	其中每个segment:
//	0xff,<Segment ID>[,<Segment length>]
//		Segment ID:
//		SOI		D8		文件头
//		EOI		D9		文件尾
//		SOF0	C0		帧开始（标准 JPEG）
//		SOF1	C1		同上
//		DHT		C4		定义 Huffman 表（霍夫曼表）
//		SOS		DA		扫描行开始
//		DQT		DB		定义量化表
//		DRI		DD		定义重新开始间隔
//		APP0	E0		定义交换格式和图像识别信息
//		COM		FE		注释
//		除起始和结束段都有段长度, motorola字节顺序, 长度包括长度字段本身, 但不包含0xff和段标识
//
//	IDF信息段格式:
//		char		1		0xff
//		char		1		0xe1
//		uint16_t	2		wSegmentLength，包括长度字段本身
//		char[6]		6		IDF,0,0
//		char[2]		2		II,为tiff header起始
//		uint16_t	2		0x2a,00
//		<IDF0>
//		<IDF1>
//		...
//
//	IDF格式:
//		uint32_t			4		nOffset,以tiff header为起始点
//		uint16_t			2		cnRecord
//		<Record0>
//		<Record1>
//		...
//
//	Record格式:
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
//		uint32_t			4		nOffset,也是以tiff header为起始点的
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
//		定义 APP 标识(SECTION)
//		#define M_APP0  0xE0
//		#define M_APP1  0xE1
//		#define M_APP2  0xE2
//		#define M_APP3  0xE3
//		#define M_APP4  0xE4
//		#define M_APP5  0xE5
//		#define M_APP6  0xE6
//		...
//
//		#define TAG_MAKE              0x010F    //相机DC 制造商
//		#define TAG_MODEL             0x0110    //DC 型号
//		#define TAG_ORIENTATION       0x0112    //拍摄时方向，例如向左手旋转DC 90度拍摄照片
//		#define TAG_XRESOLUTION       0x011A    //X 轴分辨率
//		#define TAG_YRESOLUTION       0x011B    //Y 轴分辨率
//		#define TAG_RESOLUTIONUNIT    0x0128    //分辨率单位，例如 inch, cm 
//		#define TAG_DATATIME          0x0132    //日期时间
//		#define TAG_YBCR_POSITION     0x0213    //YCbCr 位置控制，例如 居中
//		#define TAG_COPYRIGHT         0x8298    //版权
//		#define TAG_EXIF_OFFSET       0x8769    //EXIF 偏移，这时候相当于处理一个新的 EXIF 信息
//		#define TAG_IMAGEWIDTH        0x0001    //图像宽度
//		#define TAG_IMAGEHEIGHT       0x0101    //图像高度
//		#define TAG_EXPOSURETIME      0x829A    //曝光时间，例如 1/30 秒
//		#define TAG_FNUMBER           0x829D    //光圈，例如 F2.8
//		#define TAG_EXIF_VERSION      0x9000    //EXIF 信息版本
//		#define TAG_DATETIME_ORIGINAL 0x9003    //照片拍摄时间，例如 2005-10-13 11:09:35
//		#define TAG_DATATIME_DIGITIZED  0x9004  //相片被其它图像修改软件修改后的时间，例如  2005-10-13 11:36:35
//		#define TAG_COMPONCONFIG      0x9101    //ComponentsConfiguration 色彩空间配置
//		#define TAG_COMPRESS_BIT      0x9202    //每像素压缩位数
//		#define TAG_SHUTTERSPEED      0x9201    //快门速度，例如 1/30 秒
//		#define TAG_APERTURE          0x9202    //光圈值，例如 F2.8
//		#define TAG_BRIGHTNESS        0x9203    //亮度
//		#define TAG_EXPOSURE_BIAS     0x9204    //曝光补偿，例如 EV0.0
//		#define TAG_MAXAPERTURE       0x9205    //最大光圈值，例如 F2.8
//		#define TAG_SUBJECT_DISTANCE  0x9206    //拍摄物距离，例如 3.11 米
//		#define TAG_METERING_MODE     0x9207    //测光模式，例如矩阵
//		#define TAG_WHITEBALANCE      0x9208    //LightSource 白平衡
//		#define TAG_FLASH             0x9209    //是否使用闪光灯
//		#define TAG_FOCALLENGTH       0x920A    //焦距，例如 7.09mm
//		#define TAG_USERCOMMENT       0x9286    //用户注释
//		#define TAG_MAKE_COMMENT      0x927C    //厂商注释。这个版本不提供(2005-10-13)
//		#define TAG_SUBSECTIME        0x9290    //SubSecTime
//		#define TAG_SUBTIME_ORIGINAL  0x9291    //SubSecTimeOriginal
//		#define TAG_SUBTIME_DIGITIZED 0x9292    //SubSecTimeDigitized
//		#define TAG_FLASHPIXVERSION   0x00A0    //Flash Pix 版本
//		#define TAG_COLORSPACE        0x01A0    //色彩空间，例如 sRGB
//		#define TAG_PIXEL_XDIMENSION  0x02A0    //
//		#define TAG_PIXEL_YDIMENSION  0x03A0    //
//		#define TAG_INTEROP_OFFSET    0xa005    //偏移
//		#define TAG_FOCALPLANEXRES    0xA20E    //焦平面X轴分辨率，例如 1024000/278
//		#define TAG_FOCALPLANEYRES    0xA20F    //焦平面X轴分辨率，例如 768000/209
//		#define TAG_FOCALPLANEUNITS   0xA210    //焦平面分辨率单位
//		#define TAG_EXIF_IMAGEWIDTH   0xA002    //EXIF 图像宽度(就是这张 JPG 图像)
//		#define TAG_EXIF_IMAGELENGTH  0xA003    //EXIF 图像高度
//		#define TAG_EXPOSURE_PROGRAM  0x8822    //
//		#define TAG_ISO_EQUIVALENT    0x8827    //
//		#define TAG_COMPRESSION_LEVEL 0x9102    //
//		#define TAG_THUMBNAIL_OFFSET  0x0201    //缩略图偏移
//		#define TAG_THUMBNAIL_LENGTH  0x0202    //缩略图大小
//		#define TAG_GPS_VERSIONID       0x0000  //GPS 版本
//		#define TAG_GPS_LATITUDEREF     0x0001  //纬度参考，例如南纬
//		#define TAG_GPS_LATITUDE        0x0002  //纬度值
//		#define TAG_GPS_LONGITUDEREF    0x0003  //经度参考，例如东经
//		#define TAG_GPS_LONGITUDE       0x0004  //经度值
//		#define TAG_GPS_ALTITUDEREF     0x0005  //海拔高度参考
//		#define TAG_GPS_ALTITUDE        0x0006  //海拔
//		#define TAG_GPS_TIMESTAMP       0x0007  //时间戳
//		#define TAG_GPS_SATELLITES      0x0008  //卫星
//		#define TAG_GPS_STATUS          0x0009  //状态
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
	int cnVar;							//变量数目
	int nOffset;						//数据所在位置偏移，不管数据长度是否低于4字节
}IDFINFO,*PIDFINFO;

//原则是nOffset四个字节可以容纳就不再单存
#define FMT_BYTE		1				//nLen为字节数，<=4偏移直接就是数据
#define FMT_STRING		2				//nLen为长度，<=4偏移直接就是数据
#define FMT_USHORT		3				//nLen为ushort数，<=2偏移直接就是数据
#define FMT_ULONG		4				//nLen为ulong数，<=1偏移直接就是数据
#define FMT_URATIONAL	5				//固定8字节一个，两个ulong,结果为a/b
#define FMT_SBYTE		6				//nLen为字节数，<=4偏移直接就是数据
#define FMT_UNDEFINED	7				//未定义，与BYTE相似
#define FMT_SSHORT		8				//nLen为sshort数，<=2偏移直接就是数据
#define FMT_SLONG		9				//nLen为ulong数，<=1偏移直接就是数据
#define FMT_SRATIONAL	10				//固定8字节，两个slong,结果为a/b
#define FMT_SINGLE		11				//4字节浮点数
#define FMT_DOUBLE		12				//8字节浮点数

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
