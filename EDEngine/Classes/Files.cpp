#include "Files.h"
#include "MD5.h"

USING_NS_CC;

#include "errno.h"
#if (CC_TARGET_PLATFORM == CC_PLATFORM_WIN32)
#include <direct.h>
#include "Shlobj.h"
#pragma comment(lib,"Shell32")
#endif
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
#include "sys/types.h"
#include "sys/stat.h"
#include "sys/time.h"
#include "fcntl.h"
#include <dirent.h>

extern std::string g_ExternalStorageDirectory;
std::string GetSDCardDir()
{
	return g_ExternalStorageDirectory;
}

#endif

#define min(a,b) ((a)>(b)?(b):(a))
#define max(a,b) ((a)>(b)?(a):(b))

int GetError()
{
#ifdef WIN32
	return (GetLastError());
#else
	return (errno);
#endif
}

//申请内存，读取指定文件特定位置的指定长度
//
//	参数说明：
//	pnLength			返回文件长度，文件末尾添加了一个0字符，但长度没有包含0，NULL时不返回长度
//	nReservedTop		返回缓冲区前保留多少字节，默认为0
//	nReservedTail		返回缓冲区后保留多少字节，默认为0
//	nStartPoint			文件起始位置，默认为0
//	nReadLength			读取长度，默认为0，表示读取全部内容
char *ReadDataFile(const char *pszFile,uint32_t *pnLength,uint32_t nReservedTop,uint32_t nReservedTail,uint32_t nStartPoint,uint32_t nReadLength)
{
	FILE *fp=fopen(pszFile,"rb");
	int nErrorNo=GetError();
	if (nErrorNo!=0)
	{
		CCLog("can not read file: %s, error: %d",pszFile,nErrorNo);
	}
	if (fp==NULL) return NULL;

	fseek(fp,0L,SEEK_END);
	uint32_t len=ftell(fp);
	//文件长度不够
	if (len<=nStartPoint)
	{
		fclose(fp);
		return NULL;
	}

	if (nReadLength==0)
	{
		//实际需要读取的长度
		nReadLength=len-nStartPoint;
	}
	else
	{
		//实际需要读取的长度
		nReadLength=min(len-nStartPoint,nReadLength);
	}

	if (nReadLength==0)
	{
		fclose(fp);
		return NULL;
	}

	char *pBuf=(char *)malloc(len+nReservedTop+max(nReservedTail,1));
	if (pBuf==NULL)
	{
		fclose(fp);
		return NULL;
	}
	fseek(fp,0L,SEEK_SET);
	fread(pBuf+nReservedTop,sizeof(char),nReadLength,fp);
	fclose(fp);

	if (pnLength!=NULL) *pnLength=nReadLength;

	//尾巴加个0，方便程序使用
	pBuf[nReservedTop+nReadLength]=0;
	return pBuf;
}

bool WriteDataFile(const char *pszFile,const char *pData,int len)
{
	FILE *fp=fopen(pszFile,"wb");
	if (fp==NULL)
	{
        MakeDirForFile(pszFile);
        fp=fopen(pszFile,"wb");
        if (fp==NULL)
        {
            CCLog("can not create file: %s, %d, %d",pszFile,len,GetError());
            return false;
        }
	}
	int nRet=fwrite(pData,sizeof(char),len,fp);
	fclose(fp);
	if (nRet!=len)
	{
		EraseFile(pszFile);

		CCLog("can not write file: %s, %d, %d",pszFile,len,GetError());
		return false;
	}
	return true;
}

int GetFileLength(const char *pszFile)
{
	FILE *fp=fopen(pszFile,"rb");
	if (fp==NULL) return 0;
	fseek(fp,0,SEEK_END);
	int len=ftell(fp);
	fclose(fp);
	return len;
}

bool IsFileExist(const char *pszPathName)
{
	FILE *fp=fopen(pszPathName,"rb");
	if (fp!=NULL) fclose(fp);
	return fp!=NULL;
}

int MakeDir(const char *pszDir)
{
	int nRet;
#if (CC_TARGET_PLATFORM == CC_PLATFORM_WIN32)
	nRet=_mkdir(pszDir);
#endif
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
	nRet=mkdir(pszDir,S_IRWXU | S_IRWXG | S_IRWXO);
	chmod(pszDir,0x777);
#endif
#if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)
	nRet=mkdir(pszDir,0xffff);
#endif
	int nError=GetError();
	return nRet;
}

