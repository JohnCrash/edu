local crash = require "crash"
local uikits = require "uikits"
local cache = require "cache"
local kits = require "kits"
local login = require "login"
local json = require "json-c"
local loadingbox = require "loadingbox"
local adderrorview = require "errortitlenew/AddErrorView"
local ljshell = require "ljshell"
local imagepreview = require "errortitlenew/imagepreview"
local ui = {
	FILE = 'errortitlenew/main.json',
	FILE_3_4 = 'errortitlenew/main43.json',

	BUTTON_QUIT = 'mainmenu/fanhui',
	BUTTON_ADD = 'mainmenu/tianj',
	
	TXT_ERR_COUNT = 'mainmenu/sl',
	TXT_USER_NAME = 'mainmenu/mz',
	
	VIEW_NO_ALL_STA = 'wukemu',
	BUTTON_ADD_NO = 'wukemu/jia',
	VIEW_NO_BUHUI_STA = 'wubuhui',
	VIEW_NO_YIHUI_STA = 'wuhui',
	VIEW_NO_TEACHER = 'wukemu_T',
	
	BUTTON_CUR_COURSE_ALL = 'mainmenu/kemu',
	BUTTON_CUR_COURSE_MATH = 'mainmenu/shuxue',
	BUTTON_CUR_COURSE_CHN = 'mainmenu/yuwen',
	BUTTON_CUR_COURSE_ENG = 'mainmenu/yinyu',
	BUTTON_CUR_COURSE_OTHER = 'mainmenu/zh',

	COURSE_LIST = 'kemu',
	COURSE_LIST_ALL = 'kemu/quanbu',
	COURSE_LIST_MATH = 'kemu/shuxue',
	COURSE_LIST_CHN = 'kemu/yuwen',
	COURSE_LIST_ENG = 'kemu/yinyu',
	COURSE_LIST_OTHER = 'kemu/zhonghe',

	BUTTON_CUR_STA_ALL = 'mainmenu/zhuangt',
	BUTTON_CUR_STA_YES = 'mainmenu/yihui',
	BUTTON_CUR_STA_NO = 'mainmenu/buhui',
	
	STA_LIST = 'zhuangt',
	STA_LIST_ALL = 'zhuangt/quanbu',
	STA_LIST_YES = 'zhuangt/yihui',
	STA_LIST_NO = 'zhuangt/buhui',

	VIEW_TITLE = 'tik',
	PER_TITLE_VIEW = 'tik/ti1',
	VIEW_TU = 'tu',
	PIC_VIEW = 'tu/Image_20',

	PIC_COURSE_MATH = 'xinxi/shuxue',
	PIC_COURSE_CHN = 'xinxi/yuwen',
	PIC_COURSE_ENG = 'xinxi/yinyu',
	PIC_COURSE_OTHER = 'xinxi/zhonghe',
	
	TXT_CUXIN = 'xinxi/wen1',
	TXT_LIJIE = 'xinxi/wen2',
	TXT_GAINIAN = 'xinxi/wen3',
	TXT_BUHUI = 'xinxi/wen4',
	TXT_JISUAN = 'xinxi/wen5',
	TXT_QITA = 'xinxi/wen6',

	BUTTON_STA_HUI = 'xinxi/zt',
	

--[[	EMPTY_VIEW = 'errortitlenew/meishouchang.json',
	EMPTY_VIEW_3_4 = 'errortitlenew/meishouchang43.json',
	
	BIG_PIC_VIEW = 'errortitlenew/showpic_new.json',
	BIG_PIC_VIEW_3_4 = 'errortitlenew/showpic43_new.json',
	
	VIEW_BIG = 'mypic_up',
	BIG_PIC = 'mypic_up/my_pic',
	CLOSE_BUT = 'mypic_up/closebox/close',
	
	CHECK_HUI = 'hui',--]]
	
}

local ErrorTitlePerView = class("ErrorTitlePerView")
ErrorTitlePerView.__index = ErrorTitlePerView

local is_loading

function ErrorTitlePerView.create(user_name)
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),ErrorTitlePerView)
	scene:addChild(layer)
	layer.course_index = 0
	layer.status_index = 0
	layer.page_index = 1
	layer.totalpagecount = 0
	layer.totalcount = 0
	layer.isneedupdate = true
	layer.inner_posx = 0
	layer.inner_posy = 0
	layer.user_name = user_name
	is_loading = false
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

