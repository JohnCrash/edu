local kits = require "kits"
local uikits = require "uikits"
local http = require "han/http"
local json = require "json-c"

require "AudioEngine"

local _email_num = 4

local function setMailNum(num)
	_email_num = num
end

local function getMailNum()
	return _email_num
end

local function initEmailFlag(parent,email,flag,num,setup,isreplace)
	if email then
		local e = uikits.child(parent,email)
		if e then
			uikits.event(e,function()
				if isreplace then
					uikits.replaceScene(require "calc/notic".create())
				else
					uikits.pushScene(require "calc/notic".create())
				end
			end)
		end
	end
	local f = uikits.child(parent,flag)
	local n = uikits.child(parent,num)
	print("main num :"..tostring(_email_num))
	if f and n then
		if _email_num <= 0 then
			f:setVisible(false)
			n:setVisible(false)
		else
			f:setVisible(true)
			n:setVisible(true)		
			n:setString(tostring(_email_num))
		end
	else
		kits.log("ERROR initEmailFlag f = "..tostring(f).." n = "..tostring(n))
	end
	if setup then
		local s = uikits.child(parent,setup)
		if s then
			uikits.event(s,function()
				if isreplace then
					uikits.replaceScene(require "calc/setup".create())
				else
					uikits.pushScene(require "calc/setup".create())
				end
			end)
		end
	end
end

local function back(parent,idback)
	uikits.event(uikits.child(parent,idback),function(sender)
		uikits.popScene()
	end)
end

local function tab(parent,uitabs,func)
	local t = {}
	
	local function switchTab(i)
		if t[i] then
			for k,v in pairs(t) do
				v:setSelectedState(false)
			end
			if func then
				func(i)
			end
			t[i]:setSelectedState(true)
		end
	end
	
	for i,v in pairs(uitabs) do
		local item = uikits.child(parent,v)
		t[i] = item
		uikits.event(item,function()
			switchTab(i)
		end)
	end
	switchTab(1)
	return t
end

