#include "AppDelegate.h"
#include "HelloWorldScene.h"
#include "lua_ext.h"
#include "lua_ljshell.h"
#include "luaDebug.h"

#if CC_TARGET_PLATFORM == CC_PLATFORM_WIN32
#include "win32/glfw3native.h"
#include "CommCtrl.h"
#endif

#if CC_TARGET_PLATFORM == CC_PLATFORM_MAC||CC_TARGET_PLATFORM == CC_PLATFORM_IOS
#include "AppleBundle.h"
#endif

#ifdef __ANDROID__
#undef _DEBUG
#endif
MySpaceBegin
#if CC_TARGET_PLATFORM == CC_PLATFORM_WIN32
#include <string>
extern bool g_Reset;
extern int g_FrameWidth;
extern int g_FrameHeight;
extern std::string g_Orientation;
extern std::wstring utf8ToUnicode(const std::string& s);
extern std::wstring toUnicode(const std::string& s);

HWND g_hMainWnd = NULL;
COLORREF g_frameColor = RGB(2, 137, 130);
COLORREF g_titleColor = RGB(255, 255, 255);

std::string toUTF8( const std::wstring& wstr )
{
	std::string str;
	int len = WideCharToMultiByte(CP_UTF8,0,wstr.c_str(),-1,NULL,NULL,NULL,NULL); 
	if( len == 0 )
	{
		return "";
	}
	str.resize( len );
	len = WideCharToMultiByte(CP_UTF8,0,wstr.c_str(),-1,&str[0],str.size(),NULL,NULL);
	if( str.back()==0 )
		str.pop_back();
	return str;
}
#endif
AppDelegate_v3::AppDelegate_v3()
{

}

AppDelegate_v3::~AppDelegate_v3()
{
	//releaseInternalLuaEngine();
}

extern std::string g_Mode;
#if CC_TARGET_PLATFORM == CC_PLATFORM_WIN32
/*
* 定义一个新的窗口过程
*/
static void ToggleGlass(HWND hwnd) {
	SetWindowPos(hwnd, NULL, 0, 0, 0, 0,
		SWP_NOSIZE | SWP_NOMOVE | SWP_NOZORDER | SWP_FRAMECHANGED);
	RedrawWindow(hwnd, NULL, NULL, RDW_INVALIDATE | RDW_UPDATENOW);
}

static void GetNCInfo(HWND hwnd, int *pbroderWidth, int *ptitleHeight, 
	LPRECT pcr, LPRECT pwr,LPRECT icon,LPRECT minb,LPRECT closeb)
{
	GetWindowRect(hwnd, pwr);
	GetClientRect(hwnd, pcr);
	
	pwr->right = abs(pwr->right - pwr->left);
	pwr->left = 0;
	pwr->bottom = abs(pwr->bottom - pwr->top);
	pwr->top = 0;

	*pbroderWidth = (abs(pwr->right - pwr->left) - abs(pcr->right - pcr->left)) / 2;
	*ptitleHeight = abs(pwr->bottom - pwr->top) - abs(pcr->bottom - pcr->top) - *pbroderWidth;

	icon->left = 0;
	icon->top = 0;
	icon->right = *ptitleHeight;
	icon->bottom = *ptitleHeight;

	closeb->top = 0;
	closeb->right = abs( pwr->right-pwr->left);
	closeb->left = closeb->right-*ptitleHeight;
	closeb->bottom = *ptitleHeight;

	minb->top = 0;
	minb->right = abs(pwr->right - pwr->left) - *ptitleHeight;
	minb->left = minb->right - *ptitleHeight;
	minb->bottom = *ptitleHeight;

	pcr->left += *pbroderWidth;
	pcr->right += *pbroderWidth;
	pcr->top += *ptitleHeight;
	pcr->bottom += *ptitleHeight;
}
#define BUTTON_MIN 1
#define BUTTON_CLOSE 2
#define BORDER_WIDTH 6
static int g_cursorToButton = 0;