function ErrorTitlePerView:init_butlist()
--[[	local view_no_all = uikits.child(self._widget,ui.VIEW_NO_ALL_STA)
	local view_no_yihui = uikits.child(self._widget,ui.VIEW_NO_YIHUI_STA)
	local view_no_buhui = uikits.child(self._widget,ui.VIEW_NO_BUHUI_STA)
	view_no_all:setVisible(false)
	view_no_yihui:setVisible(false)
	view_no_buhui:setVisible(false)--]]
	local save_info = kits.config("et_init",'get')
	if save_info then
		local save_info_tb = json.decode(save_info)
		self.course_index = save_info_tb.course_index
		self.status_index = save_info_tb.status_index
	end
	local txt_user_name = uikits.child(self._widget,ui.TXT_USER_NAME)
	txt_user_name:setString(self.user_name)
	
	local but_add_no = uikits.child(self._widget,ui.BUTTON_ADD_NO)
	uikits.event(but_add_no,	
		function(sender,eventType)	
			self.isneedupdate = true
			local scene_next = adderrorview.create()		
			uikits.pushScene(scene_next)	
	end,"click")
	
	local course_list = uikits.child(self._widget,ui.COURSE_LIST)
	local status_list = uikits.child(self._widget,ui.STA_LIST)
	course_list:setVisible(false)
	status_list:setVisible(false)
	local per_title_src = uikits.child(self._widget,ui.PER_TITLE_VIEW)
	per_title_src:setVisible(false)
	
	local pic_course_math = uikits.child(per_title_src,ui.PIC_COURSE_MATH)
	local pic_course_chn = uikits.child(per_title_src,ui.PIC_COURSE_CHN)
	local pic_course_eng = uikits.child(per_title_src,ui.PIC_COURSE_ENG)
	local pic_course_other = uikits.child(per_title_src,ui.PIC_COURSE_OTHER)
	pic_course_math:setVisible(false)
	pic_course_chn:setVisible(false)
	pic_course_eng:setVisible(false)
	pic_course_other:setVisible(false)

	local but_cur_course_all = uikits.child(self._widget,ui.BUTTON_CUR_COURSE_ALL)
	local but_cur_course_math = uikits.child(self._widget,ui.BUTTON_CUR_COURSE_MATH)
	local but_cur_course_chn = uikits.child(self._widget,ui.BUTTON_CUR_COURSE_CHN)
	local but_cur_course_eng = uikits.child(self._widget,ui.BUTTON_CUR_COURSE_ENG)
	local but_cur_course_other = uikits.child(self._widget,ui.BUTTON_CUR_COURSE_OTHER)	
	
	but_cur_course_all:setVisible(false)
	but_cur_course_math:setVisible(false)
	but_cur_course_chn:setVisible(false)
	but_cur_course_eng:setVisible(false)
	but_cur_course_other:setVisible(false)
		
	if self.course_index == 0 then
		but_cur_course_all:setVisible(true)
	elseif self.course_index == 1 then
		but_cur_course_chn:setVisible(true)
	elseif self.course_index == 2 then
		but_cur_course_math:setVisible(true)
	elseif self.course_index == 3 then
		but_cur_course_eng:setVisible(true)
	elseif self.course_index == 4 then
		but_cur_course_other:setVisible(true)
	end
	
	uikits.event(but_cur_course_all,	
		function(sender,eventType)	
			self._status_list:setVisible(false)
			local is_show = course_list:isVisible()	
			if is_show == true then
				course_list:setVisible(false)
			else
				course_list:setVisible(true)
			end	
	end,"click")
	
	uikits.event(but_cur_course_math,	
		function(sender,eventType)	
			self._status_list:setVisible(false)
			local is_show = course_list:isVisible()	
			if is_show == true then
				course_list:setVisible(false)
			else
				course_list:setVisible(true)
			end	
	end,"click")
	
	uikits.event(but_cur_course_chn,	
		function(sender,eventType)	
			self._status_list:setVisible(false)
			local is_show = course_list:isVisible()	
			if is_show == true then
				course_list:setVisible(false)
			else
				course_list:setVisible(true)
			end	
	end,"click")
	
	uikits.event(but_cur_course_eng,	
		function(sender,eventType)	
			self._status_list:setVisible(false)
			local is_show = course_list:isVisible()	
			if is_show == true then
				course_list:setVisible(false)
			else
				course_list:setVisible(true)
			end	
	end,"click")
	
	uikits.event(but_cur_course_other,	
		function(sender,eventType)	
			self._status_list:setVisible(false)
			local is_show = course_list:isVisible()	
			if is_show == true then
				course_list:setVisible(false)
			else
				course_list:setVisible(true)
			end	
	end,"click")
	
	local list_course_all = uikits.child(self._widget,ui.COURSE_LIST_ALL)
	local list_course_math = uikits.child(self._widget,ui.COURSE_LIST_MATH)
	local list_course_chn = uikits.child(self._widget,ui.COURSE_LIST_CHN)
	local list_course_eng = uikits.child(self._widget,ui.COURSE_LIST_ENG)
	local list_course_other = uikits.child(self._widget,ui.COURSE_LIST_OTHER)	
	
	uikits.event(list_course_all,	
		function(sender,eventType)	
			self.page_index = 1
			self.course_index = 0
			course_list:setVisible(false)
			but_cur_course_all:setVisible(true)
			but_cur_course_math:setVisible(false)
			but_cur_course_chn:setVisible(false)
			but_cur_course_eng:setVisible(false)
			but_cur_course_other:setVisible(false)
			self:getdatabyurl()
	end,"click")

	uikits.event(list_course_math,	
		function(sender,eventType)	
			self.page_index = 1
			self.course_index = 2
			course_list:setVisible(false)
			but_cur_course_all:setVisible(false)
			but_cur_course_math:setVisible(true)
			but_cur_course_chn:setVisible(false)
			but_cur_course_eng:setVisible(false)
			but_cur_course_other:setVisible(false)
			self:getdatabyurl()
	end,"click")
	
	uikits.event(list_course_chn,	
		function(sender,eventType)	
			self.page_index = 1
			self.course_index = 1
			course_list:setVisible(false)
			but_cur_course_all:setVisible(false)
			but_cur_course_math:setVisible(false)
			but_cur_course_chn:setVisible(true)
			but_cur_course_eng:setVisible(false)
			but_cur_course_other:setVisible(false)
			self:getdatabyurl()
	end,"click")

	uikits.event(list_course_eng,	
		function(sender,eventType)	
			self.page_index = 1
			self.course_index = 3
			course_list:setVisible(false)
			but_cur_course_all:setVisible(false)
			but_cur_course_math:setVisible(false)
			but_cur_course_chn:setVisible(false)
			but_cur_course_eng:setVisible(true)
			but_cur_course_other:setVisible(false)
			self:getdatabyurl()
	end,"click")

	uikits.event(list_course_other,	
		function(sender,eventType)	
			self.page_index = 1
			self.course_index = 4
			course_list:setVisible(false)
			but_cur_course_all:setVisible(false)
			but_cur_course_math:setVisible(false)
			but_cur_course_chn:setVisible(false)
			but_cur_course_eng:setVisible(false)
			but_cur_course_other:setVisible(true)
			self:getdatabyurl()
	end,"click")
	
