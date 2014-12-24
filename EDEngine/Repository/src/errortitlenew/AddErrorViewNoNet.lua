local crash = require "crash"
local uikits = require "uikits"
local cache = require "cache"
local kits = require "kits"
local login = require "login"
local json = require "json-c"
local loadingbox = require "loadingbox"
local messagebox_ = require "messagebox"
local editpic = require "errortitlenew/EditPicNoNet"
local ljshell = require "ljshell"

local ui = {
	FILE = 'errortitlenew/tian.json',
	FILE_3_4 = 'errortitlenew/tian43.json',

	BUTTON_QUIT = 'mainmenu/fanhui',
	BUTTON_ADD = 'mainmenu/wanc',

	VIEW_EMPTY = 'jia1',
	BUTTON_TO_CHOOSE = 'jia1/jia',
	
	VIEW_PIC_CHOOSE = 'tan',
	BUTTON_SHOW_PIC = 'tan/xianche',
	BUTTON_CAMERA_PIC = 'tan/xiangji',	
	BUTTON_HIDE = 'tan/tui',	
	
	VIEW_PIC_HAS = 'wan',
	CHECK_SEL_COURSE_MATH = 'wan/kemu/shuxue',
	CHECK_SEL_COURSE_CHN = 'wan/kemu/yuwen',
	CHECK_SEL_COURSE_ENG = 'wan/kemu/yiny',
	CHECK_SEL_COURSE_OTHER = 'wan/kemu/zh',

	CHECK_SEL_REASON_CUXIN = 'wan/yuanyin/chux',
	CHECK_SEL_REASON_LIJIE = 'wan/yuanyin/lijie',
	CHECK_SEL_REASON_GAINIAN = 'wan/yuanyin/mohu',
	CHECK_SEL_REASON_BUHUI = 'wan/yuanyin/buhui',
	CHECK_SEL_REASON_JISUAN = 'wan/yuanyin/cuow',
	CHECK_SEL_REASON_QITA = 'wan/yuanyin/qit',

	ALL_SHOW_PIC_VIEW = 'wan/tu',
	PIC_VIEW = 'wan/tu/tu1',
	PER_PIC = 'Image_68',
	
	ADD_VIEW = 'wan/tu/tu_add',
	BUTTON_ADD_PIC = 'wan/tu/tu_add/jia'
}

local AddErrorViewNoNet = class("AddErrorViewNoNet")
AddErrorViewNoNet.__index = AddErrorViewNoNet

function AddErrorViewNoNet.create(parent_view)
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),AddErrorViewNoNet)
	scene:addChild(layer)
	layer._parent_view = parent_view
	layer._piclist = {}
	layer.course_sel = 1
	layer.reason_sel = 1
	layer._remark = nil
	layer.isneedupdate = 0
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

local add_title_url = 'http://app.lejiaolexue.com/exerbook2/add.ashx?'

