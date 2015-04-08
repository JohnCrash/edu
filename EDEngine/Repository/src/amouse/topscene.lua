local kits = require "kits"
local curl = require 'curl'
local uikits = require "uikits"
local login = require "login"
local cache = require "cache"
local loadingbox = require "loadingbox"

local ui = {
	FILE = 'amouse/jie_mian_5/jie_mian_5.json',
	BACK = 'Button_fan_hui',
	WEEK = 'CheckBox_ben_zhou_tong_xue_bang',
	HISTORY='CheckBox_li_shi_zui_jia',
	TITLE = 'Image_txdyb',
	CAPTION = 'Label_t',
	LIST = 'ScrollView_6',
	ITEM = 'Panel_7',
	RANK = 'Label_t1',
	NAME = 'Label_name',
	SCORE = 'Label_fen',
	CUP = 'ImageView_121',
}

local TopScene = class("TopScene")
TopScene.__index = TopScene

function TopScene.create(zoneid)
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),TopScene)
	
	scene:addChild(layer)
	layer._zoneid = zoneid
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

function TopScene:init()
	uikits.initDR{width=2048,height=1536,mode=cc.ResolutionPolicy.NO_BORDER}
	self._root = uikits.fromJson{file=ui.FILE}
	self:addChild(self._root)
	local back = uikits.child(self._root,ui.BACK)
	uikits.event(
		back,
		function(sender)
			uikits.popScene()
		end
	)
	self._week = uikits.child(self._root,ui.WEEK)
	self._history = uikits.child(self._root,ui.HISTORY)
	self._caption = uikits.child(self._root,ui.CAPTION)
	self._title = uikits.child(self._root,ui.TITLE)
	self._scrollview = uikits.scroll(self._root,ui.LIST,ui.ITEM)
	uikits.event(self._week,function(sender)
		self:WeekTop()
	end)
	uikits.event(self._history,function(sender)
		self:HistoryTop()
	end)	
	local circle = loadingbox.circle( self._root )
	local url = 'http://api.lejiaolexue.com/rest/userinfo/query_user_area_prop.ashx?uid='..login.uid()
	cache.request_json(url,function(t)
		if circle and cc_isobj(circle) then
			circle:removeFromParent()
		end
		if t and type(t)=='table' and t.area_prop then
			self._prop = t.area_prop
			if self._prop and self._prop.county_id == 0 then --110108 then
				self:CountyTop()
				return
			end
		else
			kits.log("ERROR amoue top scene ,query_uers_area_prop.ashx return invlide value")
		end
		self:WeekTop()
	end)
end

function TopScene:clearAll()
	self._scrollview:clear()
end

function TopScene:rankByUrl( url )
	local circle = loadingbox.circle( self._root )
	cache.request_json(url,function(tops)
		if circle and cc_isobj(circle) then
			circle:removeFromParent()
		end
		self:clearAll()
		if tops and tops.users and type(tops.users)=='table' then
			for k,v in pairs(tops.users) do
				--kits.log( "table:"..k )
				if type(v)=='table' then
				--	for n,s in pairs(v) do
				--		kits.log( "	"..n..":"..s )
				--	end
					local item = self._scrollview:additem()
					uikits.child(item,ui.CUP):setVisible(k==1)
					uikits.child(item,ui.RANK):setString(tostring(k))
					uikits.child(item,ui.NAME):setString(tostring(v.uname))
					uikits.child(item,ui.SCORE):setString(tostring(v.score))
				end
			end		
			self._scrollview:relayout()
		else
			kits.log("players rank table error!")
		end		
	end)
end

function TopScene:WeekTop()
	self._week:setSelectedState(true)
	self._history:setSelectedState(false)
	--week
	local url = 'http://app.lejiaolexue.com/ourgame/api/rank/top.ashx?app_id=1004&period=1&zone_id='..tostring(self._zoneid)
	
	self:rankByUrl(url)
end

function TopScene:HistoryTop()
	self._week:setSelectedState(false)
	self._history:setSelectedState(true)	
	
	local url = 'http://app.lejiaolexue.com/ourgame/api/rank/top.ashx?app_id=1004&period=0&zone_id='..tostring(self._zoneid)
	self:rankByUrl(url)
end

function TopScene:CountyTop()
	self._week:setVisible(false)
	self._history:setVisible(false)
	self._caption:setVisible(true)
	self._caption:setString(" ->"..self._prop.grade_year)
	local url
	self:rankByUrl(url)
end

function TopScene:release()
end

return TopScene