local uikits = require "uikits"
local socket = require "socket"
local loadingbox = require "src/errortitile/loadingbox"
local cache = require "cache"
local topics = require "src/errortitile/topics"
local kits = require "kits"
--local answer = curweek or require "src/errortitile/answer"
local resultview = class("resultview")
resultview.__index = resultview
local ui = {
	RESULTVIEW = '2398',
	exit_but = '2398/2414',
	gomainpage_but = '2398/2413',
	date_txt = '2398/2399',
	practicetime_txt = '2398/2404',
	itemcount_txt = '2398/2408',
	rightper_txt = '2398/2412',	
}
function create(practicetime,right_itemcount,all_itemcount)
	local scene = cc.Scene:create()				
	local cur_layer = uikits.extend(cc.Layer:create(),resultview)		
	cur_layer.practicetime = practicetime	
	cur_layer.right_itemcount = right_itemcount
	cur_layer.all_itemcount = all_itemcount
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

function resultview:showviewdata(item_data)
	local exit_but = uikits.child(self._widget,ui.exit_but)
	local gomainpage_but = uikits.child(self._widget,ui.gomainpage_but)
	local date_txt = uikits.child(self._widget,ui.date_txt)
	local practicetime_txt = uikits.child(self._widget,ui.practicetime_txt)
	local itemcount_txt = uikits.child(self._widget,ui.itemcount_txt)
	local rightper_txt = uikits.child(self._widget,ui.rightper_txt)

	local str_data = os.date("%Y.%m.%d", os.time())
	date_txt:setString(str_data)
	local practicetime = kits.time_to_string(self.practicetime)
	practicetime_txt:setString(practicetime)

	itemcount_txt:setString(self.right_itemcount.."/"..self.all_itemcount)
	local str = string.format("%0.2f",(self.right_itemcount/self.all_itemcount*100))
	rightper_txt:setString(str.."%")
	
	uikits.event(exit_but,	
		function(sender,eventType)
--		kits.quit()
		uikits.popScene()	
		uikits.popScene()	
	end,"click")
	
	uikits.event(gomainpage_but,
		function(sender,eventType)
--[[		local t_wronglist = package.loaded["src/errortitile/WrongSubjectList"]
		if t_wronglist then
			local scene_next = t_wronglist.create()								
			cc.Director:getInstance():replaceScene(scene_next)								
		end			--]]
	--	uikits.popScene()
		uikits.popScene()		
	end,"click")

end

function resultview:init()	
	if _G.screen_type == 1 then
		self._widget = ccs.GUIReader:getInstance():widgetFromJsonFile("errortitile/TheWrong/Export/zuotijieshu.json")			
	else
		self._widget = ccs.GUIReader:getInstance():widgetFromJsonFile("errortitile/TheWrong/Export/zuotijieshu43.json")		
	end
	self:addChild(self._widget)
	self:showviewdata()
	--self:showitemdata(self.item_data)
end

function resultview:release()

end
return {
create = create,
}