function AddErrorViewNoNet:adderrortitle()
	self._parent_view.isneedupdate = true

	local pic_table = {}
	for i,v in pairs(self._piclist) do
		pic_table[i] = v.file_path
	end
	
	local config_file_name = os.time()..'.json'
	
	local pic_str = json.encode(pic_table)
	kits.write_local_file('errortitle/'..config_file_name,pic_str)
	
	local cur_title_info = {}
	cur_title_info.course = self.course_sel
	cur_title_info.status = 1
	cur_title_info.reason = self.reason_sel
	cur_title_info.content = config_file_name
	local all_title_info_str = kits.read_local_file('errortitle/config.json')
	local all_title_info_tb = {}
	if all_title_info_str then
		all_title_info_tb = json.decode(all_title_info_str)
	end
	cur_title_info.id = #all_title_info_tb+1
	all_title_info_tb[#all_title_info_tb+1] = cur_title_info
	all_title_info_str = json.encode(all_title_info_tb)
	kits.write_local_file('errortitle/config.json',all_title_info_str)
	
	uikits.popScene()
	
end

local scheduler

function AddErrorViewNoNet:SetButtonEnabled(is_show)
	local but_add = uikits.child(self._widget,ui.BUTTON_ADD)	
	if is_show == true then
		but_add:setEnabled(true)
		but_add:setBright(true)
		but_add:setTouchEnabled(true)
	else
		but_add:setEnabled(false)
		but_add:setBright(false)
		but_add:setTouchEnabled(false)	
	end
end

local TYPE_EMPTY = 1
local TYPE_PIC_HAS = 2
local TYPE_SHOW_CHOOSE = 3
local TYPE_HIDE_CHOOSE = 4

local INDEX_COURSE_CHN = 1
local INDEX_COURSE_MATH = 2
local INDEX_COURSE_ENG = 3
local INDEX_COURSE_OTHER = 4

local INDEX_REASON_CUXIN = 1
local INDEX_REASON_LIJIE = 2
local INDEX_REASON_GAINIAN = 3
local INDEX_REASON_BUHUI = 4
local INDEX_REASON_JISUAN = 5
local INDEX_REASON_QITA = 6

function AddErrorViewNoNet:set_view_type(type_index)
	if type_index == TYPE_EMPTY then
		self._view_empty:setVisible(true)
		self._view_pic_choose:setVisible(false)
		self._view_pic_has:setVisible(false)
	elseif type_index == TYPE_PIC_HAS then
		self._view_empty:setVisible(false)
		self._view_pic_choose:setVisible(false)
		self._view_pic_has:setVisible(true)		
	elseif type_index == TYPE_SHOW_CHOOSE then
		self._view_pic_choose:setVisible(true)
		self._view_empty:setEnabled(false)
		self._view_pic_has:setEnabled(false)
	elseif type_index == TYPE_HIDE_CHOOSE then
		self._view_pic_choose:setVisible(false)
		self._view_empty:setEnabled(true)
		self._view_pic_has:setEnabled(true)
	end
end

function AddErrorViewNoNet:init_gui_fun()
	
	local save_info = kits.config("et_add",'get')
	if save_info then
		local save_info_tb = json.decode(save_info)
		self.course_sel = save_info_tb.course_sel
	end
	
	local but_to_show_choose = uikits.child(self._widget,ui.BUTTON_TO_CHOOSE)
	uikits.event(but_to_show_choose,	
	function(sender,eventType)	
		self:set_view_type(TYPE_SHOW_CHOOSE)				
	end,"click")
		
	local but_show_pic = uikits.child(self._widget,ui.BUTTON_SHOW_PIC)
	local but_camera_pic = uikits.child(self._widget,ui.BUTTON_CAMERA_PIC)
	local but_hide = uikits.child(self._widget,ui.BUTTON_HIDE)
	uikits.event(but_hide,	
	function(sender,eventType)	
		self:set_view_type(TYPE_HIDE_CHOOSE)				
	end,"click")
--[[	
	uikits.event(but_show_pic,	
		function(sender,eventType)	
			local scene_next = editpic.create(self)		
			uikits.pushScene(scene_next)						
	end,"click")
	uikits.event(but_camera_pic,	
		function(sender,eventType)	
			local scene_next = editpic.create(self)		
			uikits.pushScene(scene_next)						
	end,"click")--]]
	
	local function messagebox(parent,title,text )
		messagebox_.open(parent,function()end,messagebox_.MESSAGE,tostring(title),tostring(text) )
	end

	if but_camera_pic then --zhaoxiang
		uikits.event(but_camera_pic,function(sender)
			cc_takeResource(TAKE_PICTURE,function(t,result,res)
					kits.log('type ='..tostring(t)..' result='..tostring(result)..' res='..tostring(res))
					if result == RESULT_OK then
						local b,newRes = cc_adjustPhoto(res,1280)
						--kits.del_file( res )
						if b then
							local scene_next = editpic.create(self,newRes,res)		
							uikits.pushScene(scene_next)	
						else
							messagebox(self,"错误","请检查拍照设备是否正常")
						end
					elseif result == RESULT_ERROR then
						messagebox(self,"错误","请检查设备是否正常")
					end
				end)			
		end)	
	end
	if but_show_pic then --tuku xuanqu
		uikits.event(but_show_pic,function(sender)
			cc_takeResource(PICK_PICTURE,function(t,result,res)
					kits.log('type ='..tostring(t)..' result='..tostring(result)..' res='..tostring(res))
					if result == RESULT_OK then
						local b,newRes = cc_adjustPhoto(res,1280)
						--kits.del_file( res )
						if b then
							local scene_next = editpic.create(self,newRes,res)		
							uikits.pushScene(scene_next)	
						else
							messagebox(self,"错误","请检查设备是否正常")
						end
					elseif result == RESULT_ERROR then
						messagebox(self,"错误","请检查设备是否正常")
					end					
				end)			
		end)	
	end		 
	
	local but_sel_course_math = uikits.child(self._widget,ui.CHECK_SEL_COURSE_MATH)
	local but_sel_course_chn = uikits.child(self._widget,ui.CHECK_SEL_COURSE_CHN)
	local but_sel_course_eng = uikits.child(self._widget,ui.CHECK_SEL_COURSE_ENG)
	local but_sel_course_other = uikits.child(self._widget,ui.CHECK_SEL_COURSE_OTHER)
	
	but_sel_course_math.index = INDEX_COURSE_MATH
	but_sel_course_chn.index = INDEX_COURSE_CHN
	but_sel_course_eng.index = INDEX_COURSE_ENG
	but_sel_course_other.index = INDEX_COURSE_OTHER
	but_sel_course_chn:setSelectedState(false)
	but_sel_course_math:setSelectedState(false)
	but_sel_course_eng:setSelectedState(false)
	but_sel_course_other:setSelectedState(false)
	if self.course_sel == INDEX_COURSE_CHN then
		but_sel_course_chn:setSelectedState(true)
	elseif self.course_sel == INDEX_COURSE_MATH then
		but_sel_course_math:setSelectedState(true)
	elseif self.course_sel == INDEX_COURSE_ENG then
		but_sel_course_eng:setSelectedState(true)
	elseif self.course_sel == INDEX_COURSE_OTHER then
		but_sel_course_other:setSelectedState(true)
	end	
	
	local function set_checkbox_course(cur_but,is_sel)
		if is_sel == true then
			if self.course_sel == INDEX_COURSE_CHN then
				but_sel_course_chn:setSelectedState(false)
			elseif self.course_sel == INDEX_COURSE_MATH then
				but_sel_course_math:setSelectedState(false)
			elseif self.course_sel == INDEX_COURSE_ENG then
				but_sel_course_eng:setSelectedState(false)
			elseif self.course_sel == INDEX_COURSE_OTHER then
				but_sel_course_other:setSelectedState(false)
			end
			self.course_sel = cur_but.index
		else
			if cur_but.index == self.course_sel then
				cur_but:setSelectedState(true)
			end
		end
	end
	
	uikits.event(but_sel_course_chn,	
		function(sender,eventType)	
			set_checkbox_course(sender,eventType)
	end)		
	uikits.event(but_sel_course_math,	
		function(sender,eventType)	
			set_checkbox_course(sender,eventType)
	end)	
	uikits.event(but_sel_course_eng,	
		function(sender,eventType)	
			set_checkbox_course(sender,eventType)
	end)	
	uikits.event(but_sel_course_other,	
		function(sender,eventType)	
			set_checkbox_course(sender,eventType)
	end)	
	
	local check_sel_reason_cuxin = uikits.child(self._widget,ui.CHECK_SEL_REASON_CUXIN)
	local check_sel_reason_lijie = uikits.child(self._widget,ui.CHECK_SEL_REASON_LIJIE)
	local check_sel_reason_gainian = uikits.child(self._widget,ui.CHECK_SEL_REASON_GAINIAN)
	local check_sel_reason_buhui = uikits.child(self._widget,ui.CHECK_SEL_REASON_BUHUI)
	local check_sel_reason_jisuan = uikits.child(self._widget,ui.CHECK_SEL_REASON_JISUAN)
	local check_sel_reason_qita = uikits.child(self._widget,ui.CHECK_SEL_REASON_QITA)

	check_sel_reason_cuxin.index = INDEX_REASON_CUXIN
	check_sel_reason_lijie.index = INDEX_REASON_LIJIE
	check_sel_reason_gainian.index = INDEX_REASON_GAINIAN
	check_sel_reason_buhui.index = INDEX_REASON_BUHUI
	check_sel_reason_jisuan.index = INDEX_REASON_JISUAN
	check_sel_reason_qita.index = INDEX_REASON_QITA
	
	check_sel_reason_cuxin:setSelectedState(true)
	
	local function set_checkbox_reason(cur_but,is_sel)
		if is_sel == true then
			if self.reason_sel == INDEX_REASON_CUXIN then
				check_sel_reason_cuxin:setSelectedState(false)
			elseif self.reason_sel == INDEX_REASON_LIJIE then
				check_sel_reason_lijie:setSelectedState(false)
			elseif self.reason_sel == INDEX_REASON_GAINIAN then
				check_sel_reason_gainian:setSelectedState(false)
			elseif self.reason_sel == INDEX_REASON_BUHUI then
				check_sel_reason_buhui:setSelectedState(false)
			elseif self.reason_sel == INDEX_REASON_JISUAN then
				check_sel_reason_jisuan:setSelectedState(false)
			elseif self.reason_sel == INDEX_REASON_QITA then
				check_sel_reason_qita:setSelectedState(false)
			end
			self.reason_sel = cur_but.index
		else
			if cur_but.index == self.reason_sel then
				cur_but:setSelectedState(true)
			end
		end
	end
	
	uikits.event(check_sel_reason_cuxin,	
		function(sender,eventType)	
			set_checkbox_reason(sender,eventType)
	end)		
	uikits.event(check_sel_reason_lijie,	
		function(sender,eventType)	
			set_checkbox_reason(sender,eventType)
	end)	
	uikits.event(check_sel_reason_gainian,	
		function(sender,eventType)	
			set_checkbox_reason(sender,eventType)
	end)	
	uikits.event(check_sel_reason_buhui,	
		function(sender,eventType)	
			set_checkbox_reason(sender,eventType)
	end)	
	uikits.event(check_sel_reason_jisuan,	
		function(sender,eventType)	
			set_checkbox_reason(sender,eventType)
	end)	
	uikits.event(check_sel_reason_qita,	
		function(sender,eventType)	
			set_checkbox_reason(sender,eventType)
	end)	
	
	local view_add = uikits.child(self._widget,ui.ADD_VIEW)
	view_add:setVisible(true)	
	local but_add_pic = uikits.child(self._widget,ui.BUTTON_ADD_PIC)
	uikits.event(but_add_pic,	
	function(sender,eventType)	
		self:set_view_type(TYPE_SHOW_CHOOSE)				
	end,"click")	
	
	local view_pic = uikits.child(self._widget,ui.PIC_VIEW)
	view_pic:setVisible(false)	
end

function AddErrorViewNoNet:init()
	if self.isneedupdate == 1 then
		self:set_view_type(TYPE_HIDE_CHOOSE)
		return
	elseif self.isneedupdate == 2 then
		self:set_view_type(TYPE_HIDE_CHOOSE)
		self:update_info()
		self:SetButtonEnabled(true)
		return
	end
	if uikits.get_factor() == uikits.FACTOR_9_16 then
		uikits.initDR{width=1920,height=1080}
	else
		uikits.initDR{width=1440,height=1080}
	end
	self._widget = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE_3_4}
	self:addChild(self._widget)
	
	local but_add = uikits.child(self._widget,ui.BUTTON_ADD)	
	self:SetButtonEnabled(false)
	uikits.event(but_add,	
	function(sender,eventType)	
		self:adderrortitle()				
	end,"click")
	
	local but_quit = uikits.child(self._widget,ui.BUTTON_QUIT)
	uikits.event(but_quit,	
		function(sender,eventType)	
			self._parent_view.isneedupdate = false
			uikits.popScene()						
	end,"click")		
	
	self._view_empty = uikits.child(self._widget,ui.VIEW_EMPTY)
	self._view_pic_choose = uikits.child(self._widget,ui.VIEW_PIC_CHOOSE)
	self._view_pic_has = uikits.child(self._widget,ui.VIEW_PIC_HAS)
	self:set_view_type(TYPE_EMPTY)
	self:init_gui_fun()
	