static void DrawButton(HDC hdc, LPRECT prc,int type)
{
	if (type == g_cursorToButton){
		COLORREF color = RGB(GetRValue(g_frameColor) / 2, GetGValue(g_frameColor) / 2, GetBValue(g_frameColor) / 2);
		HBRUSH br = CreateSolidBrush(color);
		FillRect(hdc, prc, br);
		DeleteObject(br);
	}
	if (type == BUTTON_MIN){
		HBRUSH br = CreateSolidBrush(g_titleColor);
		RECT rc = *prc;
		rc.left += BORDER_WIDTH;
		rc.right -= BORDER_WIDTH;
		rc.bottom -= BORDER_WIDTH;
		rc.top = rc.bottom - 3;
		FillRect(hdc, &rc,br);
		DeleteObject(br);
	}
	else if (type == BUTTON_CLOSE){
		HPEN pen = CreatePen(PS_SOLID, 2, g_titleColor);
		HGDIOBJ op = SelectObject(hdc, pen);
		MoveToEx(hdc, prc->left + BORDER_WIDTH, prc->top + BORDER_WIDTH,NULL);
		LineTo(hdc, prc->right - BORDER_WIDTH, prc->bottom - BORDER_WIDTH);
		MoveToEx(hdc, prc->left + BORDER_WIDTH, prc->bottom - BORDER_WIDTH, NULL);
		LineTo(hdc, prc->right - BORDER_WIDTH, prc->top + BORDER_WIDTH);
		SelectObject(hdc, op);
	}
}

static void InvalidateButton(HWND hwnd,int type, LPRECT minb, LPRECT closeb)
{
	if (g_cursorToButton != type){
		g_cursorToButton = type;
		RECT rc;
		rc.left = minb->left - BORDER_WIDTH;
		rc.right = closeb->right;
		rc.top = -minb->bottom;
		rc.bottom = 0;
		RedrawWindow(hwnd, &rc, NULL, RDW_INVALIDATE | RDW_UPDATENOW | RDW_FRAME);
	}
}

static WNDPROC g_DefWndProc = NULL;
static TRACKMOUSEEVENT g_TrackMouseEvent;
static void MouseHover(HWND hwnd)
{
	g_TrackMouseEvent.cbSize = sizeof(g_TrackMouseEvent);
	g_TrackMouseEvent.dwFlags = TME_HOVER | TME_NONCLIENT | TME_LEAVE;
	g_TrackMouseEvent.hwndTrack = hwnd;
	g_TrackMouseEvent.dwHoverTime = HOVER_DEFAULT;
	_TrackMouseEvent(&g_TrackMouseEvent);
}

static LRESULT DefualtProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	if (g_DefWndProc){
		return g_DefWndProc(hwnd, uMsg, wParam, lParam);
	}
	else{
		return DefWindowProc(hwnd, uMsg, wParam, lParam);
	}
}

