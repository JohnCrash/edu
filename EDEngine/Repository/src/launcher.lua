require "Cocos2d"
local kits = require "kits"
local uikits = require "uikits"
local login = require "login"

local local_dir = cc.FileUtils:getInstance():getWritablePath()
local platform = CCApplication:getInstance():getTargetPlatform()
--require("mobdebug").start("192.168.2.182")
local function init_test_resource()
  local res = local_dir..'res/'
  local pfu = cc.FileUtils:getInstance()
  local size = cc.Director:getInstance():getVisibleSize()

	if platform == kTargetWindows then
		pfu:addSearchPath(local_dir..'src/')
		pfu:addSearchPath(local_dir..'res/')	
		pfu:addSearchPath(local_dir..'cache/')
	else
		pfu:addSearchPath('src/')
		pfu:addSearchPath('res/')
		local dir = local_dir..'test/'
		if not kits.local_directory_exists(dir) then
			kits.make_local_directory('test/')
		end
		pfu:addSearchPath(dir)
	end
  
  pfu:addSearchPath(local_dir)
end

init_test_resource()
--加入返回键
local function onKeyRelease(key,event)
	if key == cc.KeyCode.KEY_ESCAPE then
		uikits.popScene()
	end
end

local listener_keyboard = cc.EventListenerKeyboard:create()
listener_keyboard:registerScriptHandler(onKeyRelease,cc.Handler.EVENT_KEYBOARD_RELEASED )	
local directorEventDispatcher = cc.Director:getInstance():getEventDispatcher()
directorEventDispatcher:addEventListenerWithFixedPriority(listener_keyboard,1)

if uikits.get_factor() == uikits.FACTOR_9_16 then
	uikits.initDR{width=1920,height=1080}
else
	uikits.initDR{width=1440,height=1080}
end

if uikits.get_factor() == uikits.FACTOR_9_16 then
	uikits.initDR{width=1920,height=1080}
else
	uikits.initDR{width=1440,height=1080}
end
	
local app,cookie = cc_launchparam()
local scene
if cookie and type(cookie)=='string' and string.len(cookie)>1 then
	
	login.set_cookie( cookie )
else
	login.set_selector(1) --学生
end

if app == 'homework' then
	local worklist = require "homework/worklist"
	scene = worklist.create()
elseif app == 'amouse' then
	uikits.initDR{width=1024,height=768,mode=cc.ResolutionPolicy.NO_BORDER}
	local amouse = require "amouse/amouse_om"
	scene = AMouseMain()	
elseif app == 'teacher' then
	local teacher = require "homework/teacher"
	scene = teacher.create()
elseif app == 'errortitile' then
	local WrongSubjectList = require "errortitile/WrongSubjectList"
	scene = WrongSubjectList.create()
else
	local worklist = require "homework/worklist"
	scene = worklist.create()
end
	
cc.Director:getInstance():runWithScene(scene)