--[[		
	local per_pic_src = uikits.child(self._widget,ui.PER_PIC)
	per_pic_src:setVisible(false)
	scheduler = cc.Director:getInstance():getScheduler()--]]
end

--local download_pic_url = 'http://file-stu.lejiaolexue.com/rest/dlimage/'
local download_pic_url = 'http://file-stu.lejiaolexue.com/rest/dl/'
local pic_space = 10
local schedulerEntry 
function AddErrorViewNoNet:update_info()
	
	local function timer_update(time)
		local pic_view = uikits.child(self._widget,ui.PIC_VIEW)
		pic_view:removeChildByTag(10000)
		
		if schedulerEntry then
			scheduler:unscheduleScriptEntry(schedulerEntry)
		end
	end
	
	local function touchEventDel(sender,eventType)
		if eventType == ccui.TouchEventType.began then
			local index = sender.index
			local pic_view = uikits.child(self._widget,ui.PIC_VIEW)
			local del_pic = pic_view:getChildByTag(10000+index)
			del_pic:setTag(10000)
			local x_pic = del_pic:getPositionX()
			for i=index+1,#self._piclist do
				if self._piclist[i] then
					self._piclist[i-1] = self._piclist[i]
					local cur_pic = pic_view:getChildByTag(10000+i)
					local pos_temp = cur_pic:getPositionX()					
					cur_pic:setPositionX(x_pic)
					cur_pic:setTag(10000+i-1)
					x_pic = pos_temp
					local but_del = uikits.child(cur_pic,ui.BUTTON_DEL)
					but_del.index = i-1
				end
			end
			self._piclist[#self._piclist] = nil
			if #self._piclist == 0 then
				self:SetButtonEnabled(false)
			end
			schedulerEntry = scheduler:scheduleScriptFunc(timer_update,0.01,false)
		end
	end
	self._view_empty:setVisible(false)
	self._view_pic_has:setVisible(true)		
	
	local per_pic_src = uikits.child(self._widget,ui.PIC_VIEW)
	local view_add = uikits.child(self._widget,ui.ADD_VIEW)
	local size_view_pic = per_pic_src:getContentSize()
	local add_pos_x = 0
	add_pos_x = (pic_space + size_view_pic.width)*#self._piclist
	view_add:setPositionX(add_pos_x)
	
	if #self._piclist >0 then
		local add_pic = self._piclist[#self._piclist]
		local new_pic_view = per_pic_src:clone()
		local new_pic = uikits.child(new_pic_view,ui.PER_PIC)
		local file_path = add_pic.file_path
		new_pic:loadTexture(file_path)
		
		local s_tu_view = new_pic_view:getContentSize()
		local s_pic = new_pic:getContentSize()
		if s_pic.height > s_pic.width then
			new_pic:setScale(s_tu_view.height/s_pic.height)
		else
			new_pic:setScale(s_tu_view.width/s_pic.width)
		end
								
		
		local x_pic = 0
		x_pic = x_pic + (pic_space+size_view_pic.width)*(#self._piclist-1)
		new_pic_view:setPositionX(x_pic)
		new_pic_view:setVisible(true)

		local pic_view = uikits.child(self._widget,ui.ALL_SHOW_PIC_VIEW)
		pic_view:addChild(new_pic_view,1,10000+#self._piclist)
--[[
		cache.request_nc(download_pic_url..add_pic.mini_src,
		function(b,t)
				if b then

				else
					kits.log("ERROR :  download_pic_url failed")
				end
			end,add_pic.mini_src)--]]
	end
end

function AddErrorViewNoNet:release()
	local save_info_tb = {}
	save_info_tb.course_sel = self.course_sel
	local save_info = json.encode(save_info_tb)
	kits.config("et_add",save_info)
end

return AddErrorViewNoNet