LRESULT CALLBACK myWindowProcHook(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	switch (uMsg)
	{
	case WM_NCPAINT:
	{
		TCHAR txt[256];
		RECT cr, icon, minb, closeb,wr, dirty, dirty_box;
		SIZE size;
		int len = GetWindowText(hwnd, txt, 255);
		int x, y, broderWidth, titleHeight;

		GetNCInfo(hwnd, &broderWidth, &titleHeight, &cr, &wr, &icon, &minb, &closeb);
		/*
		GetWindowRect(hwnd, &wr);
		if (!wParam || wParam == 1) {
			dirty = wr;
			dirty.left = dirty.top = 0;
		}
		else {
			GetRgnBox(reinterpret_cast<HRGN>(wParam), &dirty_box);
			if (!IntersectRect(&dirty, &dirty_box, &wr))
				return 0;
			OffsetRect(&dirty, -wr.left, -wr.top);
		}
		*/
		HDC hdc = GetWindowDC(hwnd);
		/*
		 * 绘制背景
		 */
		HBRUSH br = CreateSolidBrush(g_frameColor);
		{
			RECT rc;
			rc = wr;
			rc.bottom = titleHeight;
			FillRect(hdc, &rc, br);
			rc.top = wr.bottom - broderWidth;
			rc.bottom = wr.bottom;
			FillRect(hdc, &rc, br);

			rc.right = wr.left + broderWidth;
			rc.top = wr.top + titleHeight;
			rc.bottom = wr.bottom - broderWidth;
			FillRect(hdc, &rc, br);

			rc.left = wr.right - broderWidth;
			rc.right = wr.right;
			FillRect(hdc, &rc, br);
		}
		DeleteObject(br);
		
		/* 
		 * 绘制标题
		 */
		GetTextExtentPoint32(hdc, txt, len, &size);
		x = (abs(wr.right - wr.left)-size.cx)/2;
		y = (titleHeight - size.cy) / 2;
		SetTextColor(hdc, g_titleColor);
		SetBkColor(hdc, g_frameColor);
		HGDIOBJ hfont = GetStockObject(SYSTEM_FIXED_FONT);
		HGDIOBJ of = SelectObject(hdc,hfont);
		TextOut(hdc, x, y, txt, len);
		SelectObject(hdc, of);
		/*
		 * 绘制图标
		 */
		//HICON hicon = (HICON)GetClassLongPtr(hwnd, GCLP_HICON);
		//DrawIconEx(hdc, 0, 0, hicon, icon.right - icon.left, icon.bottom - icon.top, 0, NULL, DI_IMAGE | DI_MASK);
		/*
		 * 绘制最小化按钮和关闭按钮
		 */
		br = CreateSolidBrush(g_titleColor);
		DrawButton(hdc, &minb,BUTTON_MIN);
		DrawButton(hdc, &closeb,BUTTON_CLOSE);
		DeleteObject(br);
		ReleaseDC(hwnd, hdc);
	}
		break;
	case WM_NCHITTEST:
		{
			POINT pt;
			int broderWidth, titleHeight;
			pt.x = (int)(short)LOWORD(lParam);
			pt.y = (int)(short)HIWORD(lParam);
			RECT cr, wr, icon, minb, closeb;
			GetNCInfo(hwnd, &broderWidth, &titleHeight, &cr, &wr, &icon, &minb, &closeb);
			ScreenToClient(hwnd, &pt);
			pt.y += titleHeight;

			if (PtInRect(&minb, pt)) //点击到最小化
			{
				InvalidateButton(hwnd,BUTTON_MIN, &minb,&closeb);
				MouseHover(hwnd);
			}
			else if (PtInRect(&closeb, pt)) //点击到最关闭
			{
				InvalidateButton(hwnd,BUTTON_CLOSE, &minb, &closeb);
				MouseHover(hwnd);
			}
			else
			{
				InvalidateButton(hwnd,0, &minb, &closeb);
			}
			return DefualtProc(hwnd, uMsg, wParam, lParam);
		}
		break;
	case WM_NCLBUTTONDOWN:
		{
			POINT pt;
			int broderWidth, titleHeight;
			pt.x = (int)(short)LOWORD(lParam);
			pt.y = (int)(short)HIWORD(lParam);
			RECT cr, wr, icon, minb, closeb;
			GetNCInfo(hwnd, &broderWidth, &titleHeight, &cr, &wr, &icon, &minb, &closeb);
			ScreenToClient(hwnd, &pt);
			pt.y += titleHeight;
			if (PtInRect(&minb, pt)) //点击到最小化
			{
				CloseWindow(hwnd);
			}
			else if (PtInRect(&closeb, pt)) //点击到最关闭
			{
				DestroyWindow(hwnd);
				PostQuitMessage(0);
			}
			else if (PtInRect(&icon, pt)) //图标
			{
				HMENU hmenu = GetSystemMenu(hwnd,TRUE);
				TrackPopupMenu(hmenu, TPM_LEFTALIGN | TPM_TOPALIGN | TPM_LEFTBUTTON, pt.x, pt.y, 0, hwnd, NULL);
				PostMessage(hwnd, WM_NULL, 0, 0);
			}
			else
			{
				return DefualtProc(hwnd, uMsg, wParam, lParam);
			}
		}
		break;
	case WM_NCMOUSEHOVER:
		MouseHover(hwnd);
		break;
	case WM_NCMOUSELEAVE:{
		   RECT cr, wr, icon, minb, closeb;
		   int broderWidth, titleHeight;
		   GetNCInfo(hwnd, &broderWidth, &titleHeight, &cr, &wr, &icon, &minb, &closeb);
		   InvalidateButton(hwnd, 0, &minb, &closeb);
		}
		break;
	case WM_NCACTIVATE:
		RedrawWindow(hwnd, NULL, NULL,RDW_UPDATENOW);
		break;
	default:
		return DefualtProc(hwnd, uMsg, wParam, lParam);
	}
	return 0;
}
#endif

