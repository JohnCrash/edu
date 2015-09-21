#ifdef WIN32
	#include <Windows.h>
	//#include <dbghelp.h>  
	#include <shellapi.h>  
	#include <shlobj.h>  
#elif __ANDROID__
	#include <android/log.h>
	#include <unistd.h>
	#include <signal.h>	
	#include <string.h>
	#include <assert.h>
	#include <dlfcn.h>
	#	include <string>
	/* 仅仅为了取得程序的读写路径 */
	#include "cocos2d.h"
	#ifndef NDEBUG
	#define Verify(x, r)  assert((x) && r)
	#else
	#define Verify(x, r)  ((void)(x))
	#endif
	
	static struct sigaction old_sa[NSIG];
	
	typedef struct map_info_t map_info_t;
	typedef struct {
		uintptr_t absolute_pc;
		uintptr_t stack_top;
		size_t stack_size;
	} backtrace_frame_t;
	typedef struct {
		uintptr_t relative_pc;
		uintptr_t relative_symbol_addr;
		char* map_name;
		char* symbol_name;
		char* demangled_name;
	} backtrace_symbol_t;
	typedef ssize_t (*t_unwind_backtrace_signal_arch)(siginfo_t* si, void* sc, const map_info_t* lst, backtrace_frame_t* bt, size_t ignore_depth, size_t max_depth);
	static t_unwind_backtrace_signal_arch unwind_backtrace_signal_arch;
	typedef map_info_t* (*t_acquire_my_map_info_list)();
	static t_acquire_my_map_info_list acquire_my_map_info_list;
	typedef void (*t_release_my_map_info_list)(map_info_t* milist);
	static t_release_my_map_info_list release_my_map_info_list;
	typedef void (*t_get_backtrace_symbols)(const backtrace_frame_t* backtrace, size_t frames, backtrace_symbol_t* symbols);
	static t_get_backtrace_symbols get_backtrace_symbols;
	typedef void (*t_free_backtrace_symbols)(backtrace_symbol_t* symbols, size_t frames);
	static t_free_backtrace_symbols free_backtrace_symbols;	
#endif
#include <stdio.h>
#include "acr.h"

#define MAX_LOG 64
#define MAX_SIZE 256
int _current = -1;
char _logs[MAX_LOG][MAX_SIZE];

/*
 * 初始化日志缓冲
 * 作一个循环的字符串缓冲，日志如果溢出就回到0，构成一个循环日志。
 */
void acr_init_log()
{
	_current = 0;
	for (int i = 0; i < MAX_LOG; i++)
		_logs[i][0] = 0;
}

void acr_add_log(const char * msg)
{
	if (_current == -1)
		acr_init_log();
	if (msg){
		int len = strlen(msg);
		if ( len < MAX_SIZE - 3){
			strcpy(_logs[_current], msg);
			/* 如果结尾不是\n补上一个\n */
			if (_logs[_current][len - 1] != '\n'){
				_logs[_current][len] = '\n';
				_logs[_current][len+1] = 0;
			}
		}
		else
		{
			memcpy(_logs[_current], msg, MAX_SIZE-1);
			_logs[_current][MAX_SIZE-1] = 0;
			/* 如果结尾不是\n补上一个\n */
			if (_logs[_current][MAX_SIZE - 2] != '\n'){
				_logs[_current][MAX_SIZE - 2] = '\n';
			}
		}
		_current++;
		if (_current >= MAX_LOG)
			_current = 0;
	}
}

/*
 * 将日志写入到文件
 */
void acr_write_log(const char *filename)
{
	if (_current == -1)
		acr_init_log();
	FILE *fp = fopen(filename, "wb");
	if (fp){
		for (int i = _current + 1; i < MAX_LOG; i++)
		{
			int len = strlen(_logs[i]);
			if (len>0)
				fwrite(_logs[i], 1, len, fp);
		}
		for (int i = 0; i <= _current; i++)
		{
			int len = strlen(_logs[i]);
			if (len>0)
				fwrite(_logs[i], 1, len, fp);
		}
		fclose(fp);
	}
}

#ifdef WIN32
/*
 * windows 结构化异常处理函数
 */
