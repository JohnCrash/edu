local kits = require "kits"
local uikits = require "uikits"
local cache = require "cache"
local hitconfig = require 'hitmouse/hitconfig'
local gradeview = require 'hitmouse/gradeview'
local global = require "hitmouse/global"

local ui = {
	TEA_FILE = 'hitmouse/xiaozhang.json',
	TEA_FILE_3_4 = 'hitmouse/xiaozhang43.json',

	STU_FILE = 'hitmouse/bishai.json',
	STU_FILE_3_4 = 'hitmouse/bishai43.json',
	
	VIEW_GRADE_SRC = 'nj',
	TXT_GRADE_OPEN = 'w2',
	TXT_GRADE_CLOSE = 'wen',
	
	TXT_HAS_MATCH = 'xiao/w2',
	TXT_NO_MATCH = 'xiao/wen',

	VIEW_CHANGE_CLASS = 'ding/change_class',
	BUTTON_LEFT = 'ding/change_class/zuo',
	BUTTON_RIGHT = 'ding/change_class/you',
	TXT_SCHOOL_NAME = 'ding/change_class/school_name',

	BUTTON_QUIT  = 'ding/fan',
}

local matchview = class("matchview")
matchview.__index = matchview

function matchview.create(arg)
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),matchview)
	
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

function matchview:show_match_list()
	self.is_has_match = false
	for i=1,9 do
		local match_enable = 0
		if self.match_list_data[i].enable == 1 and self.match_list_data[i].enter_number >0 then
			match_enable = 1
		end
		local but_grade = uikits.child(self._matchview,ui.VIEW_GRADE_SRC..i)
		local txt_grade_open = uikits.child(but_grade,ui.TXT_GRADE_OPEN)
		local txt_grade_close = uikits.child(but_grade,ui.TXT_GRADE_CLOSE)
		but_grade.block_id = self.match_list_data[i].road_block_id
		but_grade.enable = self.match_list_data[i].enable
		but_grade.match_id = self.match_list_data[i].match_id
		but_grade.match_name = self.match_list_data[i].match_name
		but_grade.user_rank = self.match_list_data[i].rank
		but_grade.match_enable = match_enable
		if self.match_list_data[i].enable == 1 then
			txt_grade_open:setVisible(true)
			txt_grade_close:setVisible(false)
			self.is_has_match = true
		--	but_grade:setEnabled(true)
			but_grade:setBright(true)
		--	but_grade:setTouchEnabled(true)
		else
		--	but_grade:setEnabled(false)
			but_grade:setBright(false)
		--	but_grade:setTouchEnabled(false)	
			txt_grade_open:setVisible(false)
			txt_grade_close:setVisible(true)			
		end
		uikits.event(but_grade,	
			function(sender,eventType)	
				local scene_next = gradeview.create(sender.block_id,sender.enable,sender.match_id,sender.user_rank,sender.match_name,sender.match_enable)
				uikits.pushScene(scene_next)	
			end,"click")
	end
	local txt_has_match = uikits.child(self._matchview,ui.TXT_HAS_MATCH)
	local txt_no_match = uikits.child(self._matchview,ui.TXT_NO_MATCH)
	if self.is_has_match == true then
		txt_has_match:setVisible(true)
		txt_no_match:setVisible(false)			
	else
		txt_has_match:setVisible(false)
		txt_no_match:setVisible(true)			
	end
end

function matchview:get_match_list()
	local send_data = {}
	if self.id_flag == hitconfig.ID_FLAG_PAR then
		send_data.v1 = self.cur_school_info.school_id
		send_data.v2 = self.cur_school_info.user_id
	else
		send_data.v1 = 0
		send_data.v2 = 0
	end
	hitconfig.post_data(self._matchview,'get_match_list',send_data,function(t,v)
		if t and t == 200 then
--[[			if v and type(v) == 'table' then
				hitconfig.logTable(v)
			else
				print('v::::::::'..v)
			end--]]
			self.match_list_data = v
			self:show_match_list()
		else
--[[			hitconfig.messagebox(self._matchview,hitconfig.NETWORK_ERROR,function(e)
				if e == hitconfig.OK then
					
				else
					
				end
			end)	--]]
			hitconfig.messagebox(self._matchview,hitconfig.DIY_MSG,function(e)
				if e == hitconfig.RETRY then
					self:get_match_list()
				else
					uikits.popScene()
				end
			end,v)								
		end
	end)
