local kits = require "kits"
local uikits = require "uikits"
local cache = require "cache"
local level = require "hitmouse2/game"
local music = require "hitmouse2/music"
local http = require "hitmouse2/hitconfig"
local global = require "hitmouse2/global"
local state = require "hitmouse2/state"

local ui = {
	FILE = 'hitmouse2/load.json',
	FILE_3_4 = 'hitmouse2/load43.json',
	PROGRESS = "jindu",
}

local loading = uikits.SceneClass("loading")

function loading:init()
	local login = require "login"
	kits.log("uid:"..tostring(login.uid()))
	kits.log("cookie:"..tostring(login.cookie()))
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
		self:get_user_info()
		self:login()
	end
end

function loading:get_user_info()
	local url = 'http://api.lejiaolexue.com/rest/userinfo/full/current'
	cache.request_json( url,function(t)
		http.logTable(t,1)
		if t then
			if t.uig and t.uig[1] and t.uig[1].uname then
				state.set_name(t.uig[1].uname)
				return
			else
				http.messagebox(self._root,http.DIY_MSG,function(e)
					if e == http.RETRY then
						self:get_user_info()
					else
						uikits.popScene()
					end
				end,tostring(t.msg))
			end
		end
	end)
end

function loading:login()
	local send_data = {}
	kits.log("do loading:login...")
	http.post_data(self._root,'login',send_data,function(t,v)
					if t and t == 200 and v then
						http.logTable(v,1)
						self._progress:setPercent(10)
						self:initUserId()
					else
						http.messagebox(self._root,http.DIY_MSG,function(e)
							if e==http.RETRY then
								self:login()
							else
								uikits.popScene()
							end
						end,v)	
					end
				end,true)
end

function loading:launch()
	self._progress:setPercent(100)
	kits.log("login success!")
	local main = require "hitmouse2/main"
	uikits.replaceScene(main.create(self._arg))
	level.init()
end

function loading:initClassOrChild2()
	http.post_data(self._root,'get_childinfo',send_data,function(t,v)
			if t and t==200 and v then
				http.logTable(v)
				if v.v1 and v.v2 then
					global.setChildInfo(v)
				else
					global.setChildInfo({v1=false,v2={}})
				end
				self:launch()
			else
				http.messagebox(self._root,http.DIY_MSG,function(e)
					if e == http.RETRY then
						self:initClassOrChild2()
					else
						uikits.popScene()
					end
				end,v)	
			end
	end,true)	
end

function loading:initClassOrChild()
	local id = http.get_id_flag()
	local send_data={}
	http.post_data(self._root,'get_teacherclass',send_data,function(t,v)
			if t and t==200 and v then
				global.setTeacherClass(v)
				self:initClassOrChild2()
			else
				http.messagebox(self._root,http.DIY_MSG,function(e)
					if e == http.RETRY then
						self:initClassOrChild()
					else
						uikits.popScene()
					end
				end,v)	
			end
	end,true)
end

function loading:initBuyVoteInfo()
	local send_data = {}
	kits.log("do loading:initBuyVoteInfo...")
	http.post_data(self._root,'buy_vote_info',send_data,function(t,v)
		if t and t==200 and v then
			self._progress:setPercent(100)
			kits.log("loading initBuyVoteInfo success!")
			http.logTable(v,1)
			global.setBuyVoteInfo(v.v1,v.v2,v.v3)
			self:initClassOrChild()
		else
			http.messagebox(self._root,http.DIY_MSG,function(e)
				if e == http.RETRY then
					self:initBuyVoteInfo()
				else
					uikits.popScene()
				end
			end,v)	
		end
	end,true)
end

function loading:initAttachChild()
	local send_data = {}
	kits.log("do loading:initAttachChild...")
	http.post_data(self._root,'get_attach_child',send_data,function(t,v)
		if t and t==200 and v then
			self._progress:setPercent(100)
			kits.log("loading initAttachChild success!")
			http.logTable(v,1)
			global.setAttachChildUID(v.v1)
			self:initClassOrChild()
		else
			http.messagebox(self._root,http.DIY_MSG,function(e)
				if e == http.RETRY then
					self:initAttachChild()
				else
					uikits.popScene()
				end
			end,v)	
		end
	end,true)
end

