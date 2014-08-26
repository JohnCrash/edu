require "Cocos2d"
local kits = require "kits"
local uikits = require "uikits"

local local_dir = cc.FileUtils:getInstance():getWritablePath()
local platform = CCApplication:getInstance():getTargetPlatform()

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
		pfu:addSearchPath(local_dir..'test/')
	end
  
  pfu:addSearchPath(local_dir)
end

init_test_resource()
require("mobdebug").start("192.168.2.182")

if uikits.get_factor() == uikits.FACTOR_9_16 then
	uikits.initDR{width=1920,height=1080}
else
	uikits.initDR{width=1440,height=1080}
end
	
local app,cookie = cc_launchparam()
local scene
app = 'homework'
cookie = "sc1=D3F1DC81D98457FE8E1085CB4262CAAD5C443773akl%2bNQbvBYOcjHsDK0Fu4kV%2fbgv3ZBi7sFKU19KP5ks0GkvPwGpmMWe%2b8Q6O%2fkT7EuHjkQ%3d%3d"
if cookie then
	local login = require "login"
	login.set_cookie( cookie )
end

if app == 'homework' then
	local worklist = require "homework/worklist"
	scene = worklist.create()
elseif app == 'amouse' then
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
