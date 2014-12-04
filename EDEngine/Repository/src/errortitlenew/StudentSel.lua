local uikits = require "uikits"
local kits = require "kits"
local json = require "json-c"
local login = require "login"
local cache = require "cache"
local messagebox = require "messagebox"
local loadingbox = require "loadingbox"
local errortitleview = require "errortitlenew/ErrorTitlePerView"
local ljshell = require "ljshell"

local StudentSel = class("StudentSel")
StudentSel.__index = StudentSel
local ui = {
	PStudentSel_FILE = 'errortitlenew/haiz.json',
	PStudentSel_FILE_3_4 = 'errortitlenew/haiz43.json',
	
	VIEW_STU = 'hz1',
	PIC_STU = 'toux',
	TXT_STU = 'ming',
	
	TStudentSel_FILE = 'errortitlenew/banji.json',
	TStudentSel_FILE_3_4 = 'errortitlenew/banji43.json',
	
	VIEW_CLASS_ALL = 'xues',
	VIEW_CLASS_TITLE = 'xues/bj',
	CHECK_JT = 'zk',
	TXT_CLASS_NAME = 'bm',
	
	VIEW_STU_BY_CLASS = 'xues/lb',
	VIEW_PER_STU = 'xs1',
	PIC_STU_T = 'toux',
	TXT_STU_NAME = 'mz',
	TXT_STU_NUM = 'sl',
	
	BUTTON_QUIT = 'mainmenu/fanhui',
}

function create(child_tb)
	local scene = cc.Scene:create()				
	local cur_layer = uikits.extend(cc.Layer:create(),StudentSel)		
	if child_tb then
		cur_layer._child_tb = child_tb
	end
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

local parent_view_space = 20
local button_empty_path = 'errortitlenew/but_stu.png'
local download_log_url = 'http://image.lejiaolexue.com/userlogo/'