function loading:initLevelStar()
	local send_data = {}
	kits.log("do loading:initLevelStar...")
	http.post_data(self._root,'get_level_star',send_data,function(t,v)
		if t and t==200 and v then
			self._progress:setPercent(96)
			kits.log("loading initLevelStar success!")
			http.logTable(v,1)
			state.set_level_star(v)
			self:initAttachChild()
		else
			http.messagebox(self._root,http.DIY_MSG,function(e)
				if e == http.RETRY then
					self:initLevelStar()
				else
					uikits.popScene()
				end
			end,v)	
		end
	end,true)
end

function loading:initRegion()
	local send_data = {}
	kits.log("do loading:initRegion...")
	http.post_data(self._root,'list_region',send_data,function(t,v)
		if t and t==200 and v then
			self._progress:setPercent(93)
			kits.log("loading initRegion success!")
			http.logTable(v,1)
			state.set_region(v.v1,v.v2,v.v3,v.v4)
			self:initLevelStar()
		else
			http.messagebox(self._root,http.DIY_MSG,function(e)
				if e == http.RETRY then
					self:initRegion()
				else
					uikits.popScene()
				end
			end,v)	
		end
	end,true)
end

function loading:initSilver()
	local send_data = {}
	kits.log("do loading:initSilver...")
	http.post_data(self._root,'get_silver_count',send_data,function(t,v)
		if t and t==200 and v then
			self._progress:setPercent(90)
			kits.log("loading initSilver success!")
			http.logTable(v,1)
			if v.v1 then
				state.set_sliver(v.v1)
			else
				kits.log("ERROR get_silver_count return invalid value")
			end
			self:initRegion()
		else
			http.messagebox(self._root,http.DIY_MSG,function(e)
				if e == http.RETRY then
					self:initSilver()
				else
					uikits.popScene()
				end
			end,v)	
		end
	end,true)
end

function loading:initSP()
	local send_data = {}
	kits.log("do loading:initSP...")
	http.post_data(self._root,'get_sp',send_data,function(t,v)
		if t and t==200 and v then
			self._progress:setPercent(60)
			kits.log("loading initSP success!")
			http.logTable(v,1)
			if v.v1 and v.v2 and v.v3 then
				state.set_sp(v.v1,v.v2,v.v3)
			else
				state.set_sp(0,0,0)
				kits.log("ERROR get_sp return invalid value")
			end
			self:initSilver()
		else
			http.messagebox(self._root,http.DIY_MSG,function(e)
				if e == http.RETRY then
					self:initSP()
				else
					uikits.popScene()
				end
			end,v)	
		end
	end,true)
end

function loading:initNews()
	local send_data = {}
	kits.log("do loading:get_news...")
	http.post_data(self._root,'get_news',send_data,function(t,v)
		if t and t==200 and v then
			self._progress:setPercent(50)
			kits.log("loading initNews success!")
			http.logTable(v,1)
			self._arg.hasMission = v.v1
			self._arg.hasMatch = v.v2
			self._arg.hasWorldMatch = v.v3
			self._arg.hasAchievement = v.v4
			state.set_news(v.v1,v.v2,v.v3,v.v4)
			self:initSP()
		else
			http.messagebox(self._root,http.DIY_MSG,function(e)
				if e == http.RETRY then
					self:initNews()
				else
					uikits.popScene()
				end
			end,v)	
		end
	end,true)
end

function loading:initSummary()
	local send_data = {}
	kits.log("do loading:initSummary...")
	http.post_data(self._root,'get_user_msg_state',send_data,function(t,v)
		if t and t==200 and v then
			self._progress:setPercent(40)
			kits.log("loading initLevelData success!")
			http.logTable(v,1)
			self._arg = {}
			self._arg.hasMsg = v.v1
			state.set_hasmsg(v.v1)
			self:initNews()
		else
			http.messagebox(self._root,http.DIY_MSG,function(e)
				if e == http.RETRY then
					self:initSummary()
				else
					uikits.popScene()
				end
			end,v)	
		end
	end,true)
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
			self._progress:setPercent(30)
			self:initSummary()
		else
			http.messagebox(self._root,http.DIY_MSG,function(e)
				if e == http.RETRY then
					self:initLevelData()
				else
					uikits.popScene()
				end
			end,v)			
		end
	end,true)
end

function loading:initUserId()
	kits.log("do loading:initUserId...")
	http.get_user_id(self._root,function(b,try)
		if b then
			kits.log("loading initUserId success!")
			self._progress:setPercent(20)
			--强制设置
			--http.set_id_flag(http.ID_FLAG_STU)
			--http.set_id_flag(http.ID_FLAG_TEA)
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