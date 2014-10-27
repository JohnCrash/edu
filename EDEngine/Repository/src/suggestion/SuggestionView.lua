local uikits = require "uikits"
local kits = require "kits"
local json = require "json-c"
local login = require "login"
local cache = require "cache"
local loadingbox = require "loadingbox"
local messagebox = require "messagebox"
local SuggestionRet = require "suggestion/SuggestionRet"
local SuggestionView = class("SuggestionView")
SuggestionView.__index = SuggestionView

--local get_uesr_info_url = 'http://api.lejiaolexue.com/rest/userinfo/simple/current'
local ui = {
	FILE = 'suggestion/yijian169.json',
	FILE_3_4 = 'suggestion/yijian43.json',
	CHECKBOX_YIJIAN = 'jian',
	CHECKBOX_CUOWU = 'cuo',
	CHECKBOX_TOUSU = 'tou',
	BUTTON_BACK = 'tiao/fanhui',
	BUTTON_COMMIT = 'tiao/ti',
	EDIT_CONTENT = 'wen/wenzi',
}

function create()
	local scene = cc.Scene:create()				
	local cur_layer = uikits.extend(cc.Layer:create(),SuggestionView)		
	--cur_layer.screen_type = screen_type	
	
	scene:addChild(cur_layer)
	
	local function onNodeEvent(event)
		if "enter" == event then
			cur_layer:init()
		elseif "exit" == event then			
			cur_layer:release()
		end
	end	
	cur_layer:registerScriptHandler(onNodeEvent)
	return scene	
end

--local cookie_1 = "sc1=D3F1DC81D98457FE8E1085CB4262CAAD5C443773akl%2bNQbvBYOcjHsDK0Fu4kV%2fbgv3ZBi7sFKU19KP5ks0GkvPwGpmMWe%2b8Q6O%2fkT7EuHjkQ%3d%3d"
local upload_url = 'http://api.lejiaolexue.com/rest/feedback/add.ashx'
function SuggestionView:upload_suggestion()
	local edit_view = uikits.child(self._widget,ui.EDIT_CONTENT)
	local txt_send = edit_view:getStringValue()
	local send_data 
	if txt_send ~= ''then
		send_data = 'type='..self.sel_type..'&content='..txt_send
	else
		send_data = 'type='..self.sel_type..'&content='
		print('EDIT_CONTENT  nil')
	--	return
	end
	cache.request_json( upload_url..'?'..send_data,function(t)
		if t and type(t)=='table' then
			if 	t.result ~= 0 then			
				print(tostring(t.msg))	
				local scene_next = SuggestionRet.create(false,send_data)	
				uikits.pushScene(scene_next)				
			else
				local scene_next = SuggestionRet.create(true)	
				uikits.pushScene(scene_next)		
			end	
		else
			--既没有网络也没有缓冲
			messagebox.open(self,function(e)
				if e == messagebox.TRY then
					self:upload_suggestion()
				elseif e == messagebox.CLOSE then
					uikits.popScene()
				end
			end,messagebox.RETRY)	
		end
	end,'N')	

end

function SuggestionView:SetButtonEnabled(is_show)
	local but = uikits.child(self._widget,ui.BUTTON_COMMIT)
	if is_show == true then
		but:setEnabled(true)
		but:setBright(true)
		but:setTouchEnabled(true)
	else
		but:setEnabled(false)
		but:setBright(false)
		but:setTouchEnabled(false)	
	end
end

function SuggestionView:init()	
--	loadArmature("errortitile/silver/Export/NewAnimation/NewAnimation.ExportJson")	
	if uikits.get_factor() == uikits.FACTOR_9_16 then
		uikits.initDR{width=1920,height=1080}
	else
		uikits.initDR{width=1440,height=1080}
	end
	self._widget = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE_3_4}
	self:addChild(self._widget)
--	self._widget:setScale(0.5)
	uikits.initDR(design)
	
	self: SetButtonEnabled(false)
	
	local check_yijian = uikits.child(self._widget,ui.CHECKBOX_YIJIAN)
	local check_cuowu = uikits.child(self._widget,ui.CHECKBOX_CUOWU)
	local check_tousu  = uikits.child(self._widget,ui.CHECKBOX_TOUSU)
	
	self.sel_type = 0
	uikits.event(check_yijian,
		function(sender,eventType)
			if eventType == true then
				local checkbox_old
				if self.sel_type == 2 then
					checkbox_old = uikits.child(self._widget,ui.CHECKBOX_CUOWU)
					checkbox_old:setSelectedState(false)
				elseif self.sel_type == 3 then
					checkbox_old = uikits.child(self._widget,ui.CHECKBOX_TOUSU)
					checkbox_old:setSelectedState(false)					
				end
				self: SetButtonEnabled(true)
				self.sel_type = 1
			else
				if self.sel_type == 1 then
					sender:setSelectedState(true)
				end
			end
	end)		
	
	uikits.event(check_cuowu,
		function(sender,eventType)
			if eventType == true then
				local checkbox_old
				if self.sel_type == 1 then
					checkbox_old = uikits.child(self._widget,ui.CHECKBOX_YIJIAN)
					checkbox_old:setSelectedState(false)
				elseif self.sel_type == 3 then
					checkbox_old = uikits.child(self._widget,ui.CHECKBOX_TOUSU)
					checkbox_old:setSelectedState(false)					
				end
				self: SetButtonEnabled(true)
				self.sel_type = 2
			else
				if self.sel_type == 2 then
					sender:setSelectedState(true)
				end
			end
	end)		
	
	uikits.event(check_tousu,
		function(sender,eventType)
			if eventType == true then
				local checkbox_old
				if self.sel_type == 1 then
					checkbox_old = uikits.child(self._widget,ui.CHECKBOX_YIJIAN)
					checkbox_old:setSelectedState(false)
				elseif self.sel_type == 2 then
					checkbox_old = uikits.child(self._widget,ui.CHECKBOX_CUOWU)
					checkbox_old:setSelectedState(false)					
				end
				self: SetButtonEnabled(true)
				self.sel_type = 3
			else
				if self.sel_type == 3 then
					sender:setSelectedState(true)
				end
			end
	end)		
	
	local but_commit = uikits.child(self._widget,ui.BUTTON_COMMIT)
	local but_back = uikits.child(self._widget,ui.BUTTON_BACK)
	uikits.event(but_commit,
		function(sender,eventType)
		self:upload_suggestion()
	end,"click")	
	
	uikits.event(but_back,
		function(sender,eventType)
		uikits.popScene()
	end,"click")		
--	self:getdatabyurl()
--	local loadbox = SuggestionViewbox.open(self)
--	local scene_next = WrongSubjectList.create()								
--	cc.Director:getInstance():replaceScene(scene_next)	

end

function SuggestionView:release()

end
return {
create = create,
}