--[[	local check_status = uikits.child(self._widget,ui.BUTTON_STA_HUI)
	uikits.event(check_status,	
		function(sender,eventType)	
			print('eventType::'..tostring(eventType))
			if eventType == true then
				self.page_index = 1
				self.status_index = 2
				self:getdatabyurl()
			else
				self.page_index = 1
				self.status_index = 1
				self:getdatabyurl()
			end	
	end)--]]
	local but_cur_status_all = uikits.child(self._widget,ui.BUTTON_CUR_STA_ALL)
	local but_cur_status_yes = uikits.child(self._widget,ui.BUTTON_CUR_STA_YES)
	local but_cur_status_no = uikits.child(self._widget,ui.BUTTON_CUR_STA_NO)
	
	but_cur_status_all:setVisible(false)
	but_cur_status_yes:setVisible(false)
	but_cur_status_no:setVisible(false)
	
	if self.status_index == 0 then
		but_cur_status_all:setVisible(true)
	elseif self.status_index == 1 then
		but_cur_status_no:setVisible(true)
	elseif self.status_index == 2 then
		but_cur_status_yes:setVisible(true)
	end
	
	uikits.event(but_cur_status_all,	
		function(sender,eventType)	
			self._course_list:setVisible(false)
			local is_show = status_list:isVisible()	
			if is_show == true then
				status_list:setVisible(false)
			else
				status_list:setVisible(true)
			end	
	end,"click")
	
	uikits.event(but_cur_status_yes,	
		function(sender,eventType)	
			self._course_list:setVisible(false)
			local is_show = status_list:isVisible()	
			if is_show == true then
				status_list:setVisible(false)
			else
				status_list:setVisible(true)
			end	
	end,"click")
	
	uikits.event(but_cur_status_no,	
		function(sender,eventType)	
			self._course_list:setVisible(false)
			local is_show = status_list:isVisible()	
			if is_show == true then
				status_list:setVisible(false)
			else
				status_list:setVisible(true)
			end	
	end,"click")	
	
	local list_status_all = uikits.child(self._widget,ui.STA_LIST_ALL)
	local list_status_yes = uikits.child(self._widget,ui.STA_LIST_YES)
	local list_status_no = uikits.child(self._widget,ui.STA_LIST_NO)
	
	uikits.event(list_status_all,	
		function(sender,eventType)	
		self.page_index = 1
		self.status_index = 0
		status_list:setVisible(false)
		but_cur_status_all:setVisible(true)
		but_cur_status_yes:setVisible(false)
		but_cur_status_no:setVisible(false)
		self:getdatabyurl()
	end,"click")
	uikits.event(list_status_yes,	
		function(sender,eventType)	
		self.page_index = 1
		self.status_index = 2
		status_list:setVisible(false)
		but_cur_status_all:setVisible(false)
		but_cur_status_yes:setVisible(true)
		but_cur_status_no:setVisible(false)
		self:getdatabyurl()
	end,"click")
	uikits.event(list_status_no,	
		function(sender,eventType)	
		self.page_index = 1
		self.status_index = 1
		status_list:setVisible(false)
		but_cur_status_all:setVisible(false)
		but_cur_status_yes:setVisible(false)
		but_cur_status_no:setVisible(true)
		self:getdatabyurl()
	end,"click")
end

