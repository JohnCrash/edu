#ifndef __LJFILES_H__
#define __LJFILES_H__

//常用函数库
#include "staticlib.h"
#include "cocos2d.h"

MySpaceBegin

#define	servertype_min			1

#define	servertype_login		1
#define	servertype_api			2
#define	servertype_image		3
#define	servertype_file			4
#define	servertype_im			5
#define	servertype_imfile		6

#define	servertype_max			6

int GetError();

//读取文件数据
char *ReadDataFile(const char *pszFile,uint32_t *pnLength=NULL,uint32_t nReservedTop=0,uint32_t nReservedTail=0,uint32_t nStartPoint=0,uint32_t nReadLength=0);
bool WriteDataFile(const char *pszFile,const char *pData,int len);
int GetFileLength(const char *pszFile);
bool IsFileExist(const char *pszPathName);
int MakeDir(const char *pszDir);
bool EraseDir(const char *pszPath);
void MakeDirForFile(const char *pszPathName);
void MakeFullDir(const char *pszPathName);
bool EraseFile(const char *pszPathName);

void GeneUniqueName(const char *pData,int len,char *pszUniqueName);
bool GeneUniqueName(const char *pszPathName,char *pszUniqueName);

std::string genUniqueName(); //产生一个随机的文件名称，确保不重复
std::string allocTmpFile( std::string suffix );
void releaseTmpFile( std::string file );

class CDirMng
{
public:
	CDirMng();
	~CDirMng();

	bool Init(const char *pszAppName);
	bool InitUser(int nUserID);

	//所有目录都以/结尾，方便合并文件名

	//------------------------------------------------------------------------------------------------
	//folders
	//------------------------------------------------------------------------------------------------
	std::string &GetDataDir(){return m_strDataDir;}								//数据跟目录，比如：/ljdata/
	std::string &GetShareDir(){return m_strShareDir;}							//共享文件目录，比如：/ljdata/Share
	std::string &GetLobbyDir(){return m_strLobbyDir;}							//ljshell应用的目录，比如：/ljdata/ljshell
	std::string &GetDownloadDir(){return m_strDownloadDir;}						//下载资源目录，比如：/ljdata/share/download/
	
	std::string &GetAppDir(){return m_strAppDir;}								//应用目录，比如：/ljdata/homework/
	std::string &GetAppDataDir(){return m_strAppDataDir;}						//应用数据目录，比如：/ljdata/homework/data/
	std::string &GetAppTmpDir(){return m_strAppTmpDir;}							//应用临时文件目录，比如：/ljdata/homework/tmp/

	std::string &GetUserDir(){return m_strUserDir;}								//用户信息目录，比如：/ljdata/share/user/14757/
	std::string &GetAppUserDir(){return m_strAppUserDir;}						//应用用户私有数据目录，比如：/ljdata/homework/user/14757/

	//------------------------------------------------------------------------------------------------
	//files
	//------------------------------------------------------------------------------------------------
	std::string &GetIDNamePathName(){return m_strIDNamePathName;}				//用户及群组id和中文名对照表json文件，比如：/ljdata/share/IDName.json
	std::string &GetShareSettingsPathName(){return m_strShareSettingsPathName;}	//共享配置文件目录，比如：/ljdata/share/ShareSettings.json
	std::string &GetUserSettingsPathName(){return m_strUserSettingsPathName;}	//当前用户私有配置文件，比如：/ljdata/share/user/14757/UserSettings.json

protected:
	std::string m_strAppName;
	int m_nUserID;

	std::string m_strDataDir;
	std::string m_strShareDir;
	std::string m_strLobbyDir;
	std::string m_strDownloadDir;

	std::string m_strAppDir;
	std::string m_strAppDataDir;
	std::string m_strAppTmpDir;

	std::string m_strUserDir;
	std::string m_strAppUserDir;

	std::string m_strIDNamePathName;
	std::string m_strShareSettingsPathName;
	std::string m_strUserSettingsPathName;
};

//资源名称说明：
//[type]:name
class CRscName
{
public:
	CRscName();

	CRscName(const char *pszFullName);
	CRscName(const char *pszTypeName,const char *pszName);

	void Init(const char *pszFullName);
	void Init(const char *pszTypeName,const char *pszName);

	void SetTypeName(const char *pszTypeName);
	void SetName(const char *pszName);

	std::string GetFullName();
	const char *GetTypeName(){return m_strTypeName.c_str();}
	const char *GetName(){return m_strName.c_str();}

	int GetServerType();
	std::string GetDownloadURL(int nStart=-1,int nEnd=-1,int nWidth=0,int nHeight=0);
	std::string GetUploadURL();
	std::string GetLocalPathName();

protected:
	std::string m_strTypeName;
	std::string m_strName;
};

MySpaceEnd
#endif // __LJFILES_H__
