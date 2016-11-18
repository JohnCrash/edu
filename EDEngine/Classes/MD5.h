#ifndef __MD5_H__
#define __MD5_H__
#include "staticlib.h"
#include <string>
#include <stdio.h>

MySpaceBegin

typedef unsigned int uint32_t;
typedef unsigned long long uint64_t;

//字节序的小头和大头的问题
#define ZEN_LITTLE_ENDIAN  0x0123
#define ZEN_BIG_ENDIAN     0x3210
 
#ifndef ZEN_SWAP_UINT16
#define ZEN_SWAP_UINT16(x)  ((((x) & 0xff00) >>  8) | (((x) & 0x00ff) <<  8))
#endif

#ifndef ZEN_SWAP_UINT32
#define ZEN_SWAP_UINT32(x)  ((((x) & 0xff000000) >> 24) | (((x) & 0x00ff0000) >>  8) | (((x) & 0x0000ff00) <<  8) | (((x) & 0x000000ff) << 24))
#endif
#ifndef ZEN_SWAP_UINT64
#define ZEN_SWAP_UINT64(x)  ((((x) & 0xff00000000000000) >> 56) | (((x) & 0x00ff000000000000) >>  40) | \
    (((x) & 0x0000ff0000000000) >> 24) | (((x) & 0x000000ff00000000) >>  8) | \
    (((x) & 0x00000000ff000000) << 8 ) | (((x) & 0x0000000000ff0000) <<  24) | \
    (((x) & 0x000000000000ff00) << 40 ) | (((x) & 0x00000000000000ff) <<  56))
#endif
 
///MD5的结果数据长度
static const size_t ZEN_MD5_HASH_SIZE   = 16;
///SHA1的结果数据长度
static const size_t ZEN_SHA1_HASH_SIZE  = 20;
 
/*!
@brief      求某个内存块的MD5，
@return     unsigned char* 返回的的结果，
@param[in]  buf    求MD5的内存BUFFER指针
@param[in]  size   BUFFER长度
@param[out] result 结果
*/
unsigned char *md5(const unsigned char *buf,int len,unsigned char *result);
 

/*!
@brief      求内存块BUFFER的SHA1值
@return     unsigned char* 返回的的结果
@param[in]  buf    求SHA1的内存BUFFER指针
@param[in]  size   BUFFER长度
@param[out] result 结果
*/
unsigned char *sha1(const unsigned char *buf,size_t size,unsigned char *result);

unsigned int GetCheckSum32(const char *pData,int len=0);
unsigned long long GetCheckSum64(const char *pData,int len);
void Uint64ToBase16(unsigned long long nValue,char *pBase16);
void GetCheckSumStr16(const char *pSrc,int len,char *pDst);
//void md5(const unsigned char *pSrc,int len,unsigned char *pDst);

bool IsLittleEndian();
std::string CreateRandomString();

MySpaceEnd
#endif // __MD5_H__