function ErrorTitlePerView:show_checkview(cur_title_view,reason)
	local txt_reason_cuxin = uikits.child(cur_title_view,ui.TXT_CUXIN)
	local txt_reason_lijie = uikits.child(cur_title_view,ui.TXT_LIJIE)
	local txt_reason_gainian = uikits.child(cur_title_view,ui.TXT_GAINIAN)
	local txt_reason_buhui = uikits.child(cur_title_view,ui.TXT_BUHUI)
	local txt_reason_jisuan = uikits.child(cur_title_view,ui.TXT_JISUAN)
	local txt_reason_qita = uikits.child(cur_title_view,ui.TXT_QITA)
	txt_reason_cuxin:setVisible(false)
	txt_reason_lijie:setVisible(false)
	txt_reason_gainian:setVisible(false)
	txt_reason_buhui:setVisible(false)
	txt_reason_jisuan:setVisible(false)
	txt_reason_qita:setVisible(false)

	if reason == 1 then
		txt_reason_cuxin:setVisible(true)
	elseif reason == 2 then
		txt_reason_lijie:setVisible(true)
	elseif reason == 3 then
		txt_reason_gainian:setVisible(true)
	elseif reason == 4 then
		txt_reason_buhui:setVisible(true)
	elseif reason == 5 then
		txt_reason_jisuan:setVisible(true)
	elseif reason == 6 then
		txt_reason_qita:setVisible(true)
	end

--[[	local check_boxlist = check_view:getChildren()
	local check_boxnum = check_view:getChildrenCount()	
	for i=1,check_boxnum do	
		if i ~= title_tabel.reason then
			--local per_checkbox = check_view:getChildByTag(72+i)
			check_boxlist[i]:setSelectedState(false)
		else
			check_boxlist[i]:setSelectedState(true)
		end
	end
	local checkview_size = check_view:getContentSize()
	local per_checkbox_size = check_boxlist[1]:getContentSize()
	local per_checkbox_posX = check_boxlist[1]:getPositionX()
	--check_view:setInnerContainerSize(cc.size((per_checkbox_size.width+(per_checkbox_posX-per_checkbox_size.width/2))*check_boxnum,checkview_size.height))

	local i
	for i=1,check_boxnum do	
		uikits.event(check_boxlist[i],
			function(sender,eventType)	
				if eventType == true then		
					local j
					local send_url
					local tag = sender:getTag()
					for j=1,check_boxnum do			
						local tag_box = check_boxlist[j]:getTag()
						if tag ~= tag_box then
							--local per_checkbox = check_view:getChildByTag(72+i)
							check_boxlist[j]:setSelectedState(false)
						else		
							local base_url = "http://app.lejiaolexue.com/exerbook2/item_reason.ashx"
							if check_boxlist[j]:getSelectedState() == true then
								send_url = base_url.."?id="..title_tabel.id.."&reason="..j
							else
								send_url = base_url.."?id="..title_tabel.id.."&reason="..0
							end	
							if login.get_uid_type() ~= login.STUDENT then
								send_url = send_url..'&user_id='..login.get_subuid()
							end
						end			

					end
					local loadbox = loadingbox.open(self)
					cache.request_json( send_url,function(t)
						if t and type(t)=='table' then
							if t.result ~= 0 then
								loadbox:removeFromParent()
								return false
							else
								
							end
						else
							--既没有网络也没有缓冲
							messagebox.open(self,function(e)
								if e == messagebox.TRY then
									self:adderrortitle()
								elseif e == messagebox.CLOSE then
									uikits.popScene()
								end
							end,messagebox.RETRY)	
						end
						loadbox:removeFromParent()
					end,'N')
				end
			end)
	end--]]
end

local pic_space = 10
local download_pic_url = 'http://file-stu.lejiaolexue.com/rest/dlimage/'
local download_pic_big_url = 'http://file-stu.lejiaolexue.com/rest/dl/'
local button_empty_path = 'errortitlenew/kuang.png'

function ErrorTitlePerView:save_innerpos()
	local view_title = 	uikits.child(self._widget,ui.VIEW_TITLE)
	self.inner_posx,self.inner_posy = view_title:getInnerContainer():getPosition()
end

function ErrorTitlePerView:set_innerpos()
	local view_title = 	uikits.child(self._widget,ui.VIEW_TITLE)
	view_title:getInnerContainer():setPosition(cc.p(self.inner_posx,self.inner_posy))
end

function ErrorTitlePerView:show_picview(pic_view,pic_str,per_title_view)
	local pos_start,pos_end
	local function touchEventPic(sender,eventType)
--[[		local file_path = kits.get_local_directory()..'res/errortitlenew/11.jpg'
		local imgs = {}
		imgs[1] = file_path
		--local scene_next = imagepreview.create(1,imgs,self)		
		local scene_next = imagepreview.create()		
		uikits.pushScene(scene_next)--]]	

		if eventType == ccui.TouchEventType.began then
			pos_start = sender:getTouchBeganPosition()
		elseif eventType == ccui.TouchEventType.ended then
			pos_end = sender:getTouchBeganPosition()
			if math.sqrt((pos_end.x-pos_start.x)*(pos_end.x-pos_start.x)+(pos_end.y-pos_start.y)*(pos_end.y-pos_start.y)) < 10 then
