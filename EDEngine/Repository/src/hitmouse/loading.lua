local kits = require "kits"
local uikits = require "uikits"
local cache = require "cache"
local level = require "hitmouse/level"
local music = require "hitmouse/music"
local http = require "hitmouse/hitconfig"

local ui = {
	FILE = 'hitmouse/load.json',
	FILE_3_4 = 'hitmouse/load43.json',
	PROGRESS = "jindu",
}

local loading = class("loading")
loading.__index = loading

function loading.create()
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),loading)
	
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

function loading:init()
	if uikits.get_factor() == uikits.FACTOR_9_16 then
		self._ss = cc.size(1920,1080)
	else
		self._ss = cc.size(1440,1080)
	end
	uikits.initDR{width=self._ss.width,height=self._ss.height}
	if not self._root then
		self._root = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE_3_4}
		self:addChild(self._root)
		self._progress = uikits.child(self._root,ui.PROGRESS)
		self._progress:setPercent(0)
		http.set_base_rid()
		self:login()
	end
end

function loading:login()
	local send_data = {}
	kits.log("do loading:login...")
	http.post_data(self._root,'login',send_data,function(t,v)
					if t and t == 200 and v then
						http.logTable(v,1)
						self._progress:setPercent(30)
						self:initUserId()
					else
						http.messagebox(self._root,http.NETWORK_ERROR,function(e)
							if e == http.OK then
								self:login()
							else
								uikits.popScene()
							end
						end)							
					end
				end,true)
end

function loading:launch()
	self._progress:setPercent(100)
	level.init()
	kits.log("login success!")
	local main = require "hitmouse/main"
	uikits.replaceScene(main.create())
end

function loading:initLevelData()
	local send_data = {}
	kits.log("do loading:initLevelData...")
	http.post_data(self._root,'get_roadblock_list',send_data,function(t,v)
		if t and t==200 and v then
			kits.log("loading initLevelData success!")
			http.logTable(v,1)
			if v.v1 and type(v.v1)=='number' then
				level.setCurrent(v.v1)
			else
				kits.log("ERROR loading:initLevelData v1 invalid")
			end
			if v.v2 and type(v.v2)=='number' then
				level.setLevelCount(v.v2)
			else
				kits.log("ERROR loading:initLevelData v2 invalid")
			end			
			self:launch()
		else
			http.messagebox(self._root,http.NETWORK_ERROR,function(e)
				if e == http.OK then
					self:initLevelData()
				else
					uikits.popScene()
				end
			end)			
		end
	end,true)
end

function loading:initUserId()
	kits.log("do loading:initUserId...")
	http.get_user_id(self._root,function(b,try)
		if b then
			kits.log("loading initUserId success!")
			self._progress:setPercent(60)
			self:initLevelData()
		elseif try then
			self:initUserId()
		else
			uikits.popScene()
		end
	end)
end

function loading:release()
end

return loading