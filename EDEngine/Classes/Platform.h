#ifndef _PLATFORM_H_
#define _PLATFORM_H_

#include <string>

void takeResource( int mode );
void takeResource_callback(std::string resource,int typeCode,int resultCode);

bool startRecord( std::string file );
void stopRecord();

bool initAMREncoder(int cnChannel,int nRate,int cnBitPerSample,int nMode);
void releaseAMREncoder();

#if CC_TARGET_PLATFORM == CC_PLATFORM_ANDORID
#elif CC_TARGET_PLATFORM == CC_PLATFORM_WIN32
#else
#endif

#endif