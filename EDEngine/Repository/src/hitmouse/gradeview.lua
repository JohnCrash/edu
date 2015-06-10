local kits = require "kits"
local uikits = require "uikits"
local cache = require "cache"
local hitconfig = require 'hitmouse/hitconfig'
local rankview = require 'hitmouse/rankview'
local battle = require "hitmouse/battle"

local ui = {
	TEA_FILE = 'hitmouse/xzjinru.json',
	TEA_FILE_3_4 = 'hitmouse/xzjinru43.json',

	STU_FILE = 'hitmouse/jinbishai.json',
	STU_FILE_3_4 = 'hitmouse/jinbishai43.json',
	
	VIEW_ALL_HISTORY = 'gun',
	VIEW_CUR_MATCH = 'gun/xinde',
	VIEW_HIS_MATCH_SRC = 'gun/bisai1',
	
	TXT_MATCH_NAME = 'wen',
	TXT_MATCH_RANK = 'ph',
	BUTTON_MATCH_JOIN = 'jinru',
	TXT_MATCH_TIP = 'tip',
	
	TXT_TIP_HAS_MATCH = 'w2',
	TXT_TIP_NO_MATCH = 'w3',
	BUTTON_OPEN_MATCH = 'kaiguan',
	
	BUTTON_DETAIL  = 'xiangq',
	TXT_PEOPLE_NUM = 'sj',
	TXT_OPEN_TIME = 'mz',
	
	BUTTON_QUIT  = 'ding/fan',
}

local gradeview = class("gradeview")
gradeview.__index = gradeview

function gradeview.create(block_id,enable,match_id,match_rank,match_name,match_enable)
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),gradeview)
	layer.block_id = block_id
	layer.enable = enable
	layer.match_id = match_id
	layer.match_rank = match_rank
	layer.match_name = match_name
	layer.match_enable = match_enable
	
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
	if self.id_flag == hitconfig.ID_FLAG_STU then
		local but_match_join = uikits.child(view_cur_match,ui.BUTTON_MATCH_JOIN)
		if self.enable == 1 then
			view_cur_match:setVisible(true)
			local txt_match_name = uikits.child(view_cur_match,ui.TXT_MATCH_NAME)
			local txt_match_rank = uikits.child(view_cur_match,ui.TXT_MATCH_RANK)
			local txt_match_tip = uikits.child(view_cur_match,ui.TXT_MATCH_TIP)
			txt_match_name:setString(self.match_name)
			txt_match_rank:setString(self.match_rank)
			if self.match_enable == 1 then
				but_match_join:setEnabled(true)
				but_match_join:setBright(true)
				but_match_join:setTouchEnabled(true)
				txt_match_tip:setVisible(false)
			else
				but_match_join:setEnabled(false)
				but_match_join:setBright(false)
				but_match_join:setTouchEnabled(false)	
				txt_match_tip:setVisible(true)			
			end
		else
			view_cur_match:setVisible(false)
			is_show_cur_match = false
		end
		uikits.event(but_match_join,	
			function(sender,eventType)
			local send_data = {V1=self.match_id}
			http.post_data(self._gradeview,'get_match',send_data,function(t,v)
				if t and t==200 then
					uikits.replaceScene(battle.create{
							level = n or 1,
							time_limit = v.times or 10,
							rand = v.road_radom or 0,
							diff1 = v.diffcult_low or 0,
							diff2 = v.diffcult_up or 0,
							signle = v.question_amount or 10,
							dual = 0,
							condition = v.pass_condition or 60,
						})
				else
					http.messagebox(self._gradeview,http.NETWORK_ERROR,function(e)
					end)		
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
		if self.enable == 1 then
			txt_has_match:setVisible(true)
			txt_no_match:setVisible(false)
			but_open_match:setSelectedState(false)
		else
			txt_has_match:setVisible(false)
			txt_no_match:setVisible(true)	
			but_open_match:setSelectedState(true)	
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
									if v == true then
										if self.enable == 1 then
											self.enable = 0
											txt_has_match:setVisible(false)
											txt_no_match:setVisible(true)	
										else
											self.enable = 1
											txt_has_match:setVisible(true)
											txt_no_match:setVisible(false)
										end
									else
										if self.enable == 1 then
											but_open_match:setSelectedState(false)
										else
											but_open_match:setSelectedState(true)
										end										
									end
								else
									hitconfig.messagebox(self._gradeview,hitconfig.NETWORK_ERROR,function(e)
										if e == hitconfig.OK then
										
										else
											
										end
									end)							
								end
							end)
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
		txt_people_num:setString(self.history_list[i].Users..'人')
		txt_open_time:setString(self.history_list[i].match_time)
		
		local but_detail = uikits.child(cur_pro,ui.BUTTON_DETAIL)
		but_detail.road_block_id = self.history_list[i].road_block_id
		but_detail.open_time = self.history_list[i].match_time
		uikits.event(but_detail,	
			function(sender,eventType)
				local send_data = {}
				send_data.v1 = sender.road_block_id
				send_data.v2 = 2
				send_data.v3 = 1
				send_data.v4 = 100
				hitconfig.post_data(self._gradeview,'road_block_rank',send_data,function(t,v)
								if t and t == 200 then
									uikits.pushScene( rankview.create(v,sender.open_time,self.match_name) )
								else
									hitconfig.messagebox(self._gradeview,hitconfig.NETWORK_ERROR,function(e)
										if e == hitconfig.OK then
										
										else
											
										end
									end)							
								end
							end)
				--uikits.pushScene( resetpwview.create() )
		end)
	end
end

function gradeview:get_his_list()
	local send_data = {}
	send_data.v1 = self.match_id
	hitconfig.post_data(self._gradeview,'get_match_history',send_data,function(t,v)
					if t and t == 200 then
						self.history_list = v
						self:show_history_list()
					else
						hitconfig.messagebox(self._gradeview,hitconfig.NETWORK_ERROR,function(e)
							if e == hitconfig.OK then
							
							else
								
							end
						end)							
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
	if self.id_flag == hitconfig.ID_FLAG_STU then
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