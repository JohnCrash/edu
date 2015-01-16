local uikits = require "uikits"
local kits = require "kits"
local json = require "json-c"
local login = require "login"
local cache = require "cache"
local person_info = require "poetrymatch/person_info"

local Noticeview = class("Noticeview")
Noticeview.__index = Noticeview
local ui = {
	Noticeview_FILE = 'poetrymatch/tongzhi.json',
	Noticeview_FILE_3_4 = 'poetrymatch/tongzhi.json',
	
	VIEW_NOTICE = 'gun',
	VIEW_NOTICE_SRC = 'gun/tz',
	TXT_TITLE = 'tz1/leitbt',
	TXT_CONTENT = 'tz1/wen',
	TXT_DATE = 'tz1/sj',
	
	BUTTON_QUIT = 'xinxi/fanhui',
}

local function loadArmature( name )
		ccs.ArmatureDataManager:getInstance():removeArmatureFileInfo(name)
		ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(name)	
end

function create()
	local scene = cc.Scene:create()				
	local cur_layer = uikits.extend(cc.Layer:create(),Noticeview)		
	
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
local notice_space = 50
function Noticeview:show_notice(notice_info)	
	local notice_view = uikits.child(self._Noticeview,ui.VIEW_NOTICE)	
	local notice_view_src = uikits.child(self._Noticeview,ui.VIEW_NOTICE_SRC)	
	notice_view_src:setVisible(false)
	if not notice_info then
		return
	end
	local row_num = #notice_info	
	local size_scroll = notice_view:getInnerContainerSize()
	local size_notice_view = notice_view:getContentSize()
	local size_notice_view_src = notice_view_src:getContentSize()
	local pos_src_y = notice_view_src:getPositionY()
	local pos_start_y = size_notice_view.height-pos_src_y
	if (size_notice_view_src.height+notice_space)*row_num >size_notice_view.height then
		size_scroll.height = (size_notice_view_src.height+notice_space)*row_num
		notice_view:setInnerContainerSize(size_scroll)
		pos_start_y = size_scroll.height - pos_start_y
	else
		pos_start_y = pos_src_y
	end
	for i=1,row_num do
		local cur_notice = notice_view_src:clone()
		cur_notice:setVisible(true)
		notice_view:addChild(cur_notice)
		local pos_y = pos_start_y - (i-1)*(size_notice_view_src.height+notice_space)
		cur_notice:setPositionY(pos_y)
		local txt_title = uikits.child(cur_notice,ui.TXT_TITLE)
		local txt_content = uikits.child(cur_notice,ui.TXT_CONTENT)
		local txt_date = uikits.child(cur_notice,ui.TXT_DATE)
		txt_title:setString(notice_info[i].title)
		txt_content:setString(notice_info[i].msg)
		txt_date:setString(notice_info[i].send_time)
		
	end
end

function Noticeview:getdatabyurl()
	local send_data
	person_info.post_data_by_new_form(self._Noticeview,'get_msg',send_data,function(t,v)
		if t and t == 200 then
			if v and type(v) == 'table' then
				local user_info = person_info.get_user_info()
				if user_info.has_msg == 1 then
					user_info.has_msg = 0 
					person_info.set_user_info(user_info)
				end
				self:show_notice(v)
			end
		else
		
			if t == 603 then
				person_info.messagebox(self._Noticeview,person_info.DIY_MSG,function(e)
					if e == person_info.OK then
						uikits.popScene()
					end
				end,'ÌבÊ¾',v)				
			else
				person_info.messagebox(self._Noticeview,person_info.NETWORK_ERROR,function(e)
					if e == person_info.OK then

					end
				end)
			end
		end
	end)
end

function Noticeview:init()	
	if uikits.get_factor() == uikits.FACTOR_9_16 then
		uikits.initDR{width=1920,height=1080}
	else
		uikits.initDR{width=1440,height=1080}
	end
	self._Noticeview = uikits.fromJson{file_9_16=ui.Noticeview_FILE,file_3_4=ui.Noticeview_FILE_3_4}
	self:addChild(self._Noticeview)
	local but_quit = uikits.child(self._Noticeview,ui.BUTTON_QUIT)
	uikits.event(but_quit,	
		function(sender,eventType)	
			uikits.popScene()
		end,"click")		

	self:getdatabyurl()

end

function Noticeview:release()

end
return {
create = create,
}