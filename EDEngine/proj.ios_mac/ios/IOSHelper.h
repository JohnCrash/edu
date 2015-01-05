#include "staticlib.h"
#include <string>

MySpaceBegin

bool IOS_StartApp(const char *pszURI);

bool IOS_VoiceStartRecord(int cnChannel,int nRate,int cnBitPerSample=16);
bool IOS_VoiceStopRecord();

bool IOS_VoiceStartPlay(char *pBuf,int lenBuf);
bool IOS_VoiceIsPlaying();
bool IOS_VoiceStopPlay();
bool IOS_DoVibrator();

int IOS_GetNetStatus();
bool IOS_IsIPhone();
bool IOS_IsIPad();

bool IOS_CopyToClipboard(const char *pszText);
std::string IOS_CopyFromClipboard();
bool IOS_IsPackageExist(const char *pszURL);
bool IOS_StartApp(const char *pszURL);

int TakePhoto();
int PickPicture();

void setMutiTouchEnabled( bool b );

MySpaceEnd