local function scroll(parent,list,item,tail,tailline)
	local s = uikits.scroll(parent,list,item)
	local old_relayout = s.relayout
	s.relayout = function(self,animation)
		old_relayout(self,animation)
		if tail and tailline and #self._list > 0 then
			for i,v in pairs(self._list) do
				uikits.child(v,tail):setVisible(false)
				uikits.child(v,tailline):setVisible(true)
			end
			local item = self._list[#self._list]
			uikits.child(item,tail):setVisible(true)
			uikits.child(item,tailline):setVisible(false)
		end
		self._item:setVisible(false)
	end
	return s
end

local function stop_music()
	if AudioEngine.isMusicPlaying () then
		AudioEngine.stopMusic()
	end
end

local music_type = nil
local MATCH_MUSIC_MAX = 1
local LEVEL_MUSIC_MAX = 1
local function play_music(isMatch)
	local name
	
	if music_type ~= isMatch then
		music_type = isMatch
		stop_music()
	elseif AudioEngine.isMusicPlaying () then
		return
	end
	local max_num
	if isMatch then
		max_num = MATCH_MUSIC_MAX
	else
		max_num = LEVEL_MUSIC_MAX
	end
	
	local idx = math.random(1,max_num)
	if idx <=max_num and idx >= 1 then
		name = 'calc/snd/BackGroundMusic'..idx..'.mp3'
	else
		return
	end
	AudioEngine.playMusic( name,true )
end

local _class = {
	[1] = {
		class_name = "一年级3班",
		class_id = 1, 
	},
	[2] = {
		class_name = "一年级4班",
		class_id = 2, 
	}	
}

local _config = {
	calc_mute = true,
	calc_audio = true,
	calc_left = false,
}

local debug_data = {
}

local function debug_interface(result,parent,module_id,post_data,condition,func,is_not_loading)
	local v = debug_data[module_id]
	if v then
		func(v)
		return 1
	else
		print("method "..tostring(module_id).." debug interface not  exist")
	end
end

--http.set_error_func( debug_interface )

local function getClass()
	return _class
end

local function setClass(t)
	_class = t
end
--返回知识点层次
local function getKP()
	return _kp
end

local function setKP(t)
	_kp = t
end

local function post_data(parent,method,data,condition,func,tryfunc,text,not_loading_circle)
	kits.log("INFO request :"..tostring(method))
	if debug_interface(nil,parent,method,data,condition,func,tryfunc,text,not_loading_circle) then
		return
	end
	http.post_data(parent,method,data,function(t,v)
		kits.log("INFO "..tostring(method).." response")
		http.logTable(v)
		if t and t==200 then
			local bb,msg = condition(v)
			if bb then
				func(v)
			else
				local err_info
				if not msg then
					err_info = "error "..tostring(method).." return:\n"..http.logString(v)
				else
					err_info = msg
				end
				http.messagebox(parent,http.DIY_MSG,function(e)
					if e == http.RETRY then
						if tryfunc then
							tryfunc()
						else
							kits.log("ERROR post_data "..tostring(method).." tryfunc = nil")
							uikits.popScene()
						end
					else
						uikits.popScene()
					end
				end,text or err_info)						
			end
		elseif tryfunc then
			http.messagebox(parent,http.DIY_MSG,function(e)
				if e == http.RETRY then
					tryfunc()
				else
					uikits.popScene()
				end
			end,v or "你的网络突然中断了\n请检查一下网络,然后重试一下!")				
		else
			kits.log("ERROR request "..tostring(method).." failed!")
		end
	end,not_loading_circle)
end

local _configure={}
local function set_game_configure(config)
	_configure = config
end
local function get_game_configure()
	return _configure
end

local _sp0
local _sp_limit
local _spv
local _set_time
local function get_max_sp()
	return _sp_limit
end
local function set_sp(sp0,sp_limit,spv)
	_sp0 = sp0
	_sp_limit = sp_limit
	_spv = spv
	_set_time = cc_clock()
end
local function get_sp()
	if _set_time then
		local sp = (cc_clock()-_set_time)*_spv+_sp0
		if sp>_sp_limit then
			return _sp_limit
		else
			return math.floor(sp)
		end
	else
		return -1
	end
end
local _level
local _exlevel
local function set_current_level(l,ex)
	_level = l
	_exlevel = ex
end
local function get_current_level()
	return _level,_exlevel
end
local _level_stars={[1]={},[2]={}}
local function get_level_star()
	return _level_stars
end
local function set_level_star(t,s)
	_level_stars[1] = t
	_level_stars[2] = s
--[[	if s and _level_stars[t] then
		for i=1,string.len(s) do
			local n = string.sub(s,i,i)
			table.insert(_level_stars[t],n)
		end
	end
--]]
end

local _levels_table = nil
local function get_levels()
	return _levels_table
end

local function set_levels(t)
	_levels_table = t
end

local _homework_notify_state
local function get_homework_state()
	return _homework_notify_state
end

local function set_homework_state(ns)
	_homework_notify_state = ns
end

local ui = {
	LOADINGLAYER = 'calc/jiaz.json',
}

local _loadingLayer = nil
local function showLoadingLayer()
	_loadingLayer = uikits.fromJson{file=ui.LOADINGLAYER}
	local Director = cc.Director:getInstance()
	if Director then
		local scene = Director:getRunningScene()
		if scene then
			scene:addChild(_loadingLayer,99999)
		end
	end
end

local function hideLoadingLayer()
	if _loadingLayer and cc_isobj(_loadingLayer) then
		_loadingLayer:removeFromParent()
		_loadingLayer = nil
	end
end

local function extend(target,_class)
    local t = tolua.getpeer(target)
    if not t then
        t = {}
        tolua.setpeer(target, t)
    end
    setmetatable(t, _class)
    return target
end

local function SceneClass(name,ui)
	local clas = class( name )
	clas.__index = clas
	clas.init=function(self)
	end
	clas.release=function(self)
	end
	clas.create=function(arg)
		local scene = cc.Scene:create()
		local layer = extend(cc.Layer:create(),clas)
		scene:addChild(layer)
		layer._arg = arg
		local function onNodeEvent(event)
			if "enter" == event then
				local isfirst
				if ui then
					if ui.designWidth and ui.designHeight then
						if ui.designWidth > ui.designHeight then
							if uikits.get_factor() == uikits.FACTOR_9_16 then
								layer._ss = cc.size(ui.designWidth,ui.designHeight)
							else
								layer._ss = cc.size(ui.designHeight*4/3,ui.designHeight)
							end
						else
							if cc_getUIOrientation() ~= 2 then
								local platform = CCApplication:getInstance():getTargetPlatform()
								if platform == kTargetWindows then							
									cc_setUIOrientation(2)
								end
							end
							if uikits.get_factor() == uikits.FACTOR_9_16 then
								layer._ss = cc.size(ui.designWidth,ui.designHeight)
							else
								layer._ss = cc.size(ui.designWidth,ui.designWidth*4/3)
							end						
						end
						uikits.initDR{width=layer._ss.width,height=layer._ss.height,mode=ui.designMode or cc.ResolutionPolicy.EXACT_FIT}
					end
					if not layer._root and ui.FILE and ui.FILE_3_4 then
						layer._root = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE_3_4}
						layer:addChild(layer._root)
						isfirst = true
					end
				end
				layer:init(isfirst)
			elseif "exit" == event then
				layer:release()
			end
		end	
		layer:registerScriptHandler(onNodeEvent)
		return scene		
	end
	return clas