--[[				local loadbox = loadingbox.open(self)
				is_loading = true
				cache.request_nc(download_pic_big_url..sender.pic_name,
				function(b,t)
						if b then
						--	local s_pic = picview:getContentSize()
							self:save_innerpos()	
							local local_dir = ljshell.getDirectory(ljshell.AppDir)
							local file_path = local_dir.."cache/"..sender.pic_name
						--	local file_path = kits.get_local_directory()..'res/errortitlenew/11.jpg'
							local imgs = {}
							imgs[1] = file_path
							local scene_next = imagepreview.create(1,imgs,self)	
							uikits.pushScene(scene_next)	
						else
							kits.log("ERROR :  download_pic_big_url failed")
						end
					is_loading = false
					loadbox:removeFromParent()
					end,sender.pic_name)		--]]	
				local local_dir = ljshell.getDirectory(ljshell.AppDir)	
				local imgs = {}	
				self:save_innerpos()
				self.isneedupdate = false
				for j=1,#sender.pic_name do
					local file_path = local_dir.."cache/"..sender.pic_name[j]
					imgs[j] = file_path
				end
				local scene_next = imagepreview.create(1,imgs)	
				uikits.pushScene(scene_next)					
			end
		end
		
	end
	
	local pic_table = json.decode(pic_str)
	for i=1,#pic_table do
		local cur_pic = uikits.child(per_title_view,ui.PIC_VIEW)
		cur_pic:setVisible(true)
		local loadbox = loadingbox.circle( cur_pic )
		is_loading = true
		local local_dir = ljshell.getDirectory(ljshell.AppDir)
		local file_path = local_dir.."cache/"..pic_table[i]
		if kits.exist_file(file_path) then
			if i == #pic_table then
				cur_pic:loadTexture(file_path)	
				local view_tu = uikits.child(per_title_view,ui.VIEW_TU)
				local s_tu_view = view_tu:getContentSize()
				local s_pic = cur_pic:getContentSize()
				cur_pic:setScale(s_tu_view.height/s_pic.height)	
				local button_pic = ccui.Button:create()
				button_pic:setTouchEnabled(true)
				button_pic.pic_name = pic_table
				button_pic:loadTextures(button_empty_path, button_empty_path, "")
				button_pic:setPosition(cc.p(s_tu_view.width/2,s_tu_view.height/2))        
				button_pic:addTouchEventListener(touchEventPic)
				view_tu:addChild(button_pic)	
			end
			is_loading = false
			loadbox:removeFromParent()
		else
			cache.request_nc(download_pic_big_url..pic_table[i],
			function(b,t)
					if b then
	--[[					local new_pic = pic_view:clone()
						local local_dir = ljshell.getDirectory(ljshell.AppDir)
						local file_path = local_dir.."cache/"..pic_table[i]
						new_pic:loadTexture(file_path)
						local s_pic = new_pic:getContentSize()
						local x_pic = new_pic:getPositionX()
						x_pic = x_pic + (pic_space+s_pic.width)*(i-1)
						new_pic:setPositionX(x_pic)
						new_pic:setVisible(true)
						--local pic_view = uikits.child(self._widget,ui.PIC_VIEW)
						per_title_view:addChild(new_pic)
						button_pic = ccui.Button:create()
						button_pic:setTouchEnabled(true)
						button_pic.pic_name = pic_table[i]
						button_pic:loadTextures(button_empty_path, button_empty_path, "")
						button_pic:setPosition(cc.p(s_pic.width/2,s_pic.height/2))        
						button_pic:addTouchEventListener(touchEventPic)
						new_pic:addChild(button_pic)	--]]
						--local cur_pic = uikits.child(per_title_view,ui.PIC_VIEW)
						if i == #pic_table then
--[[							local local_dir = ljshell.getDirectory(ljshell.AppDir)
							local file_path = local_dir.."cache/"..pic_table[i]--]]
							cur_pic:loadTexture(file_path)	
							local view_tu = uikits.child(per_title_view,ui.VIEW_TU)
							local s_tu_view = view_tu:getContentSize()
							local s_pic = cur_pic:getContentSize()
							cur_pic:setScale(s_tu_view.height/s_pic.height)	
									
							button_pic = ccui.Button:create()
							button_pic:setTouchEnabled(true)
							button_pic.pic_name = pic_table
							button_pic:loadTextures(button_empty_path, button_empty_path, "")
							button_pic:setPosition(cc.p(s_tu_view.width/2,s_tu_view.height/2))        
							button_pic:addTouchEventListener(touchEventPic)
							view_tu:addChild(button_pic)						
						end
					else
						kits.log("ERROR :  download_pic_url failed")
					end
					is_loading = false
					loadbox:removeFromParent()
				end,pic_table[i])	
		end	
	end
end

local title_space_shu = 40 
local title_space_heng = 20 
local status_change_url = 'http://app.lejiaolexue.com/exerbook2/do.ashx?'
local item_del_url = 'http://app.lejiaolexue.com/exerbook2/del.ashx?'

function ErrorTitlePerView:show_title(is_has_title)
	local view_title = 	uikits.child(self._widget,ui.VIEW_TITLE)
	local per_title_src = uikits.child(self._widget,ui.PER_TITLE_VIEW)
	--view_title:setVisible(false)
	local function cleartitle()
		local titleview = view_title:getChildren()
		for i,obj in pairs(titleview) do
			if obj:getTag() >100000 then
				obj:removeFromParent()
			end
		end
		local view_title = 	uikits.child(self._widget,ui.VIEW_TITLE)
		view_title:setInnerContainerSize(view_title:getContentSize())
	end
	
	self:settitlecount()
	if is_has_title == false then
		cleartitle()
		self.totalcount = 0
		self.totalpagecount = 1
		self:show_emptyview_type(true)
	else
		if self.page_index == 1 then
			cleartitle()
			local size_per_view = per_title_src:getContentSize()
			local size_title_view = view_title:getContentSize()
			local row_num = #self.title_table/2	
			row_num = math.ceil(row_num)
		--	local row_num = #self.title_table
			view_title:setInnerContainerSize(cc.size(size_per_view.width,(size_per_view.height+title_space_shu)*row_num))
			for i,v in pairs(self.title_table) do
				local cur_title_view
				cur_title_view = per_title_src:clone()