void MakeDirForFile(const char *pszPathName)
{
	const char *s=pszPathName;
	std::string strDir;
	while (true)
	{
		s=strchr(s,'/');
		if (s==NULL) break;

		strDir.clear();
		strDir.append(pszPathName,s-pszPathName);
		MakeDir(strDir.c_str());
		s++;
	}
}

void MakeFullDir(const char *pszPathName)
{
	const char *s=pszPathName;
	std::string strDir;
	while (true)
	{
		s=strchr(s,'/');
		if (s==NULL) break;

		strDir.clear();
		strDir.append(pszPathName,s-pszPathName);
		MakeDir(strDir.c_str());
		s++;
	}
	MakeDir(pszPathName);
}

bool EraseFile(const char *pszPathName)
{
	bool bRet;
#if (CC_TARGET_PLATFORM == CC_PLATFORM_WIN32)
	bRet=DeleteFileA(pszPathName) ? true : false;
#else
	bRet=(unlink(pszPathName)==0);
#endif
	return bRet;
}

//判断是否为目录
#if (CC_TARGET_PLATFORM != CC_PLATFORM_WIN32)
bool is_dir(const char *path)
{
	struct stat statbuf;
	if (lstat(path, &statbuf) ==0)//lstat返回文件的信息，文件信息存放在stat结构中
	{
		return S_ISDIR(statbuf.st_mode) != 0;//S_ISDIR宏，判断文件类型是否为目录
	}
	return false;
}

//判断是否为常规文件
bool is_file(const char *path)
{
	struct stat statbuf;
	if (lstat(path, &statbuf)==0) return S_ISREG(statbuf.st_mode) != 0;//判断文件是否为常规文件
	return false;
}
#endif

bool EraseDir(const char *pszPath)
{
#if (CC_TARGET_PLATFORM == CC_PLATFORM_WIN32)
	char szPathOrg[_MAX_PATH];
	strcpy(szPathOrg,pszPath);
	char *s=szPathOrg+strlen(szPathOrg)-1;
	if (*s=='/' || *s=='\\') *s=0;
	pszPath=szPathOrg;

	//目录属性读取失败
	DWORD dwAttr=GetFileAttributesA(pszPath);
	if (dwAttr==-1) return false;

	//是文件
	if ((dwAttr & FILE_ATTRIBUTE_DIRECTORY)==0) return false;

	char szPathName[_MAX_PATH];
	sprintf(szPathName,"%s/*.*",pszPath);

	WIN32_FIND_DATAA wfd;
	HANDLE hFind=FindFirstFileA(szPathName,&wfd);

	bool bRet=true;
	if (hFind!=INVALID_HANDLE_VALUE)
	{
		while (true)
		{
			if (wfd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)
			{
				//还是目录
				if (wfd.cFileName[0]!='.')
				{
					//真正的目录
					sprintf(szPathName,"%s/%s",pszPath,wfd.cFileName);
					//递归删除子目录
					if (!EraseDir(szPathName)) 
					{
						//子目录删除失败
						bRet=false;
						break;
					}
				}
			}
			else
			{
				//是文件了
				sprintf(szPathName,"%s/%s",pszPath,wfd.cFileName);
				if (!EraseFile(szPathName))
				{
					//文件删除失败
					bRet=false;
					break;
				}
			}
			//继续找下一个
			if (!FindNextFileA(hFind,&wfd)) break;
		}
		FindClose(hFind);
	}
	if (!bRet) return false;

	//目录下的文件都已经删光了，再删除目录本身
	return (_rmdir(pszPath)==0);
#else
	char szPathOrg[PATH_MAX];
	strcpy(szPathOrg,pszPath);
	char *s=szPathOrg+strlen(szPathOrg)-1;
	if (*s=='/' || *s=='\\') *s=0;
	pszPath=szPathOrg;

	if (!is_dir(pszPath))
	{
		return false;
	}

	DIR *dir;
	dirent *dir_info;
	if ((dir = opendir(pszPath)) == NULL) return false;

	char file_path[PATH_MAX];
	while ((dir_info = readdir(dir)) != NULL)
	{
		const char *pszName=dir_info->d_name;
		if (strcmp(pszName,".")==0 || strcmp(pszName,"..")==0) continue;

		sprintf(file_path,"%s/%s",pszPath,pszName);

		if (is_file(file_path))
		{
			EraseFile(file_path);
		}
		else
		{
			EraseDir(file_path);
		}
	}
	closedir(dir);
	return (rmdir(pszPath)==0);
#endif
}

