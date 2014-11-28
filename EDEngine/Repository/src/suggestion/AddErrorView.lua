local crash = require "crash"
local uikits = require "uikits"
local cache = require "cache"
local kits = require "kits"
local login = require "login"
local json = require "json-c"
local loadingbox = require "loadingbox"
local editpic = require "errortitlenew/EditPic"
local ljshell = require "ljshell"

local ui = {
	FILE = 'errortitlenew/addtitle_new.json',
	FILE_3_4 = 'errortitlenew/addtitle43_new.json',

	SEL_FLAG = 'Panel_kemu/select3',
	BUTTON_SEL_COURSE_MATH = 'Panel_kemu/shuxue',
	BUTTON_SEL_COURSE_CHN = 'Panel_kemu/yuwen',
	BUTTON_SEL_COURSE_ENG = 'Panel_kemu/yinyu',
	BUTTON_SEL_COURSE_OTHER = 'Panel_kemu/qita',

	TXT_REMARK = 'TextField_31',
	PER_PIC = 'Panel_8_0/Image_sc_all',
	BUTTON_DEL = 'Button_10',
	PIC_VIEW = 'Panel_8_0',
	
	BUTTON_QUIT = 'mainmenu/fanhui',
	BUTTON_ADD = 'mainmenu/Button_wc_0',
	
	BUTTON_SHOW_PIC = 'Button_sctp_0',
	BUTTON_CAMERA_PIC = 'Button_pz_0',
}

local AddErrorView = class("AddErrorView")
AddErrorView.__index = AddErrorView

function AddErrorView.create()
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),AddErrorView)
	scene:addChild(layer)
	layer._piclist = {}
	layer.course_sel = 1
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

function AddErrorView:adderrortitle()
	local send_url = add_title_url
	
	send_url = send_url..'course='..self.course_sel
	send_url = send_url..'&status=1'
	send_url = send_url..'&reason=0'
	local txt_remark = uikits.child(self._widget,ui.TXT_REMARK)	
	self._remark = txt_remark:getStringValue()
	if self._remark then
		send_url = send_url..'&remark='..self._remark
	end
	local pic_table = {}
	for i,v in pairs(self._piclist) do
		pic_table[i] = v.mini_src
	end
	local pic_str = json.encode(pic_table)
	send_url = send_url..'&content='..pic_str
	
	local loadbox = loadingbox.open(self)
	cache.request_json( send_url,function(t)
			if t and type(t)=='table' then
				if t.result ~= 0 then
					loadbox:removeFromParent()
					return false
				else
					print('t.id::'..t.id)
				end
			else
				--��û������Ҳû�л���
				messagebox.open(self,function(e)
					if e == messagebox.TRY then
						self:adderrortitle()
					elseif e == messagebox.CLOSE then
						uikits.popScene()
					end
				end,messagebox.RETRY)	
			end
			loadbox:removeFromParent()
			uikits.popScene()
	end,'NC')
end

local scheduler

function AddErrorView:SetButtonEnabled(is_show)
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

function AddErrorView:init()
	if self.isneedupdate == 1 then
		return
	elseif self.isneedupdate == 2 then
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
			uikits.popScene()						
	end,"click")		
	
	local sel_flag = uikits.child(self._widget,ui.SEL_FLAG)
	local but_sel_course_math = uikits.child(self._widget,ui.BUTTON_SEL_COURSE_MATH)
	local but_sel_course_chn = uikits.child(self._widget,ui.BUTTON_SEL_COURSE_CHN)
	local but_sel_course_eng = uikits.child(self._widget,ui.BUTTON_SEL_COURSE_ENG)
	local but_sel_course_other = uikits.child(self._widget,ui.BUTTON_SEL_COURSE_OTHER)
	
	uikits.event(but_sel_course_chn,	
		function(sender,eventType)	
			self.course_sel = 1
			local posx = sender:getPositionX()
			sel_flag:setPositionX(posx)					
	end,"click")		
	uikits.event(but_sel_course_math,	
		function(sender,eventType)	
			self.course_sel = 2
			local posx = sender:getPositionX()
			sel_flag:setPositionX(posx)					
	end,"click")	
	uikits.event(but_sel_course_eng,	
		function(sender,eventType)	
			self.course_sel = 3
			local posx = sender:getPositionX()
			sel_flag:setPositionX(posx)					
	end,"click")	
	uikits.event(but_sel_course_other,	
		function(sender,eventType)	
			self.course_sel = 4
			local posx = sender:getPositionX()
			sel_flag:setPositionX(posx)					
	end,"click")	
	
	local but_show_pic = uikits.child(self._widget,ui.BUTTON_SHOW_PIC)
	local but_camera_pic = uikits.child(self._widget,ui.BUTTON_CAMERA_PIC)