--[[				local but_del = uikits.child(cur_title_view,ui.BUTTON_DEL)
				but_del.id = v.id
				uikits.event(but_del,	
					function(sender,eventType)	
						local send_url = item_del_url..'id='..sender.id
						if login.get_uid_type() ~= login.STUDENT then
							send_url = send_url..'&user_id='..login.get_subuid()
						end
						local loadbox = loadingbox.open(self)
						is_loading = true
						self._empty:setVisible(false)
						cache.request_json( send_url,function(t)
							if t and type(t)=='table' then
								if t.result ~= 0 then
									is_loading = false
									loadbox:removeFromParent()
									return false
								else
									self.page_index = 1
									self:getdatabyurl()						
								end
							else
								--既没有网络也没有缓冲
								messagebox.open(self,function(e)
									if e == messagebox.TRY then
										self:adderrortitle()
									elseif e == messagebox.CLOSE then
										uikits.popScene()
									end
								end,messagebox.RETRY)	
							end
							is_loading = false
							loadbox:removeFromParent()
						end,'N')			
				end)		--]]
				
				local but_status = uikits.child(cur_title_view,ui.BUTTON_STA_HUI)
				but_status.id = v.id
				if v.status == 1 then
					but_status:setSelectedState(true)
				elseif v.status == 2 then
					but_status:setSelectedState(false)
				end
				uikits.event(but_status,	
					function(sender,eventType)	
						local send_url = status_change_url..'id='..sender.id
						if login.get_uid_type() ~= login.STUDENT then
							send_url = send_url..'&user_id='..login.get_subuid()
						end
						local loadbox = loadingbox.open(self)
						is_loading = true
						self:show_emptyview_type(false)
						cache.request_json( send_url,function(t)
							if t and type(t)=='table' then
								if t.result ~= 0 then
									is_loading = false
									loadbox:removeFromParent()
									return false
								else
									self.page_index = 1
									self:getdatabyurl()						
								end
							else
								--既没有网络也没有缓冲
								messagebox.open(self,function(e)
									if e == messagebox.TRY then
										self:adderrortitle()
									elseif e == messagebox.CLOSE then
										uikits.popScene()
									end
								end,messagebox.RETRY)	
							end
							is_loading = false
							loadbox:removeFromParent()
						end,'N')			
				end)				
				local pic_course 
				if v.course	== 1 then
					pic_course = uikits.child(cur_title_view,ui.PIC_COURSE_CHN)
				elseif v.course	== 2 then
					pic_course = uikits.child(cur_title_view,ui.PIC_COURSE_MATH)
				elseif v.course	== 3 then
					pic_course = uikits.child(cur_title_view,ui.PIC_COURSE_ENG)
				elseif v.course	== 4 then
					pic_course = uikits.child(cur_title_view,ui.PIC_COURSE_OTHER)
				end			
				pic_course:setVisible(true)
				
--[[				local txt_remark = uikits.child(cur_title_view,ui.TXT_REMARK)
				txt_remark:setTouchEnabled(false)
				if v.remark ~= '' then
					txt_remark:setText(v.remark)
				end
				local check_view = uikits.child(cur_title_view,ui.CHECK_VIEW)--]]
				self:show_checkview(cur_title_view,v.reason)
				
				local pic_view = uikits.child(cur_title_view,ui.PIC_VIEW)
				pic_view:setVisible(false)
				self:show_picview(pic_view,v.content,cur_title_view)
				
				local pos_x = cur_title_view:getPositionX()
				if i%2 == 1 then				
				else
					pos_x = pos_x + size_per_view.width+title_space_heng
				end		
				local cur_row = i/2
				cur_row = math.ceil(cur_row)
				
				local pos_y = view_title:getInnerContainerSize().height-(size_per_view.height+ title_space_shu)*cur_row
				cur_title_view:setPositionX(pos_x)		
				cur_title_view:setPositionY(pos_y)	
				cur_title_view:setVisible(true)
								
				view_title:addChild(cur_title_view,1,100000+i)
			end		
		else
			local size_per_view = per_title_src:getContentSize()
			local size_title_view = view_title:getContentSize()
			local row_num = #self.title_table/2	
			row_num = math.ceil(row_num)
			--local row_num = #self.title_table
			
			local size  = per_title_src:getContentSize()	
			
			local size_old = view_title:getInnerContainerSize()
			local count_old = view_title:getChildrenCount()-1
			view_title:setInnerContainerSize(cc.size(size_old.width,size_old.height+(size.height+title_space_shu)*row_num))
			
			local titleview = view_title:getChildren()
			for i,obj in pairs(titleview) do
				local per_size_old_x = titleview[i]:getPositionX()
				local per_size_old_y = titleview[i]:getPositionY()+(size.height+title_space_shu)*row_num
				titleview[i]:setPosition(cc.p(per_size_old_x,per_size_old_y))
				--titleview[i]:setVisible(false)
			end
			for i,v in pairs(self.title_table) do
				local cur_title_view
				cur_title_view = per_title_src:clone()
				