end

function matchview:init()
	if uikits.get_factor() == uikits.FACTOR_9_16 then
		uikits.initDR{width=1920,height=1080}
	else
		uikits.initDR{width=1440,height=1080}
	end
	self.id_flag = hitconfig.get_id_flag()
	if self.id_flag == hitconfig.ID_FLAG_STU or self.id_flag == hitconfig.ID_FLAG_TEA or self.id_flag == hitconfig.ID_FLAG_PAR then
		self._matchview = uikits.fromJson{file_9_16=ui.STU_FILE,file_3_4=ui.STU_FILE_3_4}	

		local view_change_class = uikits.child(self._matchview,ui.VIEW_CHANGE_CLASS)
		local txt_school_name = uikits.child(self._matchview,ui.TXT_SCHOOL_NAME)
		view_change_class:setVisible(false)
		if self.id_flag == hitconfig.ID_FLAG_PAR then
			self.child_info = global.getChildInfo()
			if self.child_info and self.child_info.v2 and #self.child_info.v2 > 1 then
				hitconfig.logTable(child_info)
				view_change_class:setVisible(true)
				self.cur_school_info = hitconfig.get_school_info()
				if self.cur_school_info then
					for i=1,#self.child_info.v2 do
						if self.cur_school_info == self.child_info.v2[i] then
							self.child_index = i
							break
						end
					end
				else
					self.child_index = 1
					self.cur_school_info = self.child_info.v2[self.child_index]			
				end
			elseif self.child_info and self.child_info.v2 and #self.child_info.v2 == 1 then
				self.child_index = 0
				self.cur_school_info = self.child_info.v2[1]
			else
				kits.log("ERROR get_childinfo failed~")
			end
			txt_school_name:setString(self.cur_school_info.user_name)
			hitconfig.set_school_info(self.cur_school_info)	
		end	
		
		local but_left = uikits.child(self._matchview,ui.BUTTON_LEFT)
		uikits.event(but_left,	
		function(sender,eventType)	
			if self.child_index == 1 then
				self.child_index = #self.child_info.v2
			else
				self.child_index = self.child_index - 1
			end
			self.cur_school_info = self.child_info.v2[self.child_index]
			local txt_school_name = uikits.child(self._matchview,ui.TXT_SCHOOL_NAME)
			txt_school_name:setString(self.cur_school_info.user_name)
			hitconfig.set_school_info(self.cur_school_info)	
			self:get_match_list()
		end,"click")

		local but_right = uikits.child(self._matchview,ui.BUTTON_RIGHT)
		uikits.event(but_right,	
		function(sender,eventType)	
			if self.child_index == #self.child_info.v2 then
				self.child_index = 1
			else
				self.child_index = self.child_index + 1
			end
			self.cur_school_info = self.child_info.v2[self.child_index]
			local txt_school_name = uikits.child(self._matchview,ui.TXT_SCHOOL_NAME)
			txt_school_name:setString(self.cur_school_info.user_name)
			hitconfig.set_school_info(self.cur_school_info)		
			self:get_match_list()
		end,"click")	
		
	else
		self._matchview = uikits.fromJson{file_9_16=ui.TEA_FILE,file_3_4=ui.TEA_FILE_3_4}		
	end
	self:addChild(self._matchview)
	
	self:get_match_list()
	
--[[	hitconfig.set_base_rid()
	self:login()--]]
	local but_quit = uikits.child(self._matchview,ui.BUTTON_QUIT)
	uikits.event(but_quit,	
		function(sender,eventType)	
			uikits.popScene()
		end,"click")
end

function matchview:release()
	
end

return matchview