LONG WINAPI MyUnhandledExceptionFilter(struct _EXCEPTION_POINTERS *pExceptionPointers)
{
	SetErrorMode(SEM_NOGPFAULTERRORBOX);

	//收集信息  
	char strBuild[256];
	char strError[1024];
	char strStack[1024];
	HMODULE hModule;
	char szModuleName[MAX_PATH] = "";

	/*
	 * 这里创建cpu寄存器的信息
	 */
	sprintf(strBuild, "Build: %s %s\n", __DATE__, __TIME__);
	GetModuleHandleEx(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS, (LPCWSTR)pExceptionPointers->ExceptionRecord->ExceptionAddress, &hModule);
	GetModuleFileNameA(hModule, szModuleName, ARRAYSIZE(szModuleName));
	sprintf(strError,"%s %08X , %08X ,%08X.\n", szModuleName, pExceptionPointers->ExceptionRecord->ExceptionCode, pExceptionPointers->ExceptionRecord->ExceptionFlags, pExceptionPointers->ExceptionRecord->ExceptionAddress);
	sprintf(strStack,"Eip=%08X,Esp=%08X,Ebp=%08X\nEdi=%08X,Esi=%08X,Ebx=%08X\nEdx=%08X,Ecx=%08X,Eax=%08X", 
		pExceptionPointers->ContextRecord->Eip, pExceptionPointers->ContextRecord->Esp, pExceptionPointers->ContextRecord->Ebp,
		pExceptionPointers->ContextRecord->Edi, pExceptionPointers->ContextRecord->Esi, pExceptionPointers->ContextRecord->Ebx,
		pExceptionPointers->ContextRecord->Edx, pExceptionPointers->ContextRecord->Ecx, pExceptionPointers->ContextRecord->Eax
		);

	/*
	 * Edengine 在启动时会寻找crash.dump文件
	 */
	char szDocPath[MAX_PATH];
	char szPath[MAX_PATH];
	char szFileName[MAX_PATH];
	SHGetFolderPathA(NULL, CSIDL_APPDATA, NULL, SHGFP_TYPE_CURRENT, szDocPath);
	sprintf(szFileName, "%s\\ljdata\\EDEngine\\crash.dump",
		szDocPath);
	FILE *fp = fopen(szFileName, "wb");
	if (fp){
		fwrite(strBuild, 1,strlen(strBuild), fp);
		fwrite(strError, 1, strlen(strError), fp);
		fwrite(strStack, 1, strlen(strStack), fp);
		fclose(fp);
	}
	sprintf(szFileName, "%s\\ljdata\\EDEngine\\crash.log",
		szDocPath);
	/*
	 * 奔溃时将lua的日志也写入到crash.log文件
	 */
	acr_write_log(szFileName);
	/*
	 * 产生一个mini crash dump 文件，但是这需要dbghelp.dll的支持
	 * 并且mini dump文件一般都140k目前暂时去掉
	 */
	//生成 mini crash dump  
	/*
	BOOL bMiniDumpSuccessful;
	WCHAR szDocPath[MAX_PATH];
	WCHAR szPath[MAX_PATH];
	WCHAR szFileName[MAX_PATH];
	WCHAR* szAppName = L"AppName";
	WCHAR* szVersion = L"v1.0";
	DWORD dwBufferSize = MAX_PATH;
	HANDLE hDumpFile;
	SYSTEMTIME stLocalTime;
	MINIDUMP_EXCEPTION_INFORMATION ExpParam;
	GetLocalTime(&stLocalTime);
	GetTempPath(dwBufferSize, szPath);
	wsprintf(szFileName, L"%s%s", szPath, szAppName);
	CreateDirectory(szFileName, NULL);
	SHGetFolderPath(NULL, CSIDL_APPDATA, NULL, SHGFP_TYPE_CURRENT, szDocPath);
	wsprintf(szFileName,L"%s\\ljdata\\EDEngine\\crash.dump",
		szDocPath);
	hDumpFile = CreateFile(szFileName, GENERIC_READ | GENERIC_WRITE,
		FILE_SHARE_WRITE | FILE_SHARE_READ, 0, CREATE_ALWAYS, 0, 0);

	MINIDUMP_USER_STREAM UserStream[2];
	MINIDUMP_USER_STREAM_INFORMATION UserInfo;
	UserInfo.UserStreamCount = 1;
	UserInfo.UserStreamArray = UserStream;
	UserStream[0].Type = CommentStreamW;
	UserStream[0].BufferSize = lstrlenW(strBuild)*sizeof(WCHAR);
	UserStream[0].Buffer = strBuild;
	UserStream[1].Type = CommentStreamW;
	UserStream[1].BufferSize = lstrlenW(strError)*sizeof(WCHAR);
	UserStream[1].Buffer = strError;

	ExpParam.ThreadId = GetCurrentThreadId();
	ExpParam.ExceptionPointers = pExceptionPointers;
	ExpParam.ClientPointers = TRUE;

	MINIDUMP_TYPE MiniDumpWithDataSegs = (MINIDUMP_TYPE)(MiniDumpNormal
		| MiniDumpWithHandleData
		| MiniDumpWithUnloadedModules
		| MiniDumpWithIndirectlyReferencedMemory
		| MiniDumpScanMemory
		| MiniDumpWithProcessThreadData
		| MiniDumpWithThreadInfo);
	bMiniDumpSuccessful = MiniDumpWriteDump(GetCurrentProcess(), GetCurrentProcessId(),
		hDumpFile, MiniDumpWithDataSegs, &ExpParam, NULL, NULL);
	*/
		return EXCEPTION_CONTINUE_SEARCH; //或者 EXCEPTION_EXECUTE_HANDLER 关闭程序  
}
#elif __ANDROID__
void _makeNativeCrashReport(const char *reason, struct siginfo *siginfo, void *sigcontext) {
	std::string stlog;
	if (unwind_backtrace_signal_arch != NULL && siginfo != NULL)  {
		map_info_t *map_info = acquire_my_map_info_list();
		backtrace_frame_t frames[256] = {0,};
		backtrace_symbol_t symbols[256] = {0,};
		const ssize_t size = unwind_backtrace_signal_arch(siginfo, sigcontext, map_info, frames, 1, 255);
		get_backtrace_symbols(frames,  size, symbols);
		for (int i = 0; i < size; ++i) {
			const char *method = symbols[i].demangled_name;
			if (!method)
				method = symbols[i].symbol_name;
			if (!method)
				method = "?";
			const char *file = symbols[i].map_name;
			if (!file)
				file = "-";
			stlog += method;
			stlog += " : ";
			stlog += file;
			stlog += "\n";
		}
		free_backtrace_symbols(symbols, size);
		release_my_map_info_list(map_info);
	}
	std::string wdir = cocos2d::FileUtils::getInstance()->getWritablePath();
	std::string filename = wdir + "crash.dump";
	FILE *fp = fopen(filename.c_str(),"wb");
	if( fp ){
		if( reason && siginfo )
		{
			char buf[1024];
			sprintf(buf,"ANDROID NATIVE EXCEPTION\nREASON:%s SIGNO:%08X ERRNO:%08X CODE:%08X\n",
				reason,siginfo->si_signo,siginfo->si_errno,siginfo->si_code);
			fwrite(buf,1,strlen(buf),fp);
		}
		fwrite(stlog.c_str(),1,stlog.length(),fp);
		fclose(fp);
	}
	wdir += "crash.log";
	acr_write_log(wdir.c_str());
}