bool AppDelegate_v3::applicationDidFinishLaunching()
{
    // initialize director
    auto director = Director::getInstance();
    auto glview = director->getOpenGLView();
    if(!glview) {
#if CC_TARGET_PLATFORM == CC_PLATFORM_WIN32
	g_Reset = false;
#ifndef _DEBUG
		if( g_Mode == "fullscreen" )
			glview = GLView::createWithFullScreen(toUTF8(TEXT("乐教乐学")));
		else if( g_Mode == "window" )
			glview = GLView::create(toUTF8(TEXT("乐教乐学")));
		else
			glview = GLView::createWithFullScreen(toUTF8(TEXT("乐教乐学")));
#else
		glview = GLView::create(toUTF8(TEXT("乐教乐学")));
#endif
#else
		glview = GLView::create("EDEngine");
#endif

#if CC_TARGET_PLATFORM == CC_PLATFORM_WIN32
		/*
		*调整窗口类型
		*/
		g_hMainWnd = glfwGetWin32Window(glview->getWindow());
		//LONG ws = GetWindowLong(g_hMainWnd, GWL_STYLE);
		SetWindowLong(g_hMainWnd, GWL_STYLE, WS_DLGFRAME | WS_CAPTION | WS_BORDER);
		SetWindowPos(g_hMainWnd, HWND_TOP, 0, 0, 0, 0, SWP_NOSIZE |SWP_NOMOVE| SWP_HIDEWINDOW);
		g_DefWndProc = (WNDPROC)GetWindowLongPtr(g_hMainWnd, GWLP_WNDPROC);
		SetWindowLongPtr(g_hMainWnd, GWLP_WNDPROC, (LONG_PTR)myWindowProcHook);
		//ToggleGlass(g_hMainWnd);
#endif

        director->setOpenGLView(glview);
    }

#ifdef USE_WIN32_CONSOLE
    // turn on display FPS
    director->setDisplayStats(true);
#endif
    // set FPS. the default value is 1.0/60 if you don't call this
    director->setAnimationInterval(1.0 / 60);
	
#ifdef USE_WIN32_CONSOLE
	registerHotkey();
#endif

	initLuaEngine();

    return true;
}

