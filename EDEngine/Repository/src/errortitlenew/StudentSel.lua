local uikits = require "uikits"
local kits = require "kits"
local json = require "json-c"
local login = require "login"
local cache = require "cache"
local messagebox = require "messagebox"
local errortitleview = require "errortitlenew/ErrorTitlePerView"

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

local get_class_url = 'http://api.lejiaolexue.com/rest/user/145487/zone/class'
local get_stu_url = 'http://api.lejiaolexue.com/rest/zone/145488/student/page=1&page_size=200'
local parent_view_space = 20
local button_empty_path = 'errortitlenew/but_stu.png'
local download_log_url = 'http://image.lejiaolexue.com/userlogo/'

function StudentSel:showparentview()

	local view_student = uikits.child(self._StudentSel,ui.VIEW_STU)
	view_student:setVisible(false)
	local size_win = self._StudentSel:getContentSize()
	local size_view_student = view_student:getContentSize()
	local all_student_width = (size_view_student.width * (#self._child_tb)) + (parent_view_space*(#self._child_tb-1))
	local pos_x_start = (size_win.width - all_student_width)/2

	local function touchEventPic(sender,eventType)
		if eventType == ccui.TouchEventType.ended then
			Errortitle_User_Id = sender.uid
			local scene_next = errortitleview.create(sender.name)								
			cc.Director:getInstance():replaceScene(scene_next)			
		end
	end

	for i = 1,#self._child_tb do
		local cur_view_student = view_student:clone()
		view_student:setVisible(true)
		local student_name = uikits.child(cur_view_student,ui.TXT_STU)
		student_name:setString(self._child_tb[i].uname)
		cur_view_student:setPositionX(pos_x_start)
		pos_x_start = pos_x_start+size_view_student.width+parent_view_space
		
		local button_pic = ccui.Button:create()
		button_pic:setTouchEnabled(true)
		button_pic.uid = self.childinfo[i].uid
		button_pic.name = self.childinfo[i].uname
		button_pic:loadTextures(button_empty_path, button_empty_path, "")
		button_pic:setPosition(cc.p(size_view_student.width/2,size_view_student.height/2))        
		button_pic:addTouchEventListener(touchEventPic)
		cur_view_student:addChild(button_pic)	
		
	end
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
	if Errortitle_User_Type == 2 then
		self._StudentSel = uikits.fromJson{file_9_16=ui.PStudentSel_FILE,file_3_4=ui.PStudentSel_FILE_3_4}
		self:addChild(self._StudentSel)
		self:showparentview()
	elseif Errortitle_User_Type == 3 then
		self._StudentSel = uikits.fromJson{file_9_16=ui.TStudentSel_FILE,file_3_4=ui.TStudentSel_FILE_3_4}
		self:addChild(self._StudentSel)	
		
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