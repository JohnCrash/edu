local crash = require "crash"
local uikits = require "uikits"
local cache = require "cache"
local kits = require "kits"
local login = require "login"
local json = require "json-c"
local loadingbox = require "loadingbox"
local TeacherBatch = require "homework/teacherbatch"
local topics = require "homework/topics"

local topics_course = topics.course_icon
local res_local = "homework/"

crash.open("teacher",1)

local ui = {
	FILE = 'homework/laoshizuoye/tongbust.json',
	FILE_3_4 = 'homework/laoshizuoye/tongbust43.json',

}

local exam_list_url="http://new.www.lejiaolexue.com/exam/handler/examhandler.ashx"
local get_class_url = "http://new.www.lejiaolexue.com/exam/handler/examhandler.ashx"

local Sethwbyles = class("Sethwbyles")
Sethwbyles.__index = Sethwbyles

function Sethwbyles.create()
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),Sethwbyles)
	
	scene:addChild(layer)
	
	local function onNodeEvent(event)
		if "enter" == event then
			layer:init()
		elseif "exit" == event then
			layer:release()
		end
	end	
	layer:registerScriptHandler(onNodeEvent)
	return scene
end

function Sethwbyles:init()
	if uikits.get_factor() == uikits.FACTOR_9_16 then
		uikits.initDR{width=1920,height=1080}
	else
		uikits.initDR{width=1440,height=1080}
	end
	self._widget = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE_3_4}
	self:addChild(self._widget)
end

function Sethwbyles:release()
	
end

return Sethwbyles