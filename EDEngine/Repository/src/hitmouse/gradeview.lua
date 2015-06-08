local kits = require "kits"
local uikits = require "uikits"
local cache = require "cache"
local hitconfig = require 'hitmouse/hitconfig'

local ui = {
	TEA_FILE = 'hitmouse/xzjinru.json',
	TEA_FILE_3_4 = 'hitmouse/xzjinru43.json',

	STU_FILE = 'hitmouse/jinbishai.json',
	STU_FILE_3_4 = 'hitmouse/jinbishai43.json',
	
	VIEW_ALL_HISTORY = 'gun',
	VIEW_CUR_MATCH = 'gun/xinde',
	VIEW_HIS_MATCH_SRC = 'gun/bisai1',
	
	BUTTON_DETAIL  = 'xiangq',
	BUTTON_QUIT  = 'ding/fan',
}

local gradeview = class("gradeview")
gradeview.__index = gradeview

function gradeview.create(block_id,enable,match_id)
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),gradeview)
	layer.block_id = block_id
	layer.enable = enable
	layer.match_id = match_id
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

function gradeview:show_match_list()
	self.is_has_match = false
	for i=1,6 do
		local but_grade = uikits.child(self._gradeview,ui.VIEW_GRADE_SRC..i)
		local txt_grade_open = uikits.child(but_grade,ui.TXT_GRADE_OPEN)
		local txt_grade_close = uikits.child(but_grade,ui.TXT_GRADE_CLOSE)
		but_grade.block_id = self.match_list_data[i].road_block_id
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
			
			end,"click")
	end
	local txt_has_match = uikits.child(self._gradeview,ui.TXT_HAS_MATCH)
	local txt_no_match = uikits.child(self._gradeview,ui.TXT_NO_MATCH)
	if self.is_has_match == true then
		txt_has_match:setVisible(true)
		txt_no_match:setVisible(false)			
	else
		txt_has_match:setVisible(false)
		txt_no_match:setVisible(true)			
	end
end

function gradeview:show_history_list()
	local is_show_cur_match = true
	local view_all_history = uikits.child(self._gradeview,ui.VIEW_ALL_HISTORY)
	local view_cur_match = uikits.child(self._gradeview,ui.VIEW_CUR_MATCH)
	local view_his_match_src = uikits.child(self._gradeview,ui.VIEW_HIS_MATCH_SRC)
	if self.id_flag == hitconfig.ID_FLAG_STU then
		if self.enable == 1 then
			view_cur_match:setVisible(true)
		else
			view_cur_match:setVisible(false)
			is_show_cur_match = false
		end
	else
	
	end

	local size_all = view_all_history:getContentSize()
	local size_cur_match = view_cur_match:getContentSize()
	local size_his_match_src = view_his_match_src:getContentSize()
	local scroll_size = view_all_history:getInnerContainerSize()
	local all_height
	if is_show_cur_match == true then
		all_height = size_cur_match.height + (size_his_match_src.height)*(#self.history_list)
	else
		all_height = (size_his_match_src.height)*(#self.history_list)
	end
	if all_height > size_all.height then
		scroll_size.height = all_height
		view_cur_match:setPositionY(scroll_size.height-size_cur_match.height)
	end
	view_mine:setInnerContainerSize(scroll_size)	
		
	local pos_y_start = scroll_size.height - size_cur_match.height - size_his_match_src.height
	view_his_match_src:setVisible(false)	
	for i=1 , #self.history_list do
		local cur_pro = view_his_match_src:clone()
		cur_pro:setVisible(true)
		cur_pro:setPositionY(pos_y_start-(i-1)*(size_his_match_src.height))
		view_mine:addChild(cur_pro,1,10000+i)
		
	end
	
	local but_mine_repw = uikits.child(self._gradeview,ui.BUTTON_MINE_REPW)
	uikits.event(but_mine_repw,	
		function(sender,eventType)
			--uikits.pushScene( resetpwview.create() )
	end)
end

function gradeview:get_his_list()
	local send_data = {}
	send_data.v1 = self.match_id
	hitconfig.post_data(self._gradeview,'get_match_history',send_data,function(t,v)
					if t and t == 200 then
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
	local but_quit = uikits.child(self._gradeview,ui.BUTTON_QUIT)
	uikits.event(but_quit,	
		function(sender,eventType)	
			uikits.popScene()
		end,"click")		
end

function gradeview:release()
	
end

return gradeview