void nativeCrashHandler_sigaction(int signal, struct siginfo *siginfo, void *sigcontext) {

	if (old_sa[signal].sa_handler)
		old_sa[signal].sa_handler(signal);

	_makeNativeCrashReport(strsignal(signal), siginfo, sigcontext);
}
#endif

void initACR()
{
	acr_init_log();
#ifdef WIN32
	SetUnhandledExceptionFilter(MyUnhandledExceptionFilter);
#elif __ANDROID__	
	void * libcorkscrew = dlopen("libcorkscrew.so", RTLD_LAZY | RTLD_LOCAL);
	if (libcorkscrew) {
		unwind_backtrace_signal_arch = (t_unwind_backtrace_signal_arch) dlsym(libcorkscrew, "unwind_backtrace_signal_arch");
		acquire_my_map_info_list = (t_acquire_my_map_info_list) dlsym(libcorkscrew, "acquire_my_map_info_list");
		release_my_map_info_list = (t_release_my_map_info_list) dlsym(libcorkscrew, "release_my_map_info_list");
		get_backtrace_symbols  = (t_get_backtrace_symbols) dlsym(libcorkscrew, "get_backtrace_symbols");
		free_backtrace_symbols = (t_free_backtrace_symbols) dlsym(libcorkscrew, "free_backtrace_symbols");
	}else{
		unwind_backtrace_signal_arch = NULL;
		acquire_my_map_info_list = NULL;
		release_my_map_info_list = NULL;
		get_backtrace_symbols = NULL;
		free_backtrace_symbols = NULL;
	}
	if(unwind_backtrace_signal_arch==NULL)
		__android_log_print(ANDROID_LOG_ERROR, "NativeCrashHandler",
			"Can not load libcorkscrew.so or can not location 'unwind_backtrace_signal_arch'");
			
	struct sigaction handler;
	int result;
	
	memset(&handler, 0, sizeof(handler));
	sigemptyset(&handler.sa_mask);
	handler.sa_sigaction = nativeCrashHandler_sigaction;
	handler.sa_flags = SA_SIGINFO | SA_ONSTACK;

	stack_t stack;
	memset(&stack, 0, sizeof(stack));
	stack.ss_size = 1024 * 128;
	stack.ss_sp = malloc(stack.ss_size);
	Verify(stack.ss_sp, "Could not allocate signal alternative stack");
	stack.ss_flags = 0;
	result = sigaltstack(&stack, NULL);
	Verify(!result, "Could not set signal stack");

	result = sigaction(SIGILL,    &handler, &old_sa[SIGILL]    );
	Verify(!result, "Could not register signal callback for SIGILL");

	result = sigaction(SIGABRT,   &handler, &old_sa[SIGABRT]   );
	Verify(!result, "Could not register signal callback for SIGABRT");

	result = sigaction(SIGBUS,    &handler, &old_sa[SIGBUS]    );
	Verify(!result, "Could not register signal callback for SIGBUS");

	result = sigaction(SIGFPE,    &handler, &old_sa[SIGFPE]    );
	Verify(!result, "Could not register signal callback for SIGFPE");

	result = sigaction(SIGSEGV,   &handler, &old_sa[SIGSEGV]   );
	Verify(!result, "Could not register signal callback for SIGSEGV");

	result = sigaction(SIGSTKFLT, &handler, &old_sa[SIGSTKFLT] );
	Verify(!result, "Could not register signal callback for SIGSTKFLT");

	result = sigaction(SIGPIPE,   &handler, &old_sa[SIGPIPE]   );
	Verify(!result, "Could not register signal callback for SIGPIPE");
#endif
}