--[[				local but_del = uikits.child(cur_title_view,ui.BUTTON_DEL)
				but_del.id = v.id
				uikits.event(but_del,	
					function(sender,eventType)	
						local send_url = item_del_url..'id='..sender.id
						local loadbox = loadingbox.open(self)
						is_loading = true
						self._empty:setVisible(false)
						cache.request_json( send_url,function(t)
							if t and type(t)=='table' then
								if t.result ~= 0 then
									is_loading = false
									loadbox:removeFromParent()
									return false
								else
									self.page_index = 1
									self:getdatabyurl()						
								end
							else
								--既没有网络也没有缓冲
								messagebox.open(self,function(e)
									if e == messagebox.TRY then
										self:adderrortitle()
									elseif e == messagebox.CLOSE then
										uikits.popScene()
									end
								end,messagebox.RETRY)	
							end
							is_loading = false
							loadbox:removeFromParent()
						end,'N')			
				end)		--]]
				
				local but_status = uikits.child(cur_title_view,ui.BUTTON_STA_HUI)
				--but_del:addTouchEventListener(touchEventHui)
				but_status.id = v.id
				if v.status == 1 then
					but_status:setSelectedState(true)
				elseif v.status == 2 then
					but_status:setSelectedState(false)
				end
				uikits.event(but_status,	
					function(sender,eventType)	
						local send_url = status_change_url..'id='..sender.id
						local loadbox = loadingbox.open(self)
						is_loading = true
						self:show_emptyview_type(false)
						cache.request_json( send_url,function(t)
							if t and type(t)=='table' then
								if t.result ~= 0 then
									is_loading = false
									loadbox:removeFromParent()
									return false
								else
									self.page_index = 1
									self:getdatabyurl()						
								end
							else
								--既没有网络也没有缓冲
								messagebox.open(self,function(e)
									if e == messagebox.TRY then
										self:adderrortitle()
									elseif e == messagebox.CLOSE then
										uikits.popScene()
									end
								end,messagebox.RETRY)	
							end
							is_loading = false
							loadbox:removeFromParent()
						end,'N')			
				end)				
				local pic_course 
				if v.course	== 1 then
					pic_course = uikits.child(cur_title_view,ui.PIC_COURSE_CHN)
				elseif v.course	== 2 then
					pic_course = uikits.child(cur_title_view,ui.PIC_COURSE_MATH)
				elseif v.course	== 3 then
					pic_course = uikits.child(cur_title_view,ui.PIC_COURSE_ENG)
				elseif v.course	== 4 then
					pic_course = uikits.child(cur_title_view,ui.PIC_COURSE_OTHER)
				end			
				pic_course:setVisible(true)
				
--[[				local txt_remark = uikits.child(cur_title_view,ui.TXT_REMARK)
				txt_remark:setTouchEnabled(false)
				if v.remark ~= '' then
					txt_remark:setText(v.remark)
				end
				local check_view = uikits.child(cur_title_view,ui.CHECK_VIEW)--]]
				self:show_checkview(cur_title_view,v.reason)
				
				local pic_view = uikits.child(cur_title_view,ui.PIC_VIEW)
				pic_view:setVisible(false)
				self:show_picview(pic_view,v.content,cur_title_view)

				local pos_x = cur_title_view:getPositionX()
				if i%2 == 1 then				
				else
					pos_x = pos_x + size_per_view.width+title_space_heng
				end		
				local cur_row = i/2
				cur_row = math.ceil(cur_row)
				
				local pos_y = view_title:getInnerContainerSize().height-(size_per_view.height+ title_space_shu)*(cur_row+count_old/2)
				print('pos_y::::'..pos_y)
				cur_title_view:setPositionX(pos_x)		
				cur_title_view:setPositionY(pos_y)	
				cur_title_view:setVisible(true)

--[[				local pos_y = view_title:getInnerContainerSize().height-(size_per_view.height+ title_space_shu)*(i+count_old)	
				cur_title_view:setPositionY(pos_y)	
				cur_title_view:setVisible(true)--]]
								
				view_title:addChild(cur_title_view,1,100000+i+count_old)
			end				
		end

	end
end

function ErrorTitlePerView:show_emptyview_type(is_show)
	local view_no_all = uikits.child(self._widget,ui.VIEW_NO_ALL_STA)
	local view_no_yihui = uikits.child(self._widget,ui.VIEW_NO_YIHUI_STA)
	local view_no_buhui = uikits.child(self._widget,ui.VIEW_NO_BUHUI_STA)
	local view_no_teacher = uikits.child(self._widget,ui.VIEW_NO_TEACHER)
	
	view_no_all:setVisible(false)
	view_no_yihui:setVisible(false)
	view_no_buhui:setVisible(false)	
	view_no_teacher:setVisible(false)
	
	if is_show == true then
		if login.get_uid_type() == login.TEACHER then
			view_no_teacher:setVisible(true)			
		else
			if self.status_index == 0 then --quanbu
				view_no_all:setVisible(true)
			elseif self.status_index == 1 then --buhui
				view_no_buhui:setVisible(true)
			elseif self.status_index == 2 then --yihui
				view_no_yihui:setVisible(true)
			end		
		end
	end
