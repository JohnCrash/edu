local kits = require "kits"
local uikits = require "uikits"
local cache = require "cache"
local global = require "han/global"
local http = require "han/http"
local json = require "json-c"
local login = require "login"

local ui = {
	FILE = 'han/load.json',
	FILE_3_4 = 'han/load43.json',
	PROGREloading = "jindu",
	designWidth = 1920,
	designHeight = 1080,
	PROGRESSBAR = "Panel_5/ProgressBar_7",
}

local loading = global.SceneClass("loading",ui)

local function commit_kp(root,progress)
	local dir = "g:/source/cap/zhejiao"
	lfs = require "lfs"
	progress:setPercent(0)
	local t = {}
	for file in lfs.dir(dir) do
		if file~='.' and file ~= '..' then
			if string.find(file,"kp_") then
				file = dir.."/"..file
				table.insert(t,file)
			end
		end
	end
	local function post(idx)
		uikits.delay_call(root,function(dt)
			if t[idx] then
				print( t[idx] )
				local file = io.open(t[idx],"rb")
				buf = file:read("*a")
				file:close()
				print( "read success" )
				local jt = json.decode(buf)
				print( "decode success" )
				global.post_data(root,"commit_kp",
					{v1=jt.list,v2=tonumber(jt.code)},
					function(v)
						return (v)
					end,
					function(v)
						if v and v.v1 then
							progress:setPercent(idx*100/#t)
							post(idx+1)
						else
							print( tostring(v.v2) )
						end
					end,
					function()
						post(idx)
					end,
					nil,true)
			else
				print("kp done!")
			end
		end)
	end
	post(1)
end

local function commit_question(root,progress)
	local dir = "g:/source/cap/upload"
	lfs = require "lfs"
	progress:setPercent(0)
	local t = {}
	for file in lfs.dir(dir) do
		if file~='.' and file ~= '..' then
			if string.find(file,"tp_") then
				file = dir.."/"..file
				table.insert(t,file)
			end
		end
	end
	local function post(idx)
		uikits.delay_call(root,function(dt)
			if t[idx] then
				print(t[idx])
				local file = io.open(t[idx],"rb")
				buf = file:read("*a")
				file:close()
				
				local jt = json.decode(buf)
				if jt.list then
					for i,v in pairs(jt.list) do
						if v.questionList then
							for ii,vv in pairs(v.questionList) do
								if vv.question then
									vv.question = global.crypt_encode(vv.question)
								end
							end
						end
					end

					--http.logTable(jt.list)
					
					global.post_data(root,"commit_question",
						{v1=jt.list},
						function(v)
							return (v)
						end,
						function(v)
							if v and v.v1 then
								progress:setPercent(idx*100/#t)
								post(idx+1)
							else
								print( tostring(v.v2) )
							end
						end,
						function()
							post(idx)
						end,
						nil,true)
				else
					print("list = nil")
					progress:setPercent(idx*100/#t)
					post(idx+1)
				end					
			else
				print("question done!")
				commit_kp(root,progress)
			end
		end)
	end
	post(1)
end

--9
function loading:get_homework_state()
	global.post_data(self._root,"get_homework_state",{},
	function(v)
		return (v)
	end,
	function(v)
		self:next_step()
		global.set_homework_state(v.v1)
		uikits.delay_call(nil,function(dt)
		uikits.replaceScene(require "calc/mainui".create())
		end,0.1)
		--commit_kp(self._root,self._progress)
		--commit_question(self._root,self._progress)
	end,
	function()
		self:get_homework_state()
	end,nil,true)	
end

--8
function loading:get_current_level()
	global.post_data(self._root,"get_levels",{},
	function(v)
		return (v and v.v1 and v.v2 and v.v3 and 
				v.v4 and v.v5 and v.v6 and v.v7 and v.v8)
	end,
	function(v)
		self:next_step()
		global.set_levels(v)
		self:get_homework_state()
	end,
	function()
		self:get_current_level()
	end,nil,true)	
end
--7
function loading:get_sp()
	global.post_data(self._root,"get_sp",{},
	function(v)
		return (v and v.v1 and v.v2 and v.v3)
	end,
	function(v)
		self:next_step()
		global.set_sp(v.v1,v.v2,v.v3)
		self:get_current_level()
	end,
	function()
		self:get_sp()
	end,nil,true)	
end
--6
function loading:get_setup()
	global.post_data(self._root,"load_config",{},
	function(v)
		return v
	end,
	function(v)
		self:next_step()
		if v.v1 and v.v2 and type(v.v2)=="string" then
			local t = json.decode(v.v2)
			if t then
				global.set_game_configure(t)
				--[[
				if t.calc_mute then
					global.play()
				end
				uikits.muteClickSound(not t.calc_audio)
				--]]
			else
				kits.log("ERROR loading:get_setup decode failed")
			end
		else
			kits.log("ERROR loading:get_setup invalid result")
		end
		self:get_sp()
	end,
	function()
		self:get_setup()
	end,nil,true)	
end
--5
function loading:get_class()
	global.post_data(self._root,"get_classes",{},
	function(v)
		return (v and type(v)=='table')
	end,
	function(v)
		self:next_step()
		global.setClass(v)
		self:get_setup()
	end,
	function()
		self:get_class()
	end,nil,true)	
end

--4
function loading:get_kp()
	global.post_data(self._root,"get_knowledge",{},
	function(v)
		return (v and type(v)=='table')
	end,
	function(v)
		self:next_step()
		global.setKP(v)
		self:get_class()
	end,
	function()
		self:get_kp()
	end,nil,true)	
end

--3
function loading:get_msg_count()
	global.post_data(self._root,"get_msg_count",{},
	function(v)
		return (v and v.v1 and v.v1 >= 0)
	end,
	function(v)
		self:next_step()
		global.setMailNum(v.v1)
		self:get_kp()
	end,
	function()
		self:get_msg_count()
	end,nil,true)
end

function loading:next_step()
	self._progress:setPercent(self._step*100/self._max_step)
	self._step = self._step + 1
end

--2
function loading:get_childinfo()
	global.post_data(self._root,"get_childinfo",{},
	function(v)
		return (v and type(v)=='table')
	end,
	function(v)
		self:next_step()
		global.setChildInfo(v.v2)
		self:initUserId()
	end,
	function()
		self:get_kp()
	end,nil,true)	
end

--1
function loading:login()
	http.set_base_rid()
	global.post_data(self._root,"login",{},
	function(v)
		return v
	end,
	function(v)
		self:next_step()
		self:get_childinfo()
	end,
	function()
		self:login()
	end,
	"登录被拒绝",true)
end

--2
function loading:initUserId()
	kits.log("do loading:initUserId...")
	http.get_user_id(self._root,function(b,try)
		if b then
			kits.log("loading initUserId success!")
			self:next_step()
			--self:get_msg_count()
			uikits.delay_call(nil,function(dt)
			uikits.replaceScene(require "han/main".create())
			end,0.1)			
		elseif try then
			self:initUserId()
		else
			uikits.popScene()
		end
	end)
end

function loading:init(b)
	if b then
		self._progress = uikits.child(self._root,ui.PROGREloading)
		print("progress = "..tostring(self._progress))
		self._max_step = 10
		self._step = 0
		self:next_step()
		self:login()
		login.load_name()
		--[[
		local count = 1
		uikits.delay_call(self._root,
			function(dt)
				self._progress:setPercent(count*10)
				if count < 11 then
					count = count+1
					return true
				else
					uikits.replaceScene(require "calc/mainui".create())
				end
			end,0.05)
		--]]
	end
end

function loading:release()
end

return loading