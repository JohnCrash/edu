
-- avoid memory leak
collectgarbage("setpause", 100) 
collectgarbage("setstepmul", 5000)
  
require "src/mainMenu"
----------------
-- for CCLuaEngine traceback
function __G__TRACKBACK__(msg)
    cclog("----------------------------------------")
    cclog("LUA ERROR: " .. tostring(msg) .. "\n")
    cclog(debug.traceback())
    cclog("----------------------------------------")
end

-- run
local function main()
--require("mobdebug").start()
local scene = cc.Scene:create()
scene:addChild(CreateTestMenu())
cc.Director:getInstance():replaceScene(scene)
end

--xpcall(main, __G__TRACKBACK__)
main()