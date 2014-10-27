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

//�����ڴ棬��ȡָ���ļ��ض�λ�õ�ָ������
//
//	����˵����
//	pnLength			�����ļ����ȣ��ļ�ĩβ�����һ��0�ַ���������û�а���0��NULLʱ�����س���
//	nReservedTop		���ػ�����ǰ���������ֽڣ�Ĭ��Ϊ0
//	nReservedTail		���ػ��������������ֽڣ�Ĭ��Ϊ0
//	nStartPoint			�ļ���ʼλ�ã�Ĭ��Ϊ0
//	nReadLength			��ȡ���ȣ�Ĭ��Ϊ0����ʾ��ȡȫ������
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
	//�ļ����Ȳ���
	if (len<=nStartPoint)
	{
		fclose(fp);
		return NULL;
	}

	if (nReadLength==0)
	{
		//ʵ����Ҫ��ȡ�ĳ���
		nReadLength=len-nStartPoint;
	}
	else
	{
		//ʵ����Ҫ��ȡ�ĳ���
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

	//β�ͼӸ�0���������ʹ��
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

//�ж��Ƿ�ΪĿ¼
#if (CC_TARGET_PLATFORM != CC_PLATFORM_WIN32)
bool is_dir(const char *path)
{
	struct stat statbuf;
	if (lstat(path, &statbuf) ==0)//lstat�����ļ�����Ϣ���ļ���Ϣ�����stat�ṹ��
	{
		return S_ISDIR(statbuf.st_mode) != 0;//S_ISDIR�꣬�ж��ļ������Ƿ�ΪĿ¼
	}
	return false;
}

//�ж��Ƿ�Ϊ�����ļ�
bool is_file(const char *path)
{
	struct stat statbuf;
	if (lstat(path, &statbuf)==0) return S_ISREG(statbuf.st_mode) != 0;//�ж��ļ��Ƿ�Ϊ�����ļ�
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

	//Ŀ¼���Զ�ȡʧ��
	DWORD dwAttr=GetFileAttributesA(pszPath);
	if (dwAttr==-1) return false;

	//���ļ�
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
				//����Ŀ¼
				if (wfd.cFileName[0]!='.')
				{
					//������Ŀ¼
					sprintf(szPathName,"%s/%s",pszPath,wfd.cFileName);
					//�ݹ�ɾ����Ŀ¼
					if (!EraseDir(szPathName)) 
					{
						//��Ŀ¼ɾ��ʧ��
						bRet=false;
						break;
					}
				}
			}
			else
			{
				//���ļ���
				sprintf(szPathName,"%s/%s",pszPath,wfd.cFileName);
				if (!EraseFile(szPathName))
				{
					//�ļ�ɾ��ʧ��
					bRet=false;
					break;
				}
			}
			//��������һ��
			if (!FindNextFileA(hFind,&wfd)) break;
		}
		FindClose(hFind);
	}
	if (!bRet) return false;

	//Ŀ¼�µ��ļ����Ѿ�ɾ���ˣ���ɾ��Ŀ¼����
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
	//����״̬Ŀ¼
#ifdef DEBUG
	m_strDataDir="u:\\ljdata/";
#endif
#else

#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
	//--------------------------------------------------------------------------------------------------
	//for android���ҵ����õ�sd����Ŀ¼
	//--------------------------------------------------------------------------------------------------
	m_strDataDir=GetSDCardDir();
	CCLog("SDCardDir: %s",m_strDataDir.c_str());
	m_strDataDir+="ljdata/";
#else
	//--------------------------------------------------------------------------------------------------
	//for IOS��ֱ��ʹ��writable path
	//--------------------------------------------------------------------------------------------------
	m_strDataDir=CCFileUtils::sharedFileUtils()->getWritablePath();
#endif

#endif
	m_strShareDir=m_strDataDir+"share/";
	m_strLobbyDir=m_strDataDir+"ljshell/";
	m_strDownloadDir=m_strShareDir+"download/";

	m_strAppDir=m_strDataDir+m_strAppName.c_str();
	m_strAppDir+="/";
	MakeFullDir(m_strAppDir.c_str()); //����Ŀ¼
	m_strAppDataDir=m_strAppDir+"data/";
	MakeFullDir(m_strAppTmpDir.c_str()); //��������Ŀ¼
	m_strAppTmpDir=m_strAppDir+"tmp/";
	MakeFullDir(m_strAppTmpDir.c_str()); //������ʱĿ¼
	
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
