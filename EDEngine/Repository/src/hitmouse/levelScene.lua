local kits = require "kits"
local uikits = require "uikits"
local cache = require "cache"
local battle = require "hitmouse/battle"
local level = require "hitmouse/level"
local http = require "hitmouse/hitconfig"

local ui = {
	FILE = 'hitmouse/chuangguan.json',
	FILE_3_4 = 'hitmouse/chuangguan43.json',
	BACK = 'ding/fan',
	LIST = 'fan',
	ITEM_NUMBER = 'g1',
	ITEM_CURRENT = 'g2',
	ITEM_LOCK = 'g3',
}

local levelScene = uikits.SceneClass("levelScene")
--[[
local levelScene = class("levelScene")
levelScene.__index = levelScene

function levelScene.create()
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),levelScene)
	
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
--]]
function levelScene:clear()
	if self._items then
		for i,v in pairs(self._items) do
			v:removeFromParent()
		end
		self._items = {}
	end
end

function levelScene:add(m,n,b)
	self._items = self._items or {}
	local item
	if m==1 then
		item = self._item_number:clone()
	elseif m==2 then
		item = self._item_current:clone()
	else
		item = self._item_lock:clone()
	end
	if m==1 or m==2 then
		uikits.event(item,function(sender)
			local send_data = {V1=n,V2=1}
			kits.log("do levelScene launch battle...")
			http.post_data(self._root,'get_match',send_data,function(t,v)
				if t and t==200 and v then
					http.logTable(v,1)
					local signle,dual = 1,1
					if v.question_amount and v.question_signle then
						signle = v.question_signle
						dual = v.question_amount-signle
					else
						kits.log("ERROR get_match invaild result,v.question_signle = nil")
					end	
--[[					
					uikits.pushScene(battle.create{
							level = v.road_block_id or 1,
							time_limit = 120,
							rand = 1,
							diff1 = 1,
							diff2 = 5,
							signle = 1,
							dual = 0,
							condition = 70,
							type = 1,
						})	
						--]]
---[[						
					uikits.pushScene(battle.create{
							level = v.road_block_id or 1,
							time_limit = v.times or 10,
							rand = v.road_radom or 0,
							diff1 = v.diffcult_low or 0,
							diff2 = v.diffcult_up or 0,
							signle = signle,
							dual = dual,
							condition = v.pass_condition or 60,
							type = 1,
						})
						--]]
				else
					http.messagebox(self._root,http.DIY_MSG,function(e)
						if e==http.RETRY then
							self:add(m,n,b)
						else
							uikits.popScene()
						end
					end,v)		
				end
			end)
		end)
	end
	item:setVisible(true)
	if n then
		local txt = uikits.child(item,'su')
		if txt then
			txt:setString(tostring(n))
		end
	end
	self._list:addChild(item)
	if not b then
		table.insert(self._items,item)	
	end
	return item
end

function levelScene:relayout()
	if self._items then
		local count = #self._items
		local raw = math.floor(count/self._colume)
		if count%self._colume > 0 then
			raw = raw + 1
		end
		local size = cc.size(self._list_size.width,raw*(self._item_size.height+self._space)+self._space)
		local x,y = self._offset,size.height-self._space-self._item_size.height
		self._list:setInnerContainerSize(size)
		local n = 1
		for i=1,count do
			self._items[i]:setPosition(cc.p(x,y))
			if n < self._colume then
				x = x + self._space + self._item_size.width
				n = n + 1
			else
				x = self._offset
				y = y - self._space - self._item_size.height
				n = 1
			end
		end
	end
end

function levelScene:visibleCurrent()
	if self._items and self._current and self._items[self._current] then
		local x,y = self._items[self._current]:getPosition()
		local inner = self._list:getInnerContainer()
		local xx,yy = inner:getPosition()
		if y<-yy then
			inner:setPosition(cc.p(xx,-(y-self._space)))
		end
	end
end

function levelScene:init()
	if uikits.get_factor() == uikits.FACTOR_9_16 then
		self._ss = cc.size(1920,1080)
	else
		self._ss = cc.size(1440,1080)
	end
	uikits.initDR{width=self._ss.width,height=self._ss.height}
	if not self._root then
		self._root = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE_3_4}
		self:addChild(self._root)
		uikits.event(uikits.child(self._root,ui.BACK),function(sender)
			uikits.popScene()
		end)
		self._list = uikits.child(self._root,ui.LIST)
		uikits.enableMouseWheelIFWindows(self._list)
		self._item_number = uikits.child(self._list,ui.ITEM_NUMBER)
		self._item_current = uikits.child(self._list,ui.ITEM_CURRENT)
		self._item_lock = uikits.child(self._list,ui.ITEM_LOCK)
		self._item_number:setAnchorPoint(cc.p(0,0))
		self._item_current:setAnchorPoint(cc.p(0,0))
		self._item_lock:setAnchorPoint(cc.p(0,0))
		self._item_size = self._item_number:getContentSize()
		self._list_size = self._list:getContentSize()
		if self._list_size.width == 1920 then
			self._colume = 10
			self._offset = 86
			self._space = 28
		else
			self._colume = 8
			self._offset = 64
			self._space = 16		
		end
		self._item_number:setVisible(false)
		self._item_current:setVisible(false)
		self._item_lock:setVisible(false)
	end
	if self._current and self._current==level.getCurrent() then
	elseif self._current and self._current==level.getCurrent()-1 then
		self:initOpenNext()
	else
		self:clear()
		self._current = level.getCurrent()
		self._count = level.getLevelCount()
		self:initLevelList()
	end
end

function levelScene:initOpenNext()
	if self._current and self._items and self._current < self._count then
		local cx,cy = self._items[self._current]:getPosition()
		local dx,dy = self._items[self._current+1]:getPosition()
		self._items[self._current]:removeFromParent()
		self._items[self._current+1]:removeFromParent()
		self._items[self._current] = self:add(1,self._current,true)
		self._items[self._current+1] = self:add(2,self._current+1,true)
		self._items[self._current]:setPosition(cc.p(cx,cy))
		self._items[self._current+1]:setPosition(cc.p(dx,dy))
		self._current = self._current + 1
		self:visibleCurrent()
	end
end

function levelScene:initLevelList()
	for i = 1,self._current-1 do
		self:add(1,i)
	end
	if self._current <= 0 then
		self._current = 1
	end
	if self._current <= self._count then
		self:add(2,self._current)
		for i = self._current+1,self._count do
			self:add(3)
		end
	end
	self:relayout()
	self:visibleCurrent()
end

function levelScene:release()
	uikits.enableMouseWheelIFWindows(nil)
end

return levelScene