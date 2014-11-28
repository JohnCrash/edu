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
	FILE = 'errortitlenew/main_new.json',
	FILE_3_4 = 'errortitlenew/main43_new.json',

	EMPTY_VIEW = 'errortitlenew/meishouchang.json',
	EMPTY_VIEW_3_4 = 'errortitlenew/meishouchang43.json',
	
	BIG_PIC_VIEW = 'errortitlenew/showpic_new.json',
	BIG_PIC_VIEW_3_4 = 'errortitlenew/showpic43_new.json',
	
	VIEW_BIG = 'mypic_up',
	BIG_PIC = 'mypic_up/my_pic',
	CLOSE_BUT = 'mypic_up/closebox/close',
	
	
	VIEW_CUR_COURSE = 'Panel_44',
	BUTTON_CUR_COURSE_ALL = 'Panel_44/kemu',
	BUTTON_CUR_COURSE_MATH = 'Panel_44/shuxu',
	BUTTON_CUR_COURSE_CHN = 'Panel_44/yuwen',
	BUTTON_CUR_COURSE_ENG = 'Panel_44/yingyu',
	BUTTON_CUR_COURSE_OTHER = 'Panel_44/qita',
	
	COURSE_LIST = 'ListView_kemu_1',
	COURSE_LIST_ALL = 'ListView_kemu_1/Button_49',
	COURSE_LIST_MATH = 'ListView_kemu_1/Button_49_1',
	COURSE_LIST_CHN = 'ListView_kemu_1/Button_49_0',
	COURSE_LIST_ENG = 'ListView_kemu_1/Button_49_1_0',
	COURSE_LIST_OTHER = 'ListView_kemu_1/Button_49_1_1',
	
	CHECK_HUI = 'hui',
--[[	VIEW_CUR_STA = 'Panel_6',
	BUTTON_CUR_STA_ALL = 'Panel_6/Button_zhuangtai_1',
	BUTTON_CUR_STA_YES = 'Panel_6/Button_zhuangtai_yihui',
	BUTTON_CUR_STA_NO = 'Panel_6/Button_zhuangtai_0',--]]
	
--[[	STA_LIST = 'ListView_zhuangtai_0',
	STA_LIST_ALL = 'ListView_zhuangtai_0/Button_49',
	STA_LIST_YES = 'ListView_zhuangtai_0/Button_49_0',
	STA_LIST_NO = 'ListView_zhuangtai_0/Button_49_1',--]]

	BUTTON_QUIT = 'mainmenu/fanhui',
	BUTTON_ADD = 'Button_wc_0',
	
	VIEW_TITLE = 'ScrollView_6',
	PER_TITLE_VIEW = 'ScrollView_6/have_1',
--	VIEW_BUHUI_MAINMENU = 'information',
--	VIEW_YIHUI_MAINMENU = 'information_0',
--	BUTTON_STA_BUHUI = 'information/Button_22',
	BUTTON_STA_HUI = 'huibuhui',
	BUTTON_DEL = 'shanchu',
	
	PIC_COURSE_MATH = 'questions_pic/shuxue',
	PIC_COURSE_CHN = 'questions_pic/yuwen',
	PIC_COURSE_ENG = 'questions_pic/yingyu',
	PIC_COURSE_OTHER = 'questions_pic/qita',
	
	TXT_REMARK = 'TextField_31_0',
	PIC_VIEW = 'Image_sc_all_0',
	
	CHECK_VIEW = 'Panel_44',
	BUTTON_CUXIN = 'Panel_44/careless',
	BUTTON_LIJIE = 'Panel_44/understand',
	BUTTON_GAINIAN = 'Panel_44/vague',
	BUTTON_BUHUI = 'Panel_44/not',
	BUTTON_JISUAN = 'Panel_44/count',
	BUTTON_QITA = 'Panel_44/other',
}

local ErrorTitlePerView = class("ErrorTitlePerView")
ErrorTitlePerView.__index = ErrorTitlePerView

local is_loading

function ErrorTitlePerView.create()
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),ErrorTitlePerView)
	scene:addChild(layer)
	layer.course_index = 0
	layer.status_index = 1
	layer.page_index = 1
	layer.totalpagecount = 0
	layer.isneedupdate = true
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
	local course_list = uikits.child(self._widget,ui.COURSE_LIST)
--	local status_list = uikits.child(self._widget,ui.STA_LIST)
	course_list:setVisible(false)
