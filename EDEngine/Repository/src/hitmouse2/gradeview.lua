local kits = require "kits"
local uikits = require "uikits"
local cache = require "cache"
local hitconfig = require 'hitmouse2/hitconfig'
local rankview = require 'hitmouse2/rankview'
local battle = require "hitmouse2/battle"


local ui = {
	TEA_FILE = 'hitmouse2/xzjinru.json',
	TEA_FILE_3_4 = 'hitmouse2/xzjinru43.json',

	STU_FILE = 'hitmouse2/jinbishai.json',
	STU_FILE_3_4 = 'hitmouse2/jinbishai43.json',
	
	VIEW_ALL_HISTORY = 'gun',
	VIEW_CUR_MATCH = 'gun/xinde',
	VIEW_HIS_MATCH_SRC = 'gun/bisai1',
	
	TXT_MATCH_NAME = 'wen',
	TXT_MATCH_RANK = 'ph',
	BUTTON_MATCH_JOIN = 'jinru',
	TXT_MATCH_TIP = 'w3',
	
	TXT_TIP_HAS_MATCH = 'w2',
	TXT_TIP_NO_MATCH = 'w3',
	BUTTON_OPEN_MATCH = 'kaiguan',
	
	BUTTON_MATCH_DETAIL = 'info',
	
	BUTTON_DETAIL  = 'xiangq',
	TXT_PEOPLE_NUM = 'sj',
	TXT_OPEN_TIME = 'mz',
	TXT_GRADE_NAME = 'cs',
	
	BUTTON_QUIT  = 'ding/fan',
}

local gradeview = class("gradeview")
gradeview.__index = gradeview

function gradeview.create(block_id,enable,match_id,match_name,child_id)
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),gradeview)
	layer.block_id = block_id
	layer.enable = enable
	layer.match_id = match_id
	layer.match_rank = 0
	layer.match_name = match_name
	layer.match_enable = 0
	if child_id then
		layer.child_id = child_id
	end
	
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

function gradeview:show_history_list()
	local is_show_cur_match = true
	local view_all_history = uikits.child(self._gradeview,ui.VIEW_ALL_HISTORY)
	local view_cur_match = uikits.child(self._gradeview,ui.VIEW_CUR_MATCH)
	local view_his_match_src = uikits.child(self._gradeview,ui.VIEW_HIS_MATCH_SRC)
	local but_match_detail = uikits.child(view_cur_match,ui.BUTTON_MATCH_DETAIL)
	uikits.event(but_match_detail,	
		function(sender,eventType)
			local send_data = {}
			send_data.v1 = self.block_id
			send_data.v2 = 2
			send_data.v3 = 1
			send_data.v4 = 100
			if self.id_flag == hitconfig.ID_FLAG_PAR then
				local cur_school_info = hitconfig.get_school_info()
				send_data.v5 = tostring(cur_school_info.user_id)
			else
				send_data.v5 = '0'
			end		
			hitconfig.post_data(self._gradeview,'road_block_rank',send_data,function(t,v)
							kits.logTable(v)
							if t and t == 200 then
								uikits.pushScene( rankview.create(v.v1,sender.open_time,self.match_name) )
							else
--[[								hitconfig.messagebox(self._gradeview,hitconfig.NETWORK_ERROR,function(e)
									if e == hitconfig.OK then
									
									else
										
									end
								end)	--]]
								hitconfig.messagebox(self._gradeview,hitconfig.DIY_MSG,function(e)
									if e == hitconfig.RETRY then
										self.show_history_list()
									else
										uikits.popScene()
									end
								end,v)								
							end
						end)
	end)	
