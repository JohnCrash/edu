require "Cocos2d"

local local_dir = cc.FileUtils:getInstance():getWritablePath()
local platform = CCApplication:getInstance():getTargetPlatform()

local function init_test_resource()
  local res = local_dir..'res/'
  local pfu = cc.FileUtils:getInstance()
  local size = cc.Director:getInstance():getVisibleSize()

  pfu:addSearchPath(res)
	if platform == kTargetWindows then
		pfu:addSearchPath(local_dir..'cache/')
	else
		pfu:addSearchPath(local_dir..'test/')
	end
  
  pfu:addSearchPath(local_dir)
end

init_test_resource()
--require "src/controller"

--下面的代码单独启动a mouse
-- avoid memory leak
collectgarbage("setpause", 100) 
collectgarbage("setstepmul", 5000)
require "src/mainMenu" 
--require "src/flower"
 -- run
local function main()
	--require("mobdebug").start()
	local scene = cc.Scene:create()
	
	scene:addChild(CreateTestMenu())
	--scene:addChild(LavaFlow())
	cc.Director:getInstance():replaceScene(scene)
end

require("mobdebug").start("192.168.0.182")

main()