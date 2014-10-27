local crash = require "crash"
local uikits = require "uikits"
local cache = require "cache"
local kits = require "kits"
local login = require "login"
local json = require "json-c"
local loadingbox = require "loadingbox"


local ui = {
	FILE = 'suggestion/jieguo169.json',
	FILE_3_4 = 'suggestion/jieguo43.json',
	UPLOAD_SUCCESS_VIEW = '1',
	UPLOAD_FAIL_VIEW = '2',
	BUTTON_BACK = 'tiao/fanhui',
	BUTTON_QUIT = '1/tui',
	BUTTON_RETRY = '2/cong',
}

local SuggestionRet = class("SuggestionRet")
SuggestionRet.__index = SuggestionRet

function SuggestionRet.create(is_success,send_data)
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),SuggestionRet)
	layer.is_success = is_success
	if is_success == false and send_data then
		layer.send_data = send_data
	end
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

local upload_url = 'http://api.lejiaolexue.com/rest/feedback/add.ashx'

function SuggestionRet:upload_suggestion()
	cache.request_json( upload_url..'?'..self.send_data,function(t)
		if t and type(t)=='table' then
			if 	t.result ~= 0 then				
				local scene_next = SuggestionRet.create(false,self.send_data)	
				cc.Director:getInstance():replaceScene(scene_next)				
			else
				local scene_next = SuggestionRet.create(true)	
				cc.Director:getInstance():replaceScene(scene_next)		
			end	
		else
			--既没有网络也没有缓冲
			messagebox.open(self,function(e)
				if e == messagebox.TRY then
					self:upload_suggestion()
				elseif e == messagebox.CLOSE then
					uikits.popScene()
					uikits.popScene()
				end
			end,messagebox.RETRY)	
		end
	end,'N')	

end

function SuggestionRet:init()
	if uikits.get_factor() == uikits.FACTOR_9_16 then
		uikits.initDR{width=1920,height=1080}
	else
		uikits.initDR{width=1440,height=1080}
	end
	self._widget = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE_3_4}
	self:addChild(self._widget)
--	self._widget:setScale(0.5)
	local view_success = uikits.child(self._widget,ui.UPLOAD_SUCCESS_VIEW)
	local view_fail = uikits.child(self._widget,ui.UPLOAD_FAIL_VIEW)
	if self.is_success == true then
		view_success:setVisible(true)	
		view_fail:setVisible(false)	
	else
		view_success:setVisible(false)	
		view_fail:setVisible(true)		
	end
	
	local but_back = uikits.child(self._widget,ui.BUTTON_BACK)
	local but_quit = uikits.child(self._widget,ui.BUTTON_QUIT)
	local but_retry = uikits.child(self._widget,ui.BUTTON_RETRY)

	uikits.event(but_back,
		function(sender,eventType)
		uikits.popScene()
	end,"click")	
	
	uikits.event(but_quit,
		function(sender,eventType)
		uikits.popScene()
		uikits.popScene()
	end,"click")		
	
	uikits.event(but_retry,
		function(sender,eventType)
		uikits.popScene()
	end,"click")		
end

function SuggestionRet:release()
	
end

return SuggestionRet