local crash = require "crash"
local uikits = require "uikits"
local cache = require "cache"
local kits = require "kits"
local login = require "login"
local json = require "json-c"
local loadingbox = require "loadingbox"
local TeacherBatch = require "homework/teacherbatch"
local topics = require "homework/topics"
local Publishhwret = require "homework/publishhwret"
local ui = {
	FILE = 'homework/laoshizuoye/fabu.json',
	FILE_3_4 = 'homework/laoshizuoye/fabu43.json',
	YINBI_TITLE = 'leirong/ys3',
	YINBI_VIEW = 'leirong/yinbi',
	CHECK_DATE_BASE = 'leirong/riqi/tu/d',
	BUTTON_BACK = 'ding/back',
	BUTTON_CONFIRM = 'ding/qr',
	BANJI_VIEW = 'leirong/banji',
	PER_BANJI_VIEW = 'leirong/banji/ban1',
	BANJI_LABEL = 'bm',
	
	FILE_RET = 'homework/laoshizuoye/fubujieshu.json',
	FILE_RET_3_4 = 'homework/laoshizuoye/fubujieshu43.json',
}

local day_index_seled
local banji_sel_num

local banji_space = 30
local Publishhw = class("Publishhw")
Publishhw.__index = Publishhw

function Publishhw.create(tb_parent_view)
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),Publishhw)
	layer.tb_parent_view = tb_parent_view
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

function Publishhw:SetButtonEnabled(but)
	if banji_sel_num  ~= 0 then
		but:setEnabled(true);
		but:setBright(true);
		but:setTouchEnabled(true)
	else
		but:setEnabled(false);
		but:setBright(false);
		but:setTouchEnabled(false)	
	end
end

function Publishhw:showbanjilist(tb_banji)
	local banji_view = uikits.child(self._widget,ui.BANJI_VIEW)
	local src_per_banji_view = uikits.child(self._widget,ui.PER_BANJI_VIEW)
	for i, obj in pairs(tb_banji) do
		cur_banji_view = src_per_banji_view:clone()
		local banji_label = uikits.child(cur_banji_view,ui.BANJI_LABEL)
		banji_label:setString(obj.zone_name)
		cur_banji_view:setVisible(true)
		local pos_x_src = cur_banji_view:getPositionX()
		local size_view = cur_banji_view:getContentSize()
		local pos_x_cur = pos_x_src + (i-1)*(size_view.width+banji_space)
		cur_banji_view:setPositionX(pos_x_cur)
		banji_view:addChild(cur_banji_view)
	end
	local size_banji_view = banji_view:getContentSize()
	local size_view = src_per_banji_view:getContentSize()
	banji_view:setInnerContainerSize(cc.size(#tb_banji*(size_view.width+banji_space),size_banji_view.height))
end

function Publishhw:getdatabyurl()
	local send_url = 'http://api.lejiaolexue.com/rest/user/125907/zone/class'
	local loadbox = loadingbox.open(self)
	cache.request_json( send_url,function(t)
			if t and type(t)=='table' then
				if t.result == 0 then
					--local tb_banji = t.zone
					local tb_banji = {}
					for i=1,10 do 
						tb_banji[i] = t.zone[1]
					end
					self:showbanjilist(tb_banji)
				end
			else
				--��û������Ҳû�л���
				messagebox.open(self,function(e)
					if e == messagebox.TRY then
						self:init()
					elseif e == messagebox.CLOSE then
						uikits.popScene()
					end
				end,messagebox.RETRY)	
			end
			loadbox:removeFromParent()
		end,'NC')
end

function Publishhw:init()
	if uikits.get_factor() == uikits.FACTOR_9_16 then
		uikits.initDR{width=1920,height=1080}
	else
		uikits.initDR{width=1440,height=1080}
	end
	self._widget = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE_3_4}
	self:addChild(self._widget)
	self:getdatabyurl()
	local yinbi_title = uikits.child(self._widget,ui.YINBI_TITLE)
	local yinbi_view = uikits.child(self._widget,ui.YINBI_VIEW)
	yinbi_title:setVisible(false)
	yinbi_view:setVisible(false)

	local but_back = uikits.child(self._widget,ui.BUTTON_BACK)
	local but_confirm = uikits.child(self._widget,ui.BUTTON_CONFIRM)
	uikits.event(but_back,
		function(sender,eventType)
		uikits.popScene()
	end,"click")

	uikits.event(but_confirm,
		function(sender,eventType)
		uikits.pushScene(Publishhwret.create(self.tb_parent_view))
	end,"click")	

	banji_sel_num = 0
	self:SetButtonEnabled(but_confirm)
	
	
	local banji_view = uikits.child(self._widget,ui.BANJI_VIEW)
	banji_view:setDirection(ccui.ScrollViewDir.horizontal)
	local per_banji_view = uikits.child(self._widget,ui.PER_BANJI_VIEW)
	per_banji_view:setVisible(false)
	
	uikits.event(per_banji_view,
			function(sender,eventType)
				local but_confirm = uikits.child(self._widget,ui.BUTTON_CONFIRM)
				if eventType == true then
					banji_sel_num = banji_sel_num+1
				else
					banji_sel_num = banji_sel_num-1
				end
				self:SetButtonEnabled(but_confirm)
		end)		
	
	for i = 1,8 do 
		local checkbox_day = uikits.child(self._widget,ui.CHECK_DATE_BASE..i)
		if i == 1 then
			checkbox_day:setSelectedState(true)
			day_index_seled = i
		else
			checkbox_day:setSelectedState(false)	
		end
		checkbox_day.index = i
		uikits.event(checkbox_day,
			function(sender,eventType)
				local checkbox_day = sender
				local checkbox_day_old = uikits.child(self._widget,ui.CHECK_DATE_BASE..day_index_seled)
				if eventType == true then
					if day_index_seled ~= checkbox_day.index then
						checkbox_day_old:setSelectedState(false)
					end
					day_index_seled = checkbox_day.index
				else
					if day_index_seled == checkbox_day.index then
						checkbox_day:setSelectedState(true)
					end
				end
		end)	
	end
end

function Publishhw:release()
	
end

return Publishhw