void GeneUniqueName(const char *pData,int len,char *pszUniqueName)
{
	sha1((const unsigned char *)pData,len,(unsigned char *)pszUniqueName);
	return;
}

bool GeneUniqueName(const char *pszPathName,char *pszUniqueName)
{
	uint32_t len;
	char *pBuf=ReadDataFile(pszPathName,&len);
	if (pBuf==NULL) return false;

	GeneUniqueName(pBuf,len,pszUniqueName);
	free(pBuf);
	return true;
}

CDirMng::CDirMng()
{
	m_nUserID=0;
}

CDirMng::~CDirMng()
{
}

static CDirMng *s_pDirMng=NULL;

std::string genUniqueName()
{
	char unqstr[256];
#if CC_TARGET_PLATFORM == CC_PLATFORM_WIN32
		DWORD dt = GetTickCount();
		GeneUniqueName( (const char*)&dt,sizeof(dt),unqstr);
#elif CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID
		timeval tv;
		gettimeofday(&tv,NULL);
		GeneUniqueName( (const char*)&tv.tv_usec,sizeof(tv.tv_usec),unqstr );
#endif
	return std::string( unqstr );
}

std::string allocTmpFile( std::string suffix )
{
	std::string result;
	if( s_pDirMng )
	{
		result = s_pDirMng->GetDataDir() + "EDEngine/tmp/" + genUniqueName() + suffix;
	}
	else
	{
		CCLOG("allocTmpFile s_pDirMng = NULL");
	}
	return result;
}

void releaseTmpFile( std::string file )
{
	EraseFile( file.c_str() );
}

bool CDirMng::Init(const char *pszAppName)
{
	m_strAppName=pszAppName;

#if (CC_TARGET_PLATFORM == CC_PLATFORM_WIN32)
	char szDocPath[MAX_PATH];
	SHGetFolderPathA(NULL, CSIDL_APPDATA, NULL, SHGFP_TYPE_CURRENT, szDocPath);
	m_strDataDir=szDocPath;
	m_strDataDir+="/ljdata/";
	//调试状态目录
#ifdef DEBUG
	m_strDataDir="u:\\ljdata/";
#endif
#else

#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
	//--------------------------------------------------------------------------------------------------
	//for android，找到内置的sd卡根目录
	//--------------------------------------------------------------------------------------------------
	m_strDataDir=GetSDCardDir();
	CCLog("SDCardDir: %s",m_strDataDir.c_str());
	m_strDataDir+="ljdata/";
#else
	//--------------------------------------------------------------------------------------------------
	//for IOS，直接使用writable path
	//--------------------------------------------------------------------------------------------------
	m_strDataDir=CCFileUtils::sharedFileUtils()->getWritablePath();
#endif

#endif
	m_strShareDir=m_strDataDir+"share/";
	m_strLobbyDir=m_strDataDir+"ljshell/";
	m_strDownloadDir=m_strShareDir+"download/";

	m_strAppDir=m_strDataDir+m_strAppName.c_str();
	m_strAppDir+="/";
	MakeFullDir(m_strAppDir.c_str()); //创建目录
	m_strAppDataDir=m_strAppDir+"data/";
	MakeFullDir(m_strAppTmpDir.c_str()); //创建数据目录
	m_strAppTmpDir=m_strAppDir+"tmp/";
	MakeFullDir(m_strAppTmpDir.c_str()); //创建临时目录
	
	m_strIDNamePathName=m_strShareDir+"IDName.json";
	m_strShareSettingsPathName=m_strShareDir+"ShareSettings.json";

	s_pDirMng=this;
	return true;
}

bool CDirMng::InitUser(int nUserID)
{
	m_nUserID=nUserID;
	if (m_nUserID==0) return false;

	if (m_strDataDir.empty()) return false;

	char szUserID[32];
	sprintf(szUserID,"/%d/",nUserID);
	m_strUserDir=m_strShareDir+"user";
	m_strUserDir+=szUserID;

	m_strAppUserDir=m_strAppDir+"user";
	m_strAppUserDir+=szUserID;

	m_strUserSettingsPathName=m_strUserDir+"UserSettings.json";
	return true;
}