void AppDelegate_v3::initLuaEngine()
{
	auto director = Director::getInstance();
	auto glview = director->getOpenGLView();

#if  (CC_TARGET_PLATFORM == CC_PLATFORM_WIN32)
	if (g_hFileMap)
	{
		PAPPFILEMAPINFO pInfo = (PAPPFILEMAPINFO)MapViewOfFile(g_hFileMap, FILE_MAP_ALL_ACCESS, 0, 0, 0);
		pInfo->size = sizeof(APPFILEMAPINFO);
		pInfo->hwnd = g_hMainWnd;
		UnmapViewOfFile(pInfo);
	}
	else
	{
		g_hMainWnd = NULL;
		CCLOG("ERROR g_hMainWnd = NULL");
	}
#endif

#if CC_TARGET_PLATFORM == CC_PLATFORM_WIN32	|| CC_TARGET_PLATFORM == CC_PLATFORM_MAC
    //window release
	if(g_Mode=="window")
	{
		int w, h;
		RECT rect;
		HWND hwnd = GetDesktopWindow();
		GetClientRect(hwnd, &rect);
		/*
		 * 这里根据启动方向来确定宽高
		 * 如果g_Orientation=="landscape"横屏，g_Orientation=="portrait"竖屏
		 */
		if(g_Orientation!="portrait")
		{
			/*
			 * 横屏模式，使用以前的代码
			 */
			if( g_FrameWidth <=0 && g_FrameHeight <= 0 )
			{
				int borderHeight = 72;//GetSystemMetrics(SM_CYBORDER);
				int width;
#ifdef _DEBUG
				width = 1024;
#else
				width = rect.right - rect.left - 2 * borderHeight;
#endif
				int height;
				float v = (rect.bottom-rect.top)/(rect.right-rect.left);
				w = width;
				if( abs(v -9/16) > abs(v-3/4) )
				{
					glview->setFrameSize(width,width*3/4);
					h = width * 3 / 4;
				}
				else
				{
					glview->setFrameSize(width,width*9/16);
					h = width * 9 / 16;
				}
			}
			else
			{
				glview->setFrameSize(g_FrameWidth,g_FrameHeight);
				w = g_FrameWidth;
				h = g_FrameHeight;
			}
		}else{
			/*
			 * 竖屏模式
			 */
			if( g_FrameWidth <=0 && g_FrameHeight <= 0 )
			{
				int borderHeight = 72;//GetSystemMetrics(SM_CYBORDER);
				h = abs(rect.bottom - rect.top) - borderHeight;
				w = (h * 3) / 4;
				glview->setFrameSize( w, h);
			}
			else
			{
				glview->setFrameSize(g_FrameWidth, g_FrameHeight);
				w = g_FrameWidth;
				h = g_FrameHeight;
			}
		}
		if (g_hMainWnd && hwnd )
		{ //居中放置
			int x,y;
			x = (abs(rect.right-rect.left)-w)/2;
			y = 0;//(abs(rect.bottom-rect.top)-h)/2;
			SetWindowPos(g_hMainWnd, HWND_TOP, x, y, 0, 0, SWP_NOSIZE | SWP_SHOWWINDOW);
			ToggleGlass(g_hMainWnd);
		}
	}
#if CC_TARGET_PLATFORM == CC_PLATFORM_MAC
    //Mac
    if (g_Mode == "window")
    {
        glview->setFrameSize(1024, 576);
    }
    else
        glview->setFrameSize(1024, 576);
#endif
	//glview->setFrameSize(1920,1080);
#endif	
    auto screenSize = glview->getFrameSize();
    
	auto pFileUtils = FileUtils::getInstance();

#if CC_TARGET_PLATFORM == CC_PLATFORM_WIN32
	InitForDebugMode();
#endif

#if CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID
	Director::getInstance()->getConsole()->listenOnTCP(5678);
#endif
    //auto designSize = Size(480, 320);
	//auto designSize = Size(960, 640);
    auto designSize = Size(1024,768);
	// auto designSize = Size(1024, 576);

    if (screenSize.height > 320)
    {
//        auto resourceSize = Size(960, 640); //4:3
		auto resourceSize = Size(1024, 768); 
        std::vector<std::string> searchPaths;

        director->setContentScaleFactor(resourceSize.height/designSize.height);
    }
    
    glview->setDesignResolutionSize(designSize.width, designSize.height, ResolutionPolicy::NO_BORDER);

#ifndef _DEBUG
	//Rlease version
	InitEngineDirectory();
#if CC_TARGET_PLATFORM != CC_PLATFORM_WIN32
	std::string wpath = getLjShellDirectory(App_DIRECTORY);
#else
	std::string path = getLjShellDirectory(App_DIRECTORY);
	std::wstring unicpath = toUnicode(path);
	std::string wpath = toUTF8(unicpath);
#endif
	pFileUtils->addSearchPath(wpath+"src/luacore",true);
	pFileUtils->addSearchPath(wpath+"res/luacore",true);
	pFileUtils->addSearchPath(wpath+"src");
	pFileUtils->addSearchPath(wpath+"res");
	pFileUtils->addSearchPath(wpath+"cache");
	pFileUtils->addSearchPath(wpath);
#if CC_TARGET_PLATFORM == CC_PLATFORM_WIN32
	std::string exe = getExeDir();
	pFileUtils->addSearchPath(exe);
	pFileUtils->addSearchPath(exe+"luacore");
	pFileUtils->addSearchPath(exe+"luacore/res");
	pFileUtils->addSearchPath(exe+"src");
    pFileUtils->addSearchPath(exe+"res");	
#else
	pFileUtils->addSearchPath("luacore");
	pFileUtils->addSearchPath("luacore/res");
	pFileUtils->addSearchPath("src");
    pFileUtils->addSearchPath("res");
#endif
#else //_DEBUG
#ifdef _PROGRAMFILES_DEBUG_
	InitEngineDirectory();
	std::string path = getLjShellDirectory(App_DIRECTORY);
	std::wstring unicpath = toUnicode(path);
	std::string wpath = toUTF8(unicpath);

	pFileUtils->addSearchPath(wpath + "src/luacore", true);
	pFileUtils->addSearchPath(wpath + "res/luacore", true);
	pFileUtils->addSearchPath(wpath + "src");
	pFileUtils->addSearchPath(wpath + "res");
	pFileUtils->addSearchPath(wpath + "cache");
	pFileUtils->addSearchPath(wpath);
	std::string exe = getExeDir();
	pFileUtils->addSearchPath(exe);
	pFileUtils->addSearchPath(exe + "luacore");
	pFileUtils->addSearchPath(exe + "luacore/res");
	pFileUtils->addSearchPath(exe + "src");
	pFileUtils->addSearchPath(exe + "res");
#else
	//_DEBUG
	InitEngineDirectory();
	std::string path = getLjShellDirectory(App_DIRECTORY);
	std::wstring unicpath = toUnicode(path);
	std::string wpath = toUTF8(unicpath);
	pFileUtils->addSearchPath(wpath + "cache");
	pFileUtils->addSearchPath(wpath);
	std::string exe = getExeDir();
	pFileUtils->addSearchPath(exe);
	pFileUtils->addSearchPath(exe+"luacore");
	pFileUtils->addSearchPath(exe+"luacore/res");
	pFileUtils->addSearchPath(exe+"src");
    pFileUtils->addSearchPath(exe+"res");
#endif
#endif
    
    auto pEngine = LuaEngine::getInstance();
	auto L = pEngine->getLuaStack()->getLuaState();
	luaopen_lua_exts(L);
	luaopen_lua_ljshell(L);
    ScriptEngineManager::getInstance()->setScriptEngine(pEngine);
	LuaStack* stack = pEngine->getLuaStack();
    //pEngine->executeScriptFile("bootstrap.lua");
	pEngine->executeScriptFile("resume.lua");
	pEngine->executeScriptFile("crash.lua");
	pEngine->executeScriptFile("launcher.lua");
}

