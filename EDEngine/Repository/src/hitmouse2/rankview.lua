local kits = require "kits"
local uikits = require "uikits"
local cache = require "cache"
local hitconfig = require 'hitmouse2/hitconfig'

local ui = {
	TEA_FILE = 'hitmouse2/xiangqing.json',
	TEA_FILE_3_4 = 'hitmouse2/xiangqing43.json',

	STU_FILE = 'hitmouse2/xiangqing.json',
	STU_FILE_3_4 = 'hitmouse2/xiangqing43.json',
	VIEW_RANK = 'gun',
	VIEW_PER_USER = 'gun/ren1',
	TXT_RANK = 'mc',
	PIC_USER = 'toux',
	TXT_USER_NAME = 'mz',
	TXT_USER_CLASS = 'bj',
	TXT_TIME = 'sj',
	TXT_USER_FEN = 'df',
	TXT_PAR_FEN = 'df2',
	TXT_ALL_FEN = 'defen',
	TXT_JOIN_TIMES = 'cs',
	
	TXT_TOP_DATE = 'ding/sj',
	TXT_TOP_GRADE = 'ding/nj',
	BUTTON_QUIT  = 'ding/fan',
}

local rankview = class("rankview")
rankview.__index = rankview

function rankview.create(rank_data,str_date,str_grade)
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),rankview)
	layer.rank_data = rank_data
	layer.str_date = str_date
	layer.str_grade = str_grade
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

function rankview:show_rank()
	local txt_top_date = uikits.child(self._rankview,ui.TXT_TOP_DATE)
	local txt_top_grade = uikits.child(self._rankview,ui.TXT_TOP_GRADE)
	txt_top_date:setString(self.str_date)
	txt_top_grade:setString(self.str_grade)
	local view_rank = uikits.child(self._rankview,ui.VIEW_RANK)
	local view_person_src = uikits.child(self._rankview,ui.VIEW_PER_USER)
	local viewSize=view_rank:getContentSize()
	local viewPosition=cc.p(view_rank:getPosition())
	local viewParent=view_rank:getParent()
	view_rank:setVisible(false)
	if self.rank_data and type(self.rank_data) == 'table' then
		local view_rank = hitconfig.createRankView(viewParent,viewPosition,viewSize,view_person_src,function(item,data)
				local txt_rank = uikits.child(item,ui.TXT_RANK)
				local pic_user = uikits.child(item,ui.PIC_USER)
				local txt_user_name = uikits.child(item,ui.TXT_USER_NAME)
				local txt_user_class = uikits.child(item,ui.TXT_USER_CLASS)
				local txt_time = uikits.child(item,ui.TXT_TIME)
				local txt_user_fen = uikits.child(item,ui.TXT_USER_FEN)
				local txt_par_fen = uikits.child(item,ui.TXT_PAR_FEN)
				local txt_all_fen = uikits.child(item,ui.TXT_ALL_FEN)
				local txt_join_times = uikits.child(item,ui.TXT_JOIN_TIMES)

				txt_rank:setString(data.rank)
				txt_user_name:setString(data.uname)
				txt_user_class:setString(data.str_gradeclass)
				txt_time:setString(data.str_times)
				txt_user_fen:setString(data.integral)
				txt_par_fen:setString(data.parent_integral)
				txt_all_fen:setString(data.results)
				txt_join_times:setString(data.enter_number)
				hitconfig.load_logo_pic(pic_user,data.user_id)
			end,function(waitingNode,afterReflash)
			local data = self.rank_data 
			afterReflash(data)
		end)
	end
end

function rankview:init()
	if uikits.get_factor() == uikits.FACTOR_9_16 then
		uikits.initDR{width=1920,height=1080}
	else
		uikits.initDR{width=1440,height=1080}
	end
	self.id_flag = hitconfig.get_id_flag()
	if self.id_flag == hitconfig.ID_FLAG_STU then
		self._rankview = uikits.fromJson{file_9_16=ui.STU_FILE,file_3_4=ui.STU_FILE_3_4}	
	else
		self._rankview = uikits.fromJson{file_9_16=ui.TEA_FILE,file_3_4=ui.TEA_FILE_3_4}		
	end
	self:addChild(self._rankview)
	self:show_rank()
	local but_quit = uikits.child(self._rankview,ui.BUTTON_QUIT)
	uikits.event(but_quit,	
		function(sender,eventType)	
			uikits.popScene()
		end,"click")
end

function rankview:release()
	
end

return rankview