--[[	uikits.event(but_show_pic,	
		function(sender,eventType)	
			local scene_next = editpic.create(self)		
			uikits.pushScene(scene_next)						
	end,"click")
	uikits.event(but_camera_pic,	
		function(sender,eventType)	
			local scene_next = editpic.create(self)		
			uikits.pushScene(scene_next)						
	end,"click")--]]
	if but_camera_pic then --插入照片
		uikits.event(but_camera_pic,function(sender)
			cc_takeResource(TAKE_PICTURE,function(t,result,res)
					kits.log('type ='..tostring(t)..' result='..tostring(result)..' res='..tostring(res))
					if result == RESULT_OK then
						--file = res
						local b,res = cc_adjustPhoto(res,1024)
						if b then
							local scene_next = editpic.create(self,res)		
							uikits.pushScene(scene_next)	
						else
							messagebox(self,"错误","图像调整失败")
						end
					end
				end)			
		end)	
	end
	if but_show_pic then --从图库插入照�?
		uikits.event(but_show_pic,function(sender)
			cc_takeResource(PICK_PICTURE,function(t,result,res)
					kits.log('type ='..tostring(t)..' result='..tostring(result)..' res='..tostring(res))
					if result == RESULT_OK then
						local b,res = cc_adjustPhoto(res,1024)
						if b then
							local scene_next = editpic.create(self,res)		
							uikits.pushScene(scene_next)	
						else
							messagebox(self,"错误","图像调整失败")
						end
					end					
				end)			
		end)	
	end		
	
	local per_pic_src = uikits.child(self._widget,ui.PER_PIC)
	per_pic_src:setVisible(false)
	scheduler = cc.Director:getInstance():getScheduler()
end

local download_pic_url = 'http://file-stu.lejiaolexue.com/rest/dlimage/'
local pic_space = 10
local schedulerEntry 
function AddErrorView:update_info()
	
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
	local per_pic_src = uikits.child(self._widget,ui.PER_PIC)
	if #self._piclist >0 then
		local add_pic = self._piclist[#self._piclist]
		cache.request_nc(download_pic_url..add_pic.mini_src..'/192_192',
		function(b,t)
				if b then
					local new_pic = per_pic_src:clone()
					local local_dir = ljshell.getDirectory(ljshell.AppDir)
					local file_path = local_dir.."cache/"..add_pic.mini_src
					new_pic:loadTexture(file_path)
					local s_pic = new_pic:getContentSize()
					local x_pic = new_pic:getPositionX()
					x_pic = x_pic + (pic_space+s_pic.width)*(#self._piclist-1)
					new_pic:setPositionX(x_pic)
					new_pic:setVisible(true)
					local but_del = uikits.child(new_pic,ui.BUTTON_DEL)
					but_del.index = #self._piclist
					but_del:addTouchEventListener(touchEventDel)
					local pic_view = uikits.child(self._widget,ui.PIC_VIEW)
					pic_view:addChild(new_pic,1,10000+#self._piclist)
				else
					kits.log("ERROR :  download_pic_url failed")
				end
			end,add_pic.mini_src)
	end
--[[	
	if self._remark then
		local txt_remark = uikits.child(self._widget,ui.TXT_REMARK)	
		txt_remark:setString(self._remark)	
	end
	local per_course_but = uikits.child(self._widget,ui.BUTTON_SEL_COURSE_CHN)
	local but_size = per_course_but:getContentSize()
	local sel_flag = uikits.child(self._widget,ui.SEL_FLAG)
	local posx = sel_flag:getPositionX()
	posx = posx + (self.course_sel -1)*but_size.width
	sel_flag:setPositionX(posx)	--]]
end

function AddErrorView:release()
	
end

return AddErrorView