--	status_list:setVisible(false)
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
	
	but_cur_course_all:setVisible(true)
	but_cur_course_math:setVisible(false)
	but_cur_course_chn:setVisible(false)
	but_cur_course_eng:setVisible(false)
	but_cur_course_other:setVisible(false)
	
	uikits.event(but_cur_course_all,	
		function(sender,eventType)	
			local is_show = course_list:isVisible()	
			if is_show == true then
				course_list:setVisible(false)
			else
				course_list:setVisible(true)
			end	
	end,"click")
	
	uikits.event(but_cur_course_math,	
		function(sender,eventType)	
			local is_show = course_list:isVisible()	
			if is_show == true then
				course_list:setVisible(false)
			else
				course_list:setVisible(true)
			end	
	end,"click")
	
	uikits.event(but_cur_course_chn,	
		function(sender,eventType)	
			local is_show = course_list:isVisible()	
			if is_show == true then
				course_list:setVisible(false)
			else
				course_list:setVisible(true)
			end	
	end,"click")
	
	uikits.event(but_cur_course_eng,	
		function(sender,eventType)	
			local is_show = course_list:isVisible()	
			if is_show == true then
				course_list:setVisible(false)
			else
				course_list:setVisible(true)
			end	
	end,"click")
	
	uikits.event(but_cur_course_other,	
		function(sender,eventType)	
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
	
	local check_status = uikits.child(self._widget,ui.CHECK_HUI)
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
	end)
--[[	local but_cur_status_all = uikits.child(self._widget,ui.BUTTON_CUR_STA_ALL)
	local but_cur_status_yes = uikits.child(self._widget,ui.BUTTON_CUR_STA_YES)
	local but_cur_status_no = uikits.child(self._widget,ui.BUTTON_CUR_STA_NO)
	
	but_cur_status_all:setVisible(true)
	but_cur_status_yes:setVisible(false)
	but_cur_status_no:setVisible(false)
	
	uikits.event(but_cur_status_all,	
		function(sender,eventType)	
			local is_show = status_list:isVisible()	
			if is_show == true then
				status_list:setVisible(false)
			else
				status_list:setVisible(true)
			end	
	end,"click")
	
	uikits.event(but_cur_status_yes,	
		function(sender,eventType)	
			local is_show = status_list:isVisible()	
			if is_show == true then
				status_list:setVisible(false)
			else
				status_list:setVisible(true)
			end	
	end,"click")
	
	uikits.event(but_cur_status_no,	
		function(sender,eventType)	
			local is_show = status_list:isVisible()	
			if is_show == true then
				status_list:setVisible(false)
			else
				status_list:setVisible(true)
			end	
	end,"click")--]]	
	
--[[	local list_status_all = uikits.child(self._widget,ui.STA_LIST_ALL)
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
	end,"click")--]]
end

function ErrorTitlePerView:show_checkview(check_view,title_tabel)
	local check_boxlist = check_view:getChildren()
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
	end
end

local pic_space = 10
local download_pic_url = 'http://file-stu.lejiaolexue.com/rest/dlimage/'
local download_pic_big_url = 'http://file-stu.lejiaolexue.com/rest/dl/'
local button_empty_path = 'errortitlenew/kuang.png'
local inner_posx
local inner_posy

function ErrorTitlePerView:save_innerpos()
	local view_title = 	uikits.child(self._widget,ui.VIEW_TITLE)
	inner_posx,inner_posy = view_title:getInnerContainer():getPosition()
end

function ErrorTitlePerView:set_innerpos()
	local view_title = 	uikits.child(self._widget,ui.VIEW_TITLE)
	view_title:getInnerContainer():setPosition(cc.p(inner_posx,inner_posy))
end

function ErrorTitlePerView:show_picview(pic_view,pic_str,per_title_view)
	
	local function touchEventPic(sender,eventType)
--[[		local file_path = kits.get_local_directory()..'res/errortitlenew/11.jpg'
		local imgs = {}
		imgs[1] = file_path
		--local scene_next = imagepreview.create(1,imgs,self)		
		local scene_next = imagepreview.create()		
		uikits.pushScene(scene_next)--]]	
		if eventType == ccui.TouchEventType.began then
			local loadbox = loadingbox.open(self)
			is_loading = true
			cache.request_nc(download_pic_big_url..sender.pic_name,
			function(b,t)
					if b then
					--	local s_pic = picview:getContentSize()
						self:save_innerpos()	
						local local_dir = ljshell.getDirectory(ljshell.AppDir)
						local file_path = local_dir.."cache/"..sender.pic_name..'1'
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
				end,sender.pic_name..'1')					
		end
	end
	
	local pic_table = json.decode(pic_str)
	for i=1,#pic_table do
		local loadbox = loadingbox.open(self)
		is_loading = true
		cache.request_nc(download_pic_url..pic_table[i]..'/192_192',
		function(b,t)
				if b then
					local new_pic = pic_view:clone()
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
					new_pic:addChild(button_pic)	
				else
					kits.log("ERROR :  download_pic_url failed")
				end
				is_loading = false
				loadbox:removeFromParent()
			end,pic_table[i])		
		
	end
end

local title_space = 20 
local status_change_url = 'http://app.lejiaolexue.com/exerbook2/do.ashx?'
local item_del_url = 'http://app.lejiaolexue.com/exerbook2/del.ashx?'