end

local function time_to_string_simple( d,expet_sec )
	if d then
		local day = math.floor( d /(3600*24) )
		local hours = math.floor( (d - day*3600*24)/3600 )
		local mins = math.floor( (d - day*3600*24 - hours*3600)/60 )
		local sec = math.floor( d - day*3600*24 - hours*3600-mins*60 )
		if day > 0 then
			return day..'天'..hours..'小时'
		elseif hours > 0 then
			return hours..'小时'..mins..'分钟'
		elseif mins > 0 then
			return mins..'分'
		elseif sec >= 0 then
			return sec..'秒'
		end
	end
	return '-'
end

local function tohex(c)
	local s = string.format("%X",c)
	if string.len(s)==1 then
		s = '0'..s
	end
	return s
end

local hexc = {
	['A'] = 10,
	['B'] = 11,
	['C'] = 12,
	['D'] = 13,
	['E'] = 14,
	['F'] = 15,
	
	['a'] = 10,
	['b'] = 11,
	['c'] = 12,
	['d'] = 13,
	['e'] = 14,
	['f'] = 15,	
	
	['0'] = 0,
	['1'] = 1,
	['2'] = 2,
	['3'] = 3,
	['4'] = 4,
	['5'] = 5,		
	['6'] = 6,
	['7'] = 7,
	['8'] = 8,
	['9'] = 9,
}
local function tochar(c1,c2)
	if c1 and c2 and hexc[c1] and hexc[c2] then
		return string.char(hexc[c1]*16+hexc[c2])
	end
end

local function crypt_encode(buf)
	local l = string.len(buf)
	local t = {}
	for i=1,l do
		table.insert(t,tohex(string.byte(buf,i,i)))
	end
	return table.concat(t)
end

local function crypt_decode(buf)
	local l = string.len(buf)
	local t = {}
	for i=1,l,2 do
		local c = tochar(string.sub(buf,i,i),string.sub(buf,i+1,i+1))
		if c then
			table.insert(t,c)
		else
			print("crypt_decode failed location i="..tostring(i))
		end
	end
	return table.concat(t)
end

local _child_info

local function setChildInfo(ci)
	_child_info = ci or {}
end

local function getChildInfo()
	return _child_info or {}
end

return {
	time_to_string_simple = time_to_string_simple,
	SceneClass = SceneClass,
	setMailNum = setMailNum,
	getMailNum = getMailNum,
	initEmailFlag = initEmailFlag,
	back = back,
	tab = tab,
	scroll = scroll,
	play = play_music,
	stop = stop_music,
	getKP = getKP,
	setKP = setKP,
	getClass = getClass,
	setClass = setClass,
	post_data = post_data,
	set_game_configure = set_game_configure,
	get_game_configure = get_game_configure,
	set_sp = set_sp,
	get_sp = get_sp,
	get_max_sp = get_max_sp,
	get_current_level = get_current_level,
	set_current_level = set_current_level,
	get_level_star = get_level_star,
	set_level_star = set_level_star,
	get_levels = get_levels,
	set_levels = set_levels,
	get_homework_state = get_homework_state,
	set_homework_state = set_homework_state,
	showLoadingLayer = showLoadingLayer,
	hideLoadingLayer = hideLoadingLayer,
	crypt_encode = crypt_encode,
	crypt_decode = crypt_decode,
	tohex = tohex,
	setChildInfo = setChildInfo,
	getChildInfo = getChildInfo,
}
