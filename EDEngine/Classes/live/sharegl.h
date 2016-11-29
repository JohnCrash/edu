#ifndef __FFSHAREGL__H__
#define __FFSHAREGL__H__

namespace ff
{
	int ffInitShare();
	void ffReleaseShare();
	int ffShareMakeCurrent();
	void ffShareMakeCurrentClear();
}
#endif