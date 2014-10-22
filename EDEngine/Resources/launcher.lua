require "Cocos2d"
require "ljshellDeprecated"
local crash = require "crash"
local kits = require "kits"
local uikits = require "uikits"
local login = require "login"
local update = require "update"
local resume = require "resume"

crash.open("launcher",1)

uikits.muteSound( kits.config("mute","get") )

local local_dir = kits.get_local_directory()
local platform = CCApplication:getInstance():getTargetPlatform()

--require("mobdebug").start("192.168.2.182")
local cache_dir = kits.get_cache_path()
if not kits.directory_exists(cache_dir) then
	kits.make_directory(cache_dir)
end
		
local function init_test_resource()
  local pfu = cc.FileUtils:getInstance()
  if platform == kTargetWindows then
		pfu:addSearchPath(local_dir..'src/')
		pfu:addSearchPath(local_dir..'res/')	

		local cache_dir = kits.get_cache_path()
		if not kits.directory_exists(cache_dir) then
			kits.make_directory(cache_dir)
		end
		pfu:addSearchPath(cache_dir)

		pfu:addSearchPath(local_dir)
		pfu:addSearchPath(local_dir..'luacore/')
		--默认资源
		pfu:addSearchPath('luacore/res')
	else --android,ios
		--先搜索跟新目录
		pfu:addSearchPath(local_dir..'src/')
		pfu:addSearchPath(local_dir..'res/')	
		pfu:addSearchPath(local_dir)
		pfu:addSearchPath(local_dir..'luacore/')
		pfu:addSearchPath(local_dir..'res/luacore')
		--搜索assets目录
		pfu:addSearchPath('src/')
		pfu:addSearchPath('res/')
		local cache_dir = kits.get_cache_path()
		if not kits.directory_exists(cache_dir) then
			kits.make_directory(cache_dir)
		end
		pfu:addSearchPath(cache_dir)
		--默认资源
		pfu:addSearchPath('luacore/res')
	end
end

--init_test_resource()

if uikits.get_factor() == uikits.FACTOR_9_16 then
	uikits.initDR{width=1920,height=1080}
else
	uikits.initDR{width=1440,height=1080}
end

local mode
--android 返回键
local function onKeyRelease(key,event)
	if key == cc.KeyCode.KEY_ESCAPE or key == cc.KeyCode.KEY_SPACE then
		if mode==2 then
			local console = require "console"
			if console.isopen() then
				cc.Director:getInstance():popScene()
			else
				local scene = console.create()
				if scene then
					cc.Director:getInstance():pushScene( scene )
				end
			end
		else
			uikits.popScene()
		end
	end
end

local listener_keyboard = cc.EventListenerKeyboard:create()
listener_keyboard:registerScriptHandler(onKeyRelease,cc.Handler.EVENT_KEYBOARD_RELEASED )	
local directorEventDispatcher = cc.Director:getInstance():getEventDispatcher()
directorEventDispatcher:addEventListenerWithFixedPriority(listener_keyboard,1)

local app,cookie,uid = cc_launchparam()
local scene

if cookie and type(cookie)=='string' and string.len(cookie)>1 then
	login.set_cookie( cookie )
else
	login.set_selector(1) --学生
end
if uid and type(uid)=='string' and string.len(uid)>1 then
	login.set_userid( uid )
end

resume.clearflag("launcher") --launcher isok
if app == 'studenthw' then
	update.create{name=app,updates={'homework','luacore','errortitile'},
		run=function()
		local worklist = require "homework/worklist"
		return worklist.create()
	end}
elseif  app == 'studenthw2' then
	update.create{name=app,updates={'homework','luacore','errortitile'},
		run=function()
		local selstudent = require "homework/selstudent"
		return selstudent.create()
	end}
elseif app == 'amouse' then
	update.create{name=app,updates={'amouse','luacore'},
		run=function()
		uikits.initDR{width=1024,height=768,mode=cc.ResolutionPolicy.NO_BORDER}
		local amouse = require "amouse/amouse_om"
		return AMouseMain()
	end}		
elseif app == 'teacherhw' then
	update.create{name=app,updates={'homework','errortitile','luacore'},
		run=function()
		local teacher = require "homework/teacher"
		return teacher.create()
	end}	
elseif app == 'exerbook' then
	update.create{name=app,updates={'homework','errortitile','luacore'},
		run=function()
		local WrongSubjectList = require "errortitile/WrongSubjectList"
		return WrongSubjectList.create()
	end}
elseif app == 'exerbook2' then
	update.create{name=app,updates={'homework','errortitile','luacore'},
		run=function()
		local WrongLoading = require "errortitile/Loading"
		return WrongLoading.create()
	end}	
elseif app and string.len(app)>0 then
	--任意启动
	update.create{name=app,updates={app,'luacore'},
		run=function()
			local a = require(app)
			return a.create()
		end}
else
	local ae = require "AppEntry"
	mode = 2
	cc.Director:getInstance():runWithScene( ae.create() )
end

