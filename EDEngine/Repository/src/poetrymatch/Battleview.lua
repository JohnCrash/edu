local uikits = require "uikits"
local kits = require "kits"
local json = require "json-c"
local login = require "login"
local cache = require "cache"
local messagebox = require "messagebox"
local person_info = require "poetrymatch/Person_info"

local Battleview = class("Battleview")
Battleview.__index = Battleview
local ui = {
	Battleview_FILE = 'poetrymatch/duizhan.json',
	Battleview_FILE_3_4 = 'poetrymatch/duizhan.json',
	
	BUTTON_SEARCH = 'pipei',
	VIEW_SEARCH_RES = 'duis',
	BUTTON_RESEARCH = 'duis/huan',
	TXT_TIME = 'duis/20s',
	
	BUTTON_QUIT = 'xinxi/fanhui',
	BUTTON_JIANG = 'xinxi/jiang',
}

local function loadArmature( name )
		ccs.ArmatureDataManager:getInstance():removeArmatureFileInfo(name)
		ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(name)	
end

function create()
	local scene = cc.Scene:create()				
	local cur_layer = uikits.extend(cc.Layer:create(),Battleview)		
	
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

function Battleview:getdatabyurl()

	cache.request_json( get_uesr_info_url,function(t)
		if t and type(t)=='table' then
			if 	t.result ~= 0 then				
				print(t.result.." : "..t.message)			
			else
				if t.uig[1].user_role == 1 then	--xuesheng
					login.set_uid_type(login.STUDENT)
					local scene_next = errortitleview.create(t.uig[1].uname)		
					--uikits.pushScene(scene_next)						
					cc.Director:getInstance():replaceScene(scene_next)	
				elseif t.uig[1].user_role == 2 then	--jiazhang
					login.set_uid_type(login.PARENT)
					self:getdatabyparent()
				elseif t.uig[1].user_role == 3 then	--laoshi
					login.set_uid_type(login.TEACHER)
					self:showteacherview()		
				end
			end	
		else
			--既没有网络也没有缓冲
			messagebox.open(self,function(e)
				if e == messagebox.TRY then
					self:init()
				elseif e == messagebox.CLOSE then
					uikits.popScene()
				end
			end,messagebox.RETRY)	
		end
	end,'N')
end

local schedulerEntry
local scheduler = cc.Director:getInstance():getScheduler()

function Battleview:show_search_res()	
	
end

function Battleview:init_gui()	
	local view_search_res = uikits.child(self._Battleview,ui.VIEW_SEARCH_RES)
	view_search_res:setVisible(false)
	local but_re_search = uikits.child(self._Battleview,ui.BUTTON_RESEARCH)	
	local txt_time = uikits.child(self._Battleview,ui.TXT_TIME)	
	local choose_time
	local but_search = uikits.child(self._Battleview,ui.BUTTON_SEARCH)	
	
	local function timer_update(time)
		txt_time:setString(choose_time)
		choose_time = choose_time -1
		if schedulerEntry and choose_time < 0 then
			view_search_res:setVisible(false)
			but_search:setVisible(true)			
			scheduler:unscheduleScriptEntry(schedulerEntry)
			schedulerEntry = nil
		end
	end	
	
	uikits.event(but_re_search,	
		function(sender,eventType)	
			self:show_search_res()
			choose_time = 10
			txt_time:setString(choose_time)
			choose_time = choose_time -1
			if not schedulerEntry then
				schedulerEntry = scheduler:scheduleScriptFunc(timer_update,1,false)
			end
		end,"click")	
		
	uikits.event(but_search,	
		function(sender,eventType)	
			self:show_search_res()
			view_search_res:setVisible(true)
			sender:setVisible(false)
			choose_time = 10
			txt_time:setString(choose_time)
			choose_time = choose_time -1
			if not schedulerEntry then
				schedulerEntry = scheduler:scheduleScriptFunc(timer_update,1,false)
			end
		end,"click")	
	
end

function Battleview:init()	
	if uikits.get_factor() == uikits.FACTOR_9_16 then
		uikits.initDR{width=1920,height=1080}
	else
		uikits.initDR{width=1440,height=1080}
	end
	self._Battleview = uikits.fromJson{file_9_16=ui.Battleview_FILE,file_3_4=ui.Battleview_FILE_3_4}
	self:addChild(self._Battleview)
	
	local but_quit = uikits.child(self._Battleview,ui.BUTTON_QUIT)
	uikits.event(but_quit,	
		function(sender,eventType)	
			uikits.popScene()
		end,"click")
		
	local but_jiang = uikits.child(self._Battleview,ui.BUTTON_JIANG)
	uikits.event(but_jiang,	
		function(sender,eventType)	
		
		end,"click")
--	self:getdatabyurl()
--	local loadbox = Battleviewbox.open(self)
--	local scene_next = WrongSubjectList.create()								
--	cc.Director:getInstance():replaceScene(scene_next)	
	self:init_gui()
end

function Battleview:release()

end
return {
create = create,
}