function ErrorTitlePerView:show_title(is_has_title)
	local view_title = 	uikits.child(self._widget,ui.VIEW_TITLE)
	local per_title_src = uikits.child(self._widget,ui.PER_TITLE_VIEW)

	local function cleartitle()
		local titleview = view_title:getChildren()
		for i,obj in pairs(titleview) do
			if obj:getTag() >10000 then
				obj:removeFromParent()
			end
		end
		local view_title = 	uikits.child(self._widget,ui.VIEW_TITLE)
		view_title:setInnerContainerSize(view_title:getContentSize())
	end
	if is_has_title == false then
		cleartitle()
		self._empty:setVisible(true)
	else
		if self.page_index == 1 then
			cleartitle()
			local size_per_view = per_title_src:getContentSize()
			local size_title_view = view_title:getContentSize()
			local row_num = #self.title_table
			view_title:setInnerContainerSize(cc.size(size_per_view.width,(size_per_view.height+title_space)*row_num))
			for i,v in pairs(self.title_table) do
				local cur_title_view
				cur_title_view = per_title_src:clone()

				local but_del = uikits.child(cur_title_view,ui.BUTTON_DEL)
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
				end)		
				
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
				
				local txt_remark = uikits.child(cur_title_view,ui.TXT_REMARK)
				txt_remark:setTouchEnabled(false)
				if v.remark ~= '' then
					txt_remark:setText(v.remark)
				end
				local check_view = uikits.child(cur_title_view,ui.CHECK_VIEW)
				self:show_checkview(check_view,v)
				
				local pic_view = uikits.child(cur_title_view,ui.PIC_VIEW)
				pic_view:setVisible(false)
				self:show_picview(pic_view,v.content,cur_title_view)

				local pos_y = view_title:getInnerContainerSize().height-(size_per_view.height+ title_space)*i	
				cur_title_view:setPositionY(pos_y)	
				cur_title_view:setVisible(true)
								
				view_title:addChild(cur_title_view,1,10000+i)
			end		
		else
			local row_num = #self.title_table
			
			local size  = view_buhui_src:getContentSize()	
			
			local size_old = view_title:getInnerContainerSize()
			local count_old = view_title:getChildrenCount()-2
			view_title:setInnerContainerSize(cc.size(size_old.width,size_old.height+(size.height+title_space)*row_num))
			view_title.share_box_src = self.share_view:getChildByTag(657)
			
			local titleview = view_title:getChildren()
			for i,obj in pairs(titleview) do
				local per_size_old_x = titleview[i]:getPositionX()
				local per_size_old_y = titleview[i]:getPositionY()+(size.height+title_space)*row_num
				titleview[i]:setPosition(cc.p(per_size_old_x,per_size_old_y))
			end
			for i,v in pairs(self.title_table) do
				local cur_title_view
				cur_title_view = per_title_src:clone()
				local but_del = uikits.child(cur_title_view,ui.BUTTON_DEL)
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
				end)		
				
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
				
				local txt_remark = uikits.child(cur_title_view,ui.TXT_REMARK)
				txt_remark:setTouchEnabled(false)
				if v.remark ~= '' then
					txt_remark:setText(v.remark)
				end
				local check_view = uikits.child(cur_title_view,ui.CHECK_VIEW)
				self:show_checkview(check_view,v)
				
				local pic_view = uikits.child(cur_title_view,ui.PIC_VIEW)
				pic_view:setVisible(false)
				self:show_picview(pic_view,v.content,cur_title_view)

				local pos_y = view_title:getInnerContainerSize().height-(size_per_view.height+ title_space)*(i+count_old)	
				cur_title_view:setPositionY(pos_y)	
				cur_title_view:setVisible(true)
								
				view_title:addChild(cur_title_view,1,10000+i+count_old)
			end				
		end

	end
end

local get_list_url = 'http://app.lejiaolexue.com/exerbook2/list.ashx?'
local download_pic_url = 'http://file-stu.lejiaolexue.com/rest/dlimage/'

function ErrorTitlePerView:getdatabyurl()
	local send_url = get_list_url
	send_url = send_url..'range=0'
	send_url = send_url..'&course='..self.course_index
	send_url = send_url..'&status='..self.status_index
--	send_url = send_url..'&status=0'
	send_url = send_url..'&page='..self.page_index
	local loadbox = loadingbox.open(self)
	is_loading = true
	self._empty:setVisible(false)
	cache.request_json( send_url,function(t)
		if t and type(t)=='table' then
			if t.result ~= 0 then
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
		self:set_innerpos()
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
	
	local but_add = uikits.child(self._widget,ui.BUTTON_ADD)
	uikits.event(but_add,	
		function(sender,eventType)	
			local scene_next = adderrorview.create()		
			uikits.pushScene(scene_next)						
	end,"click")
	local but_quit = uikits.child(self._widget,ui.BUTTON_QUIT)
	uikits.event(but_quit,	
		function(sender,eventType)	
			uikits.popScene()						
	end,"click")	
	local view_title = 	uikits.child(self._widget,ui.VIEW_TITLE)

	self._empty = uikits.fromJson{file_9_16=ui.EMPTY_VIEW,file_3_4=ui.EMPTY_VIEW_3_4}
	local per_title_src = uikits.child(self._widget,ui.VIEW_TITLE)
	view_title:addChild(self._empty)
	self._empty:setVisible(false)
	
	uikits.event(view_title,
	function(sender,eventType)
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
	
	if self.pageindex == self.totalpagecount then
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
	
end

return ErrorTitlePerView