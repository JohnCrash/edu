require "Cocos2d"
local crash = require "crash"
local kits = require "kits"
local uikits = require "uikits"
local login = require "login"
local update = require "update"

crash.open("launcher",1)

local local_dir = cc.FileUtils:getInstance():getWritablePath()
local platform = CCApplication:getInstance():getTargetPlatform()

--require("mobdebug").start("192.168.2.182")

local function init_test_resource()
  local pfu = cc.FileUtils:getInstance()
  if platform == kTargetWindows then
		pfu:addSearchPath(local_dir..'src/')
		pfu:addSearchPath(local_dir..'res/')	
		pfu:addSearchPath(local_dir..'cache/')
		pfu:addSearchPath(local_dir)
		pfu:addSearchPath(local_dir..'luacore/')
		--默认资源
		pfu:addSearchPath(local_dir..'luacore/res')
	else --android,ios
		--先搜索跟新目录
		pfu:addSearchPath(local_dir..'src/')
		pfu:addSearchPath(local_dir..'res/')	
		pfu:addSearchPath(local_dir)
		pfu:addSearchPath(local_dir..'luacore/')
		--搜索assets目录
		pfu:addSearchPath('src/')
		pfu:addSearchPath('res/')
		local cache_dir = local_dir..'test/'
		if not kits.directory_exists(cache_dir) then
			kits.make_directory(cache_dir)
		end
		pfu:addSearchPath(cache_dir)
		--默认资源
		pfu:addSearchPath('luacore/res')		
	end
end

init_test_resource()

if uikits.get_factor() == uikits.FACTOR_9_16 then
	uikits.initDR{width=1920,height=1080}
else
	uikits.initDR{width=1440,height=1080}
end

--android 返回键
local function onKeyRelease(key,event)
	if key == cc.KeyCode.KEY_ESCAPE or key == cc.KeyCode.KEY_SPACE then
		local console = require "console"
		local scene = console.create()
		if scene then
			cc.Director:getInstance():pushScene( scene )
		end
		--uikits.popScene()
	end
end
local listener_keyboard = cc.EventListenerKeyboard:create()
listener_keyboard:registerScriptHandler(onKeyRelease,cc.Handler.EVENT_KEYBOARD_RELEASED )	
local directorEventDispatcher = cc.Director:getInstance():getEventDispatcher()
directorEventDispatcher:addEventListenerWithFixedPriority(listener_keyboard,1)

local ae = require "AppEntry"
cc.Director:getInstance():runWithScene( ae.create() )
--[[
local app,cookie = cc_launchparam()
local scene
app = 'homework'

if cookie and type(cookie)=='string' and string.len(cookie)>1 then
	login.set_cookie( cookie )
else
	login.set_selector(1) --学生
end

if app == 'homework' then
	update.create{name=app,updates={'homework','luacore'},
		run=function()
		local worklist = require "homework/worklist"
		return worklist.create()
	end}
elseif app == 'amouse' then
	update.create{name=app,updates={'amouse','luacore'},
		run=function()
		uikits.initDR{width=1024,height=768,mode=cc.ResolutionPolicy.NO_BORDER}
		local amouse = require "amouse/amouse_om"
		return AMouseMain()
	end}		
elseif app == 'teacher' then
	update.create{name=app,updates={'homework','luacore'},
		run=function()
		local teacher = require "homework/teacher"
		return teacher.create()
	end}	
elseif app == 'errortitile' then
	update.create{name=app,updates={'homework','errortitile','luacore'},
		run=function()
		local WrongSubjectList = require "errortitile/WrongSubjectList"
		return WrongSubjectList.create()
	end}
elseif app and string.len(app)>0 then
	--任意启动
	update.create{name=app,updates={app,'luacore'},
		run=function()
			local a = require(app)
			return a.create()
		end}
else
	update.create{name=app,updates={'homework','luacore'},
		run=function()
		local worklist = require "homework/worklist"
		return worklist.create()
	end}
end
--]]