CRscName::CRscName()
{
}

CRscName::CRscName(const char *pszFullName)
{
	Init(pszFullName);
}

CRscName::CRscName(const char *pszTypeName,const char *pszName)
{
	Init(pszTypeName,pszName);
}

void CRscName::Init(const char *pszFullName)
{
	m_strTypeName.clear();
	const char *s=strchr(pszFullName,':');
	if (s!=NULL)
	{
		m_strTypeName.append(pszFullName,s-pszFullName);
		m_strName=s+1;
	}
	else
    {
        m_strTypeName="imfile";
        m_strName=pszFullName;
    }
}

void CRscName::Init(const char *pszTypeName,const char *pszName)
{
    SetTypeName(pszTypeName);
    SetName(pszName);
}

void CRscName::SetTypeName(const char *pszTypeName)
{
    if (pszTypeName==NULL || *pszTypeName==0) m_strTypeName="imfile";
	else m_strTypeName=pszTypeName;
}

void CRscName::SetName(const char *pszName)
{
	m_strName=pszName;
}

std::string CRscName::GetFullName()
{
	std::string str;
	if (m_strTypeName.empty() || strcmp(m_strTypeName.c_str(),"imfile")==0) str=m_strName;
	else
	{
		str=m_strTypeName+':';
		str+=m_strName;
	}
	return str;
}

int CRscName::GetServerType()
{

	const char *pszTypeName=m_strTypeName.c_str();

	if (m_strTypeName.empty() || strcmp(pszTypeName,"imfile")==0) return servertype_imfile;

	else if (strcmp(pszTypeName,"userlogo")==0) return servertype_image;
	else if (strcmp(pszTypeName,"applogo")==0) return servertype_image;
	else if (strcmp(pszTypeName,"emote")==0) return servertype_image;

	else if (strcmp(pszTypeName,"api")==0) return servertype_api;
	else if (strcmp(pszTypeName,"image")==0) return servertype_image;
	else if (strcmp(pszTypeName,"file")==0) return servertype_file;
	else if (strcmp(pszTypeName,"im")==0) return servertype_im;

	return servertype_imfile;
}

std::string CRscName::GetDownloadURL(int nStart,int nEnd,int nWidth,int nHeight)
{
	char szURL[256];
	szURL[0]=0;

	const char *pszTypeName=m_strTypeName.c_str();
	if (strcmp(pszTypeName,"userlogo")==0)
	{
		sprintf(szURL,"/userlogo/%s/99",m_strName.c_str());
	}
	else if (strcmp(pszTypeName,"applogo")==0)
	{
		sprintf(szURL,"/applogo/%s/1",m_strName.c_str());
	}
	else if (strcmp(pszTypeName,"emote")==0)
	{
		sprintf(szURL,"/emote/%s/99",m_strName.c_str());
	}
	else if (*pszTypeName==0 || strcmp(pszTypeName,"file")==0 || strcmp(pszTypeName,"imfile")==0)
	{
		if (nWidth==0)
		{
			if (nStart>=0)
			{
				sprintf(szURL,"/rest/dl/%s/%d_%d",m_strName.c_str(),nStart,nEnd);
			}
			else
			{
				sprintf(szURL,"/rest/dl/%s",m_strName.c_str());
			}
		}
		else
		{
			if (nStart>=0)
			{
				sprintf(szURL,"/rest/dlimage/%s/%d_%d/%d_%d",m_strName.c_str(),nWidth,nHeight,nStart,nEnd);
			}
			else
			{
				sprintf(szURL,"/rest/dlimage/%s/%d_%d",m_strName.c_str(),nWidth,nHeight);
			}
		}
	}
	return std::string(szURL);
}

std::string CRscName::GetUploadURL()
{
	char szURL[256];
	strcpy(szURL,"/rest/user/upload/chat");

	return std::string(szURL);
}

std::string CRscName::GetLocalPathName()
{
	std::string str=s_pDirMng->GetDownloadDir();
	if (!m_strTypeName.empty())
	{
		str+=m_strTypeName;
		str+='/';
	}
	uint32_t nCheckSum=GetCheckSum32(m_strName.c_str());
	char szSub[32];
	sprintf(szSub,"%u/",nCheckSum % 255);
	str+=szSub;
	str+=m_strName;

	return str;
}
