local kits = require "kits"
local json = require "json-c"
local ljshell = require "ljshell"
local resume = require "resume"

local local_dir = ljshell.getDirectory(ljshell.AppDir)
local liexue_server = "http://file.lejiaolexue.com/upgrade/luaapp/v"..resume.getversion().."/"
local local_server = "http://192.168.2.211:81/lgh/v"..resume.getversion().."/"
--返回类的存储根目录
local function getClassRootDirectory()
	return local_dir..'/class/'
end

local function getServerRootDirectory()
	return local_server.."class/"
end

--[[
检查类版本是否需要跟新
通过func(id)通知结果,id是下面的一个值
2本地存在，需要跟新
1本地不存在，需要跟新
0确定不需要跟新
-1没有正确检查但有本地版本,
-2没有正确检查并且不存在本地版本
--]]
local function CheckClassVersion( classId,func )
	
end

--[[
成功func(true),失败func(false)
--]]
local function UpdateClass( classId,func )
end

--[[
跟新类的特定文件，成功func(true),失败func(false)
--]]
local function UpdateClassFiles( classId,func,files )
end

return {
	CheckClassVersion = CheckClassVersion,
	UpdateClass = UpdateClass,
	UpdateClassFiles = UpdateClassFiles,
	getClassRootDirectory = getClassRootDirectory,
}