#if CC_TARGET_PLATFORM == CC_PLATFORM_WIN32
std::string AppDelegate_v3::getExeDir()
{
	TCHAR cur[256];
	GetModuleFileName(GetModuleHandle(NULL),cur,256);
	std::string exe = toUTF8( cur );
	std::string::size_type pos = exe.find_last_of('\\');
	if( pos != std::string::npos )
	{
		return exe.substr(0,pos+1);
	}
	else
		return exe;
}

void AppDelegate_v3::InitForDebugMode()
{
	TCHAR cur[256];

	GetModuleFileName(GetModuleHandle(NULL),cur,256);
	std::wstring path(cur);
	size_t p = path.rfind('\\');
	if( p !=std::wstring::npos )
	{
		std::wstring wp = path.substr(0,p);
		wp += TEXT("\\luacore");
		SetCurrentDirectory( wp.c_str() );
	}
}

#endif

void AppDelegate_v3::registerHotkey()
{
	auto director = Director::getInstance();
	auto pDispatcher = director->getEventDispatcher();
	//ped->addEventListenerWithFixedPriority(this,0);
	auto listener = EventListenerKeyboard::create();
	listener->onKeyPressed = CC_CALLBACK_2(AppDelegate_v3::onKeyPressed,this);
	listener->onKeyReleased = CC_CALLBACK_2(AppDelegate_v3::onKeyReleased,this);
	pDispatcher->addEventListenerWithFixedPriority(listener,1);
}

void AppDelegate_v3::onKeyPressed(cocos2d::EventKeyboard::KeyCode code,cocos2d::Event *pEvent)
{
#ifdef USE_WIN32_CONSOLE
	if(code==EventKeyboard::KeyCode::KEY_F9) //reset
	{
		auto director = Director::getInstance();
		director->end();
	}
	else if(code==EventKeyboard::KeyCode::KEY_F12) //quit
	{
		auto director = Director::getInstance();
		g_Quit = false;
		director->end();
	}
#endif
}

void AppDelegate_v3::onKeyReleased(cocos2d::EventKeyboard::KeyCode code,cocos2d::Event *pEvent)
{
}

// This function will be called when the app is inactive. When comes a phone call,it's be invoked too
void AppDelegate_v3::applicationDidEnterBackground() {
    Director::getInstance()->stopAnimation();

    // if you use SimpleAudioEngine, it must be pause
#ifdef __APPLE__
    CocosDenshion3::SimpleAudioEngine::getInstance()->pauseBackgroundMusic();
#else
	CocosDenshion::SimpleAudioEngine::getInstance()->pauseBackgroundMusic();
#endif
}

// this function will be called when the app is active again
void AppDelegate_v3::applicationWillEnterForeground() {
    Director::getInstance()->startAnimation();

    // if you use SimpleAudioEngine, it must resume here
#ifdef __APPLE__
    CocosDenshion3::SimpleAudioEngine::getInstance()->resumeBackgroundMusic();
#else
	CocosDenshion::SimpleAudioEngine::getInstance()->resumeBackgroundMusic();
#endif
}

MySpaceEnd