function StudentSel:showparentview()
	local view_student = uikits.child(self._StudentSel,ui.VIEW_STU)
	view_student:setVisible(false)
	local size_win = self._StudentSel:getContentSize()
	local size_view_student = view_student:getContentSize()
	local all_student_width = (size_view_student.width * (#self._child_tb)) + (parent_view_space*(#self._child_tb-1))
--	local all_student_width = (size_view_student.width * (3)) + (parent_view_space*(2))
	local pos_x_start = (size_win.width - all_student_width)/2

	local function touchEventPic(sender,eventType)
		if eventType == ccui.TouchEventType.ended then
			login.set_subuid(sender.uid)
			local scene_next = errortitleview.create(sender.name)								
			cc.Director:getInstance():replaceScene(scene_next)			
		end
	end
	
	local function showLogoPic(student_view,logo_pic_path)
		local logo_pic = uikits.child(student_view,ui.PIC_STU)
		logo_pic:loadTexture(file_path)
	end
	
	for i = 1,#self._child_tb do
	--for i = 1,3 do
		local cur_view_student = view_student:clone()
		cur_view_student:setVisible(true)
		local student_name = uikits.child(cur_view_student,ui.TXT_STU)
		student_name:setString(self._child_tb[i].uname)
		cur_view_student:setPositionX(pos_x_start)
		pos_x_start = pos_x_start+size_view_student.width+parent_view_space

		local button_pic = ccui.Button:create()
		button_pic:setTouchEnabled(true)
		button_pic.uid = self._child_tb[i].uid
		button_pic.name = self._child_tb[i].uname
		button_pic:loadTextures(button_empty_path, button_empty_path, "")
		button_pic:setPosition(cc.p(size_view_student.width/2,size_view_student.height/2))        
		button_pic:addTouchEventListener(touchEventPic)
		cur_view_student:addChild(button_pic)	
		self._StudentSel:addChild(cur_view_student)
		local local_dir = ljshell.getDirectory(ljshell.AppDir)
		local file_path = local_dir.."cache/"..self._child_tb[i].uid..'.jpg'
		if kits.exist_file(file_path) then
			showLogoPic(cur_view_student,file_path)
		else
			local send_url = download_log_url..self._child_tb[i].uid..'/99'
			cache.request_nc(send_url,
			function(b,t)
					if b then
						showLogoPic(cur_view_student,file_path)
					else
						kits.log("ERROR :  download_pic_url failed")
					end
					is_loading = false
					loadbox:removeFromParent()
				end,self._child_tb[i].uid..'.jpg')			
		end
	end
end

local get_class_url = 'http://api.lejiaolexue.com/rest/user/'
local get_stu_url = 'http://api.lejiaolexue.com/rest/zone/'
local get_uesr_info_url = 'http://api.lejiaolexue.com/rest/userinfo/simple/'
local class_space = 10
local student_space = 10


function StudentSel:update_view()
	local view_class_all = uikits.child(self._StudentSel,ui.VIEW_CLASS_ALL)
	local tb_view = view_class_all:getChildren()
	local view_len = 0
	for i=#tb_view,1,-1 do
--	for i=1 ,#tb_view do
		if tb_view[i]:isVisible() == true then
			view_len = view_len + tb_view[i]:getContentSize().height + class_space
		end
	end
	local size_scroll = view_class_all:getInnerContainerSize()

	if size_scroll.height < view_len then
		size_scroll.height = view_len
	end
	--print('size_scroll.height::'..size_scroll.height)
	view_class_all:setInnerContainerSize(size_scroll)
	local posy = size_scroll.height
	for i=1 ,#tb_view do
		if tb_view[i]:isVisible() == true then
			if cc_type(tb_view[i])=='ccui.Button' then
				posy = posy - tb_view[i]:getContentSize().height-class_space
				tb_view[i]:setPositionY(posy + tb_view[i]:getContentSize().height/2)
				if tb_view[i].student_view:isVisible() == true then
					posy = posy - tb_view[i].student_view:getContentSize().height-class_space
					tb_view[i].student_view:setPositionY(posy)
				end
			end
		end
	end
end

function StudentSel:show_class(class_tb)
	local view_class_all = uikits.child(self._StudentSel,ui.VIEW_CLASS_ALL)
	local classtitle_src = uikits.child(self._StudentSel,ui.VIEW_CLASS_TITLE)
	local student_view = uikits.child(self._StudentSel,ui.VIEW_STU_BY_CLASS)
	local size_view_class_all = view_class_all:getContentSize()
	local size_view_class = classtitle_src:getContentSize()
	local pos_y_start = classtitle_src:getPositionY()
	classtitle_src:setVisible(false)
	student_view:setVisible(false)

	local function touchEventPic(sender,eventType)
		if eventType == ccui.TouchEventType.ended then
			login.set_subuid(sender.uid)
			local scene_next = errortitleview.create(sender.name)								
			cc.Director:getInstance():replaceScene(scene_next)			
		end
	end

	local function show_student(cur_student_view,student_tb)
		local per_student_src = uikits.child(cur_student_view,ui.VIEW_PER_STU)
		per_student_src:setVisible(false)
		local size_per_student = per_student_src:getContentSize()
		local size_student_all = cur_student_view:getContentSize()
		local num_in_row_real = (size_student_all.width-student_space)/(size_per_student.width+student_space)
		local num_in_row = math.ceil(num_in_row_real)
		if num_in_row > num_in_row_real then
			num_in_row = num_in_row - 1
		end
		local row_num = #student_tb/num_in_row
		--local row_num = 45/num_in_row
		row_num = math.ceil(row_num)
		cur_student_view:setContentSize(cc.size(size_student_all.width,(size_per_student.height+student_space)*row_num))		
		size_student_all = cur_student_view:getContentSize()
		local pos_x_start = student_space
		local pos_y_start = size_student_all.height-(size_per_student.height+student_space)
		
		for j = 1,#student_tb do
		--for j = 1,45 do
			local cur_student = per_student_src:clone()
			cur_student_view:addChild(cur_student)
			cur_student:setVisible(true)
			cur_student:setPosition(cc.p(pos_x_start,pos_y_start))
			if pos_x_start+(size_per_student.width+student_space)*2 < size_student_all.width-student_space then
				pos_x_start = pos_x_start+size_per_student.width+student_space
			else
				pos_x_start = student_space
				pos_y_start = pos_y_start - size_per_student.height-student_space
			end

			local pic_student = uikits.child(cur_student,ui.PIC_STU_T)
			local txt_student_name = uikits.child(cur_student,ui.TXT_STU_NAME)
			local txt_num = uikits.child(cur_student,ui.TXT_STU_NUM)
			txt_num:setVisible(false)
			local send_url
			local local_dir = ljshell.getDirectory(ljshell.AppDir)
			local file_path = local_dir.."cache/"..student_tb[j].user_id..'.jpg'
			if kits.exist_file(file_path) then
				pic_student:loadTexture(file_path)
			else
				send_url = download_log_url..student_tb[j].user_id..'/99'
				cache.request_nc(send_url,
				function(b,t)
						if b then
							pic_student:loadTexture(file_path)
						else
							kits.log("ERROR :  download_pic_url failed")
						end
					end,student_tb[j].user_id..'.jpg')			
			end
			send_url = get_uesr_info_url..student_tb[j].user_id
			cache.request_json( send_url,function(t)
				if t and type(t)=='table' then
					if 	t.result ~= 0 then				
						print(t.result.." : "..t.message)			
					else
						if t.uig[1] then
							txt_student_name:setString(t.uig[1].uname)
							local button_pic = ccui.Button:create()
							button_pic:setTouchEnabled(true)
							button_pic.uid = student_tb[j].user_id
							button_pic.name = t.uig[1].uname
							button_pic:loadTextures(button_empty_path, button_empty_path, "")
							button_pic:setPosition(cc.p(size_per_student.width/2,size_per_student.height/2))        
							button_pic:addTouchEventListener(touchEventPic)
							cur_student:addChild(button_pic)	
						end
					end	
				else
					--既没有网络也没有缓冲
					messagebox.open(self,function(e)
						if e == messagebox.TRY then
							self:getdatabyparent()
						elseif e == messagebox.CLOSE then
							uikits.popScene()
						end
					end,messagebox.RETRY)	
				end
			end,'N')
		end
	end
	
	for i = 1,#class_tb do
		local cur_classtitle = classtitle_src:clone()
		cur_classtitle:setVisible(true)
		local class_name = uikits.child(cur_classtitle,ui.TXT_CLASS_NAME)
		local check_jt = uikits.child(cur_classtitle,ui.CHECK_JT)
		class_name:setString(class_tb[i].zone_name)
		cur_classtitle:setPositionY(pos_y_start)
		pos_y_start = pos_y_start - size_view_class.height - class_space
		cur_classtitle.check = check_jt
		local cur_student_view = student_view:clone()
		view_class_all:addChild(cur_student_view)
		cur_classtitle.student_view = cur_student_view
		uikits.event(cur_classtitle,	
			function(sender,eventType)	
				if sender.check:getSelectedState() == true then
					sender.check:setSelectedState(false)
					sender.student_view:setVisible(false)
				else
					sender.check:setSelectedState(true)
					sender.student_view:setVisible(true)
				end
				self:update_view()
			end,"click")
			
		view_class_all:addChild(cur_classtitle)
		local send_url = get_stu_url..class_tb[i].zone_id..'/student/page=1&page_size=200'
		cache.request_json( send_url,function(t)
			if t and type(t)=='table' then
				if 	t.result ~= 0 then				
					print(t.result.." : "..t.message)			
				else
					--cur_student_view:setVisible(true)
					show_student(cur_student_view,t.zm)
				end	
			else
				--既没有网络也没有缓冲
				messagebox.open(self,function(e)
					if e == messagebox.TRY then
						self:getdatabyparent()
					elseif e == messagebox.CLOSE then
						uikits.popScene()
					end
				end,messagebox.RETRY)	
			end
		end,'N')
	end
end

function StudentSel:initteacherview()
	local send_url = get_class_url..login.uid()..'/zone/class'
	local loadbox = loadingbox.open(self)
	cache.request_json( send_url,function(t)
		if t and type(t)=='table' then
			if 	t.result ~= 0 then				
				print(t.result.." : "..t.message)			
			else
				self:show_class(t.zone)
			end	
		else
			--既没有网络也没有缓冲
			messagebox.open(self,function(e)
				if e == messagebox.TRY then
					self:getdatabyparent()
				elseif e == messagebox.CLOSE then
					uikits.popScene()
				end
			end,messagebox.RETRY)	
		end
		loadbox:removeFromParent()
	end,'N')
end

function StudentSel:getdatabyteacher()
	cache.request_json( get_class_url,function(t)
		if t and type(t)=='table' then
			if 	t.result ~= 0 then				
				print(t.result.." : "..t.message)			
			else
				self.childinfo = tb_result.uis
			end	
		else
			--既没有网络也没有缓冲
			messagebox.open(self,function(e)
				if e == messagebox.TRY then
					self:getdatabyparent()
				elseif e == messagebox.CLOSE then
					uikits.popScene()
				end
			end,messagebox.RETRY)	
		end
	end,'N')		
end

function StudentSel:init()	
	if uikits.get_factor() == uikits.FACTOR_9_16 then
		uikits.initDR{width=1920,height=1080}
	else
		uikits.initDR{width=1440,height=1080}
	end
	if login.get_uid_type() == 2 then
		self._StudentSel = uikits.fromJson{file_9_16=ui.PStudentSel_FILE,file_3_4=ui.PStudentSel_FILE_3_4}
		self:addChild(self._StudentSel)
		self:showparentview()
	elseif login.get_uid_type() == 3 then
		self._StudentSel = uikits.fromJson{file_9_16=ui.TStudentSel_FILE,file_3_4=ui.TStudentSel_FILE_3_4}
		self:addChild(self._StudentSel)	
		self:initteacherview()
	end
	local but_quit = uikits.child(self._StudentSel,ui.BUTTON_QUIT)
	uikits.event(but_quit,	
		function(sender,eventType)	
			uikits.popScene()						
	end,"click")	
--	local loadbox = StudentSelbox.open(self)
--	local scene_next = WrongSubjectList.create()								
--	cc.Director:getInstance():replaceScene(scene_next)	

end

function StudentSel:release()

end
return {
create = create,
}