require "Cocos2d"
require "ljshellDeprecated"
local crash = require "crash"
local kits = require "kits"
local uikits = require "uikits"
local login = require "login"
local update = require "update"
local resume = require "resume"
local cache = require "cache"
local json = require "json-c"

crash.open("launcher",1)

uikits.muteSound( kits.config("mute","get") )
cache.clear() --清除缓冲

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

function enableDebug( b )
	if b then
		kits.log("enable debug")
		mode = 2
	else
		kits.log("disable debug")
		mode = 0
	end
end
enableDebug( kits.config("debug","get") )
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
	kits.config("cookie",cookie)
else
	--[[
	local ck = kits.config("cookie","get")
	if ck then
		login.set_cookie( ck ) --上一次成功的启动
	else
		login.set_selector(1) --学生
	end
	--]]
	login.set_cookie('')
	app = 'exerbooknew'
end
if uid and type(uid)=='string' and string.len(uid)>1 then
	login.set_userid( uid )
	kits.config("uid",uid)
else
	--[[
	local id = kits.config("uid","get")
	if id then
		login.set_userid( id )
	end
	--]]
end

resume.clearflag("launcher") --launcher isok
if app == 'studenthw' then
	update.create{name=app,updates={'homework','luacore','errortitile'},
		run=function()
		login.set_uid_type(login.STUDENT)
		local worklist = require "homework/worklist"
		return worklist.create()
	end}
elseif  app == 'studenthw2' then
	update.create{name=app,updates={'homework','luacore','errortitile'},
		run=function()
		login.set_uid_type(login.PARENT)
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
		login.set_uid_type(login.TEACHER)
		local teacher = require "homework/teacher"
		return teacher.create()
	end}	
elseif app == 'exerbook' then
	update.create{name=app,updates={'homework','errortitile','luacore'},
		run=function()
		login.set_uid_type(login.STUDENT)
		user_status = 1	
		cur_child_id = 0
		local WrongSubjectList = require "errortitile/WrongSubjectList"
		return WrongSubjectList.create()
	end}
elseif app == 'exerbook2' then
	update.create{name=app,updates={'homework','errortitile','luacore'},
		run=function()
		login.set_uid_type(login.PARENT)
		user_status = 1	
		cur_child_id = 0
		local WrongLoading = require "errortitile/Loading"
		return WrongLoading.create()
	end}	
elseif app == 'suggestion' then
	update.create{name=app,updates={'suggestion','homework','errortitile','luacore'},
		run=function()
			local suggestion = require "suggestion/SuggestionView.lua"
			return suggestion.create()
	end}	
elseif app == 'exerbooknew' then
	--如果网络上的版本小于等于系统自带的版本号就直接执行系统自带版本
	local versionNUM = resume.getversion()
	local liexue_server = 'http://file.lejiaolexue.com/upgrade/luaapp/v'..versionNUM..'/'	
	local et_url = liexue_server..'src/errortitlenew/version.json'
	local ver_str = kits.http_get(et_url,'',2)
	local function launch_default_errortitle()
		kits.log("launch default errortitle")
		local exerbooknew = require "errortitlenew/Loading"
		kits.log("COOKIE="..cookie)
		if exerbooknew then
			cc.Director:getInstance():runWithScene(
			exerbooknew.create() )
		else
			kits.log("require errortitlenew/Loading error")
			return
		end
	end
	if ver_str then
		local ver = json.decode(ver_str)
		if ver and type(ver)=='table' and ver.version then
			kits.log("server errortitle version :"..ver.version)
			if ver.version <= 100 then
				return launch_default_errortitle()
			end
		else
			kits.log("errortitle version.json decode error")
			return launch_default_errortitle()
		end
	else
		kits.log("can't request errortitlte version.json "..et_url)
		return launch_default_errortitle()
	end
	--网络正确并且版本大于默认版本启动更新程序
	kits.log("launch update errortitle")
	update.create{name=app,updates={'errortitlenew','luacore'},
		run=function()
			local exerbooknew = require "errortitlenew/Loading"
			return exerbooknew.create()
	end}	
elseif app and string.len(app)>0 then
	update.create{name=app.."_shell",updates={"luacore"},
		run = function()
			local s = kits.read_local_file("res/luacore/app.json")
			if s then
				local apps = json.decode( s )
				if apps and apps[app] and apps[app].name and apps[app].updates and apps[app].launch then
					update.create{name=apps[app].name,updates=apps[app].updates,
						run=function()
							local a = require(apps[app].launch)
							return a.create()
						end}			
				else
					kits.log("ERROR : can not found applet : "..tostring(app))
				end
			else
				kits.log("ERROR : can not read res/luacore/app.json")
			end
		end
	}
else
	local ae = require "AppEntry"
	mode = 2
	cc.Director:getInstance():runWithScene( ae.create() )
end