--[[	if self.id_flag == hitconfig.ID_FLAG_TEA then
		local but_match_join = uikits.child(view_cur_match,ui.BUTTON_MATCH_JOIN)
		local txt_match_tip = uikits.child(view_cur_match,ui.TXT_MATCH_TIP)
		view_cur_match:setVisible(true)		
		but_match_join:setEnabled(false)
		but_match_join:setBright(false)
		but_match_join:setTouchEnabled(false)	
		txt_match_tip:setVisible(false)	
		if self.enable == 1 then
			but_match_detail:setEnabled(true)
			but_match_detail:setBright(true)
			but_match_detail:setTouchEnabled(true)
		else
			but_match_detail:setEnabled(false)
			but_match_detail:setBright(false)
			but_match_detail:setTouchEnabled(false)	
		end	
			
	else--]]if self.id_flag == hitconfig.ID_FLAG_STU or self.id_flag == hitconfig.ID_FLAG_PAR or self.id_flag == hitconfig.ID_FLAG_TEA then
		local but_match_join = uikits.child(view_cur_match,ui.BUTTON_MATCH_JOIN)
		view_cur_match:setVisible(true)
		local txt_match_name = uikits.child(view_cur_match,ui.TXT_MATCH_NAME)
		local txt_match_rank = uikits.child(view_cur_match,ui.TXT_MATCH_RANK)
		local txt_match_tip = uikits.child(view_cur_match,ui.TXT_MATCH_TIP)
		txt_match_name:setString(self.match_name)
		txt_match_rank:setString(self.match_rank)
		if self.enable == 1 then
			if self.match_enable == 1 then
				but_match_join:setEnabled(true)
				but_match_join:setBright(true)
				but_match_join:setTouchEnabled(true)
				txt_match_tip:setVisible(false)
				but_match_detail:setEnabled(true)
				but_match_detail:setBright(true)
				but_match_detail:setTouchEnabled(true)
			else
				but_match_join:setEnabled(false)
				but_match_join:setBright(false)
				but_match_join:setTouchEnabled(false)	
				txt_match_tip:setVisible(false)	
				but_match_detail:setEnabled(true)
				but_match_detail:setBright(true)
				but_match_detail:setTouchEnabled(true)	
			end
		else
			but_match_join:setEnabled(false)
			but_match_join:setBright(false)
			but_match_join:setTouchEnabled(false)	
			txt_match_tip:setVisible(true)	
			but_match_detail:setEnabled(false)
			but_match_detail:setBright(false)
			but_match_detail:setTouchEnabled(false)	
			--view_cur_match:setVisible(false)
			--is_show_cur_match = false
		end
		uikits.event(but_match_join,	
			function(sender,eventType)
			local send_data = {v1=self.block_id,v2=2,v3=0,v4=false}
			if self.id_flag == hitconfig.ID_FLAG_PAR then
				local cur_school_info = hitconfig.get_school_info()
				if cur_school_info and cur_school_info.school_id then
					send_data.v5 = cur_school_info.school_id
				else
					send_data.v5 = 0
				end	
			else
				send_data.v5 = 0
			end
			hitconfig.post_data(self._gradeview,'get_new_match',send_data,function(t,v)
				if t and t==200 and v then
					hitconfig.logTable(v,1)
					if v.v1 then
						v.v5.threshold = v.v6
						v.v5.condition = v.v6
						v.v5.type = 2
						v.v5.level = self.block_id
						uikits.replaceScene(battle.create(v.v5))			
					else
						kits.log("self._root = "..tostring(self._root))
						kits.log("self._gradeview = "..tostring(self._gradeview))
						hitconfig.messagebox(self._gradeview,hitconfig.OK_MSG,function(e)
						end,tostring(v.v2 or 'get_new_match return v.v2 = nil'))
					end
					--[[
					uikits.replaceScene(battle.create{
							level = self.block_id or 1,
							time_limit = v.times or 10,
							rand = v.road_radom or 0,
							diff1 = v.diffcult_low or 0,
							diff2 = v.diffcult_up or 0,
							signle = v.question_amount or 10,
							dual = 0,
							condition = v.pass_condition or 60,
							type= 2,
						})
						--]]
				else
					hitconfig.messagebox(self._gradeview,hitconfig.DIY_MSG,function(e)
						if e == hitconfig.RETRY then
							self.show_history_list()
						else
							uikits.popScene()
						end
					end,v)	
				end
			end)
		end)
	else	
		view_cur_match:setVisible(true)
		local txt_match_name = uikits.child(view_cur_match,ui.TXT_MATCH_NAME)
		txt_match_name:setString(self.match_name)
		local txt_has_match = uikits.child(view_cur_match,ui.TXT_TIP_HAS_MATCH)
		local txt_no_match = uikits.child(view_cur_match,ui.TXT_TIP_NO_MATCH)
		local but_open_match = uikits.child(view_cur_match,ui.BUTTON_OPEN_MATCH)
		local but_match_join = uikits.child(view_cur_match,ui.BUTTON_MATCH_JOIN)
		if self.enable == 1 then
			txt_has_match:setVisible(true)
			txt_no_match:setVisible(false)
			but_open_match:setSelectedState(false)
			but_match_detail:setEnabled(true)
			but_match_detail:setBright(true)
			but_match_detail:setTouchEnabled(true)	
			but_match_join:setEnabled(true)
			but_match_join:setBright(true)
			but_match_join:setTouchEnabled(true)	
		else
			txt_has_match:setVisible(false)
			txt_no_match:setVisible(true)	
			but_open_match:setSelectedState(true)
			but_match_detail:setEnabled(false)
			but_match_detail:setBright(false)
			but_match_detail:setTouchEnabled(false)	
			but_match_join:setEnabled(false)
			but_match_join:setBright(false)
			but_match_join:setTouchEnabled(false)	
		end
		uikits.event(but_open_match,	
			function(sender,eventType)
				local send_data = {}
				send_data.v1 = self.match_id
				if self.enable == 1 then
					send_data.v2 = 0
				else
					send_data.v2 = 1
				end
				hitconfig.post_data(self._gradeview,'open_road_block',send_data,function(t,v)
								if t and t == 200 then
									if v.v1 == true then
										if self.enable == 1 then
											self.enable = 0
											txt_has_match:setVisible(false)
											txt_no_match:setVisible(true)	
											but_match_detail:setEnabled(false)
											but_match_detail:setBright(false)
											but_match_detail:setTouchEnabled(false)	
											but_match_join:setEnabled(false)
											but_match_join:setBright(false)
											but_match_join:setTouchEnabled(false)	
											--but_open_match:setSelectedState(false)
										else
											self.enable = 1
											txt_has_match:setVisible(true)
											txt_no_match:setVisible(false)
											but_match_detail:setEnabled(true)
											but_match_detail:setBright(true)
											but_match_detail:setTouchEnabled(true)	
											but_match_join:setEnabled(true)
											but_match_join:setBright(true)
											but_match_join:setTouchEnabled(true)
											--but_open_match:setSelectedState(true)
										end
									else
										if self.enable == 1 then
											but_open_match:setSelectedState(false)
										else
											but_open_match:setSelectedState(true)
										end										
									end
								else
									hitconfig.messagebox(self._gradeview,hitconfig.DIY_MSG,function(e)
										if e == hitconfig.RETRY then
											self.show_history_list()
										else
											uikits.popScene()
										end
									end,v)							
								end
							end)
		end)
		uikits.event(but_match_join,	
			function(sender,eventType)
			--如果是校长或者其他管理者不能进入游戏
			if hitconfig.get_id_flag()==hitconfig.ID_FLAG_SCH then
				hitconfig.messagebox(self._gradeview,hitconfig.OK_MSG,function(e)
				end,"管理者不能进行比赛。")
			else
			local send_data = {v1=self.block_id,v2=2}
			send_data.v3 = 0
			hitconfig.post_data(self._gradeview,'get_match',send_data,function(t,v)
				if t and t==200 then
					v.v5.threshold = v.v6
					v.v5.condition = v.v6
					v.v5.type = 1
					uikits.replaceScene(battle.create(v.v5))
--[[					
					uikits.replaceScene(battle.create{
							level = self.block_id or 1,
							time_limit = v.times or 10,
							rand = v.road_radom or 0,
							diff1 = v.diffcult_low or 0,
							diff2 = v.diffcult_up or 0,
							signle = v.question_amount or 10,
							dual = 0,
							condition = v.pass_condition or 60,
							type= 2,
						})
--]]						
				else
					hitconfig.messagebox(self._gradeview,hitconfig.DIY_MSG,function(e)
						if e == hitconfig.RETRY then
							self.show_history_list()
						else
							uikits.popScene()
						end
					end,v)	
				end
			end)
			end
		end)
	end
	local view_space = 10
	local size_all = view_all_history:getContentSize()
	local size_cur_match = view_cur_match:getContentSize()
	local size_his_match_src = view_his_match_src:getContentSize()
	local scroll_size = view_all_history:getInnerContainerSize()
	local all_height
	if is_show_cur_match == true then
		all_height = size_cur_match.height + (size_his_match_src.height+view_space)*(#self.history_list)
	else
		all_height = (size_his_match_src.height+view_space)*(#self.history_list)
	end
	if all_height > size_all.height then
		scroll_size.height = all_height
		view_cur_match:setPositionY(scroll_size.height-size_cur_match.height)
	end
	view_all_history:setInnerContainerSize(scroll_size)	
	local pos_y_start
	if is_show_cur_match == true then
		pos_y_start = scroll_size.height - size_cur_match.height - size_his_match_src.height
	else
		pos_y_start = scroll_size.height - size_his_match_src.height
	end	
	view_his_match_src:setVisible(false)	

	for i=1 , #self.history_list do
		local cur_pro = view_his_match_src:clone()
		cur_pro:setVisible(true)
		cur_pro:setPositionY(pos_y_start-(i-1)*(size_his_match_src.height+view_space))
		view_all_history:addChild(cur_pro,1,10000+i)

		local txt_people_num = uikits.child(cur_pro,ui.TXT_PEOPLE_NUM)
		local txt_open_time = uikits.child(cur_pro,ui.TXT_OPEN_TIME)
		local txt_grade_name = uikits.child(cur_pro,ui.TXT_GRADE_NAME)
		
		txt_people_num:setString(self.history_list[i].Users..'人')
		txt_open_time:setString(self.history_list[i].match_time)
		txt_grade_name:setString(self.match_name)
		
		local but_detail = uikits.child(cur_pro,ui.BUTTON_DETAIL)
		but_detail.road_block_id = self.history_list[i].road_block_id
		but_detail.open_time = self.history_list[i].match_time
		but_detail.user_num = self.history_list[i].Users
		uikits.event(but_detail,	
			function(sender,eventType)
				if sender.user_num == 0 then
--[[					hitconfig.messagebox(self._gradeview,hitconfig.DIY_MSG,function(e)
						if e == hitconfig.OK then
						
						else
							
						end
					end)	--]]
					hitconfig.messagebox(self._gradeview,hitconfig.DIY_MSG,function(e)
					end,'没有参与比赛的人')		
					return
				end
				local send_data = {}
				send_data.v1 = sender.road_block_id
				send_data.v2 = 2
				send_data.v3 = 1
				send_data.v4 = 100
--				send_data.v5 = ''
				if self.id_flag == hitconfig.ID_FLAG_PAR then
					local cur_school_info = hitconfig.get_school_info()
					send_data.v5 = tostring(cur_school_info.user_id)
				else
					send_data.v5 = '0'
				end				
				hitconfig.post_data(self._gradeview,'road_block_rank',send_data,function(t,v)
								if t and t == 200 then
									uikits.pushScene( rankview.create(v.v1,sender.open_time,self.match_name) )
								else
									hitconfig.messagebox(self._gradeview,hitconfig.DIY_MSG,function(e)
										if e == hitconfig.RETRY then
											self.show_history_list()
										else
											uikits.popScene()
										end
									end,v)							
								end
							end)
				--uikits.pushScene( resetpwview.create() )
		end)
	end
end

function gradeview:get_his_list()
	local send_data = {}
	send_data.v1 = self.match_id
	if self.id_flag == hitconfig.ID_FLAG_PAR then
		local cur_school_info = hitconfig.get_school_info()
		send_data.v2 = cur_school_info.school_id
		send_data.v3 = self.child_id
	else
		send_data.v2 = 0
		send_data.v3 = 0
	end
	hitconfig.post_data(self._gradeview,'get_match_history',send_data,function(t,v)
					if t and t == 200 then
						self.history_list = v.matchhistory
						self.match_rank = v.rank
						if self.enable == 1 and v.enter_number >0 then
							self.match_enable = 1
						end
						self:show_history_list()
					else
						hitconfig.messagebox(self._gradeview,hitconfig.DIY_MSG,function(e)
							if e == hitconfig.RETRY then
								self.get_his_list()
							else
								uikits.popScene()
							end
						end,v)							
					end
				end)
end

function gradeview:init()
	if uikits.get_factor() == uikits.FACTOR_9_16 then
		uikits.initDR{width=1920,height=1080}
	else
		uikits.initDR{width=1440,height=1080}
	end
	self.id_flag = hitconfig.get_id_flag()
	print('self.id_flag:::::::'..self.id_flag)
	if self.id_flag == hitconfig.ID_FLAG_STU or self.id_flag == hitconfig.ID_FLAG_TEA or self.id_flag == hitconfig.ID_FLAG_PAR then
		self._gradeview = uikits.fromJson{file_9_16=ui.STU_FILE,file_3_4=ui.STU_FILE_3_4}	
	else
		self._gradeview = uikits.fromJson{file_9_16=ui.TEA_FILE,file_3_4=ui.TEA_FILE_3_4}		
	end
	self:addChild(self._gradeview)

	self:get_his_list()
	local but_quit = uikits.child(self._gradeview,ui.BUTTON_QUIT)
	uikits.event(but_quit,	
		function(sender,eventType)	
			uikits.popScene()
		end,"click")		
end

function gradeview:release()
	
end

return gradeview