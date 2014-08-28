require "Cocos2d"
local kits = require "kits"
local uikits = require "uikits"
local login = require "login"
local update = require "update"

local local_dir = cc.FileUtils:getInstance():getWritablePath()
local platform = CCApplication:getInstance():getTargetPlatform()
require("mobdebug").start("192.168.2.182")
local function init_test_resource()
  local pfu = cc.FileUtils:getInstance()
  if platform == kTargetWindows then
		pfu:addSearchPath(local_dir..'src/')
		pfu:addSearchPath(local_dir..'res/')	
		pfu:addSearchPath(local_dir..'cache/')
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
		--搜索assets目录
		pfu:addSearchPath('src/')
		pfu:addSearchPath('res/')
		local cache_dir = local_dir..'test/'
		if not kits.directory_exists(cache_dir) then
			kits.make_directory(cache_dir)
		end
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
	
local app,cookie = cc_launchparam()
local scene
app = 'loading'

if cookie and type(cookie)=='string' and string.len(cookie)>1 then
	
	login.set_cookie( cookie )
else
	login.set_selector(1) --学生
end

if app == 'homework' then
	update.create{updates={'homework'},
		run=function()
		local worklist = require "homework/worklist"
		return worklist.create()
	end}
elseif app == 'amouse' then
	update.create{updates={'amouse'},
		run=function()
		uikits.initDR{width=1024,height=768,mode=cc.ResolutionPolicy.NO_BORDER}
		local amouse = require "amouse/amouse_om"
		return AMouseMain()
	end}		
elseif app == 'teacher' then
	update.create{updates={'homework'},
		run=function()
		local teacher = require "homework/teacher"
		return teacher.create()
	end}	
elseif app == 'errortitile' then
	update.create{updates={'homework','errortitile'},
		run=function()
		local WrongSubjectList = require "errortitile/WrongSubjectList"
		return WrongSubjectList.create()
	end}		
elseif app == 'loading' then
	local update = require "update"
	scene = update.create{updates={'homework','amouse','errortitle'},
		run=function()
			local worklist = require "homework/worklist"
			return worklist.create()		
		end}
else
	update.create{updates={'homework'},
		run=function()
		local worklist = require "homework/worklist"
		return worklist.create()
	end}
end

