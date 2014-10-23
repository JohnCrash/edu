#include "Platform.h"

bool initAMREncoder(int cnChannel,int nRate,int cnBitPerSample,int nMode)
{
	if (!IsValidParam(cnChannel,nRate,cnBitPerSample)) 
	{
		return false;
	}
}

void releaseAMREncoder()
{
}