end

function ErrorTitlePerView:settitlecount()
	local txt_err_count = uikits.child(self._widget,ui.TXT_ERR_COUNT)
	txt_err_count:setString(self.totalcount)
end

local get_list_url = 'http://app.lejiaolexue.com/exerbook2/list.ashx?'
--local download_pic_url = 'http://file-stu.lejiaolexue.com/rest/dlimage/'

function ErrorTitlePerView:getdatabyurl()
	local send_url = get_list_url
	send_url = send_url..'range=0'
	send_url = send_url..'&course='..self.course_index
	send_url = send_url..'&status='..self.status_index
--	send_url = send_url..'&status=0'
	send_url = send_url..'&page='..self.page_index
	if login.get_uid_type() ~= login.STUDENT then
		send_url = send_url..'&user_id='..login.get_subuid()
	end
	local loadbox = loadingbox.open(self)
	is_loading = true
	print('send_url:::'..send_url)
	self:show_emptyview_type(false)
	cache.request_json( send_url,function(t)
		if t and type(t)=='table' then
			if t.result ~= 0 then
				print('t.result:::'..t.result..':::t.msg:::'..t.msg)
				if t.result == 1 then
					self:show_title(false)
					is_loading = true
					loadbox:removeFromParent()
					return true
				end
				is_loading = false
				loadbox:removeFromParent()
				return false
			else
				--self.title_table = json.decode(t.list)
				self.title_table = t.list
				self.totalpagecount = t.page_total
				self.totalcount = t.total_count
				self:show_title(true)
			end
		else
			--既没有网络也没有缓冲
			messagebox.open(self,function(e)
				if e == messagebox.TRY then
					self:adderrortitle()
				elseif e == messagebox.CLOSE then
					uikits.popScene()
				end
			end,messagebox.RETRY)	
		end
		is_loading = false
		loadbox:removeFromParent()
	end,'N')
end

function ErrorTitlePerView:init()
	if self.isneedupdate == false then
		self._course_list:setVisible(false)
		self._status_list:setVisible(false)
		self:set_innerpos()
		self.isneedupdate = true
		return
	end
	if uikits.get_factor() == uikits.FACTOR_9_16 then
		uikits.initDR{width=1920,height=1080}
	else
		uikits.initDR{width=1440,height=1080}
	end
	self._widget = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE_3_4}
	self:addChild(self._widget)
	
--[[	local function touchEventClose(sender,eventType)
		if eventType == ccui.TouchEventType.began then
			self._bigpic:setVisible(false)
			local picview = uikits.child(self._bigpic,ui.BIG_PIC)
			picview:removeAllChildren()
		end
	end--]]

--[[	self._bigpic = uikits.fromJson{file_9_16=ui.BIG_PIC_VIEW,file_3_4=ui.BIG_PIC_VIEW_3_4}
	self:addChild(self._bigpic)
	self._bigpic:setVisible(false)--]]

	--local viewbig = uikits.child(self._bigpic,ui.VIEW_BIG)
--[[	local button_close = uikits.child(self._bigpic,ui.CLOSE_BUT)
	button_close:addTouchEventListener(touchEventClose)--]]
	self._course_list = uikits.child(self._widget,ui.COURSE_LIST)
	self._status_list = uikits.child(self._widget,ui.STA_LIST)	
	
	local but_add = uikits.child(self._widget,ui.BUTTON_ADD)
	if login.get_uid_type() == login.TEACHER then
		but_add:setVisible(false)
	end
	
	uikits.event(but_add,	
		function(sender,eventType)	
			self.isneedupdate = true
			local scene_next = adderrorview.create()		
			uikits.pushScene(scene_next)						
	end,"click")
	local but_quit = uikits.child(self._widget,ui.BUTTON_QUIT)
	uikits.event(but_quit,	
		function(sender,eventType)	
			uikits.popScene()						
	end,"click")	
	local view_title = 	uikits.child(self._widget,ui.VIEW_TITLE)

	uikits.event(view_title,
	function(sender,eventType)
		self._course_list:setVisible(false)
		self._status_list:setVisible(false)
		if eventType == ccui.ScrollviewEventType.scrollToBottom then
			if is_loading == false then
				self:updatetitleview()				
			end
		end
	end)	
	self:init_butlist()
	self:getdatabyurl()	
end

function ErrorTitlePerView:updatetitleview()
	
	if self.page_index == self.totalpagecount then
		return
	end
	self.page_index = self.page_index+1
	
	local ret = self:getdatabyurl()
	if ret == false then
		print("Percollectsubject get error!")
		return
	end
end	

function ErrorTitlePerView:release()
	local save_info_tb = {}
	save_info_tb.course_index = self.course_index
	save_info_tb.status_index = self.status_index
	local save_info = json.encode(save_info_tb)
	kits.config("et_init",save_info)
end

return ErrorTitlePerView