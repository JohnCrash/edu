local crash = require "crash"
local uikits = require "uikits"
local cache = require "cache"
local kits = require "kits"
local login = require "login"
local json = require "json-c"
local loadingbox = require "loadingbox"
local messagebox = require "messagebox"

local ui = {
	FILE = 'errortitlenew/editpic.json',
	FILE_3_4 = 'errortitlenew/editpic43.json',
	PIC_VIEW = 'Pic_view',
	BUTTON_QUIT = 'mainmenu/fanhui',
	BUTTON_ADD = 'mainmenu/quer',
	PIC_KD = 'kd',
	PIC_JT = 'kd/jt',
	BUTTON_ROTA = 'mainmenu/xuan',
}

local EditPic = class("EditPic")
EditPic.__index = EditPic

function EditPic.create(parent_layer,file_path,file_path_src)
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),EditPic)
	scene:addChild(layer)
	layer.parent_layer = parent_layer
	layer.file_path = file_path
	layer.file_path_src = file_path_src
	
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

local rotation_all = 0
local rotation_begain
local scale_all = 1
local scale_begain
local operate_type
local old_operate_type
local change_rect_begain
local move_begain
local old_pos_x
local old_pos_y
local schedulerEntry
local rotation_num =0
local buttonTL
local buttonTR
local buttonBR
local buttonBL
local loadbox
local url = 'http://file-stu.lejiaolexue.com/rest/user/upload/hw'
local temp_filename
local loadbox
function EditPic:uploadpic()
	local local_file = self.file_path
	print('loacl_path::'..local_file)
	print('layer.parent_layer::'..tostring(#self.parent_layer._piclist))
	local data = kits.read_file( local_file )
	if data then
		cache.upload( url,self.file_path,data,
			function(b,t)
				if b then
					if t.result==0 then
						self.parent_layer._piclist[#self.parent_layer._piclist+1] = {}
						self.parent_layer._piclist[#self.parent_layer._piclist].mini_src = t.md5
						self.parent_layer._piclist[#self.parent_layer._piclist].file_path = self.file_path
						self.parent_layer.isneedupdate = 2
						uikits.popScene()
						kits.log("ERROR : AddPic:AddPic upload result invalid::"..t.md5..'::'..t.width..'::'..t.height)
					else
						self.parent_layer.isneedupdate = 1
						uikits.popScene()
						kits.log("ERROR : AddPic:AddPic upload result invalid")
					end
				else
					self.parent_layer.isneedupdate = 1
					uikits.popScene()
					kits.log("ERROR :  AddPic:AddPic upload failed")
					kits.log("	local file "..local_file)
					kits.log("	url "..url)
				end
			end)
	else
		self.parent_layer.isneedupdate = 1
		loadbox:removeFromParent()
		uikits.popScene()
		print('ERROR :  AddPic:AddPic readfile failed')
	end	
end

function EditPic:copyfile(src_file,dest_file)
	local data
	data = kits.read_file(src_file)
	kits.write_file(dest_file,data)
	os.remove(src_file)
end

function EditPic:init()
	if uikits.get_factor() == uikits.FACTOR_9_16 then
		uikits.initDR{width=1920,height=1080}
	else
		uikits.initDR{width=1440,height=1080}
	end
	self._widget = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE_3_4}
	self:addChild(self._widget)

	self._picview = uikits.child(self._widget,ui.PIC_VIEW)
	local scheduler = cc.Director:getInstance():getScheduler()
--	local back_pic = cc.Sprite:create('errortitlenew/11.jpg')
	local s = self._picview:getContentSize()
--	back_pic:setPosition(cc.p(s.width/2,s.height/2))
    local back_pic = ccui.ImageView:create()
--	back_pic:setTouchEnabled(true)
--	self.file_path = kits.get_local_directory()..'res/errortitlenew/11.jpg'
	print('self.file_path::'..self.file_path)
    back_pic:loadTexture(self.file_path)
    back_pic:setPosition(cc.p(s.width/2,s.height/2))
	self._picview:addChild(back_pic,1,10001)
	
--[[	local function touchEventPic(sender,eventType)
		if eventType == ccui.TouchEventType.began then
		elseif eventType == ccui.TouchEventType.moved then
			local pos = sender:getTouchMovePosition()
			local location = self._picview:convertToNodeSpace(pos) 
			if 	operate_type == 1 then
				if scale_begain == nil then
					scale_begain = location
				end
				local pic_x,pic_y = back_pic:getPosition()
				local scale_dis = 5
				local scale_per = 0.1
				local pos_begain = cc.pGetDistance(scale_begain, cc.p(pic_x,pic_y))
				local pos_end = cc.pGetDistance(location, cc.p(pic_x,pic_y))
				if pos_begain > pos_end then
					local t=pos_begain-pos_end
					if t>=scale_dis and scale_all>0.4 then
						scale_all = scale_all-scale_per
						back_pic:setScale(scale_all)
					end
				else
					local t=pos_end-pos_begain
					if t>=scale_dis and scale_all<5 then
						scale_all = scale_all+scale_per
						back_pic:setScale(scale_all)
					end				
				end	
				scale_begain = location	
			elseif operate_type == 8 then
				if move_begain == nil then
					move_begain = location
				end		
				local pic_x,pic_y = back_pic:getPosition()
				pic_x = pic_x+(location.x-move_begain.x)
				pic_y = pic_y+(location.y-move_begain.y)
				back_pic:setPosition(cc.p(pic_x,pic_y))
				move_begain = location	
			end
		elseif eventType == ccui.TouchEventType.ended then
			if operate_type == 1 then
				scale_begain = nil
			elseif operate_type == 8 then
				move_begain = nil
			end	
		end
	end
	
	back_pic:addTouchEventListener(touchEventPic)	--]]
	
	local pic_size = back_pic:getContentSize()
	local x1,x2,y1,y2
	kits.log('pic_size.width::'..pic_size.width..'::s.width::'..pic_size.width)
	if pic_size.width>s.width then
		x1 = 0
		x2 = s.width
	else
		x1 = (s.width-pic_size.width)/2
		x2 = (s.width+pic_size.width)/2
	end
	
	if pic_size.height>s.height then
		y1 = 0
		y2 = s.height
	else
		y1 = (s.height-pic_size.height)/2
		y2 = (s.height+pic_size.height)/2
	end
	
	local sel_rect_size = {x1 = x1,y1 = y1,x2 = x2,y2=y2}
	local sel_rect = uikits.rect{x1 = sel_rect_size.x1,y1 = sel_rect_size.y1,x2 = sel_rect_size.x2,y2=sel_rect_size.y2,color=cc.c3b(255,0,0),fillColor=cc.c4f(0,0,0,0),linewidth=10}

	self._picview:addChild(sel_rect,1000,10000)
	
--[[	local rotation_table = cc.Sprite:create('errortitlenew/kd.png')
	rotation_table:setPosition(cc.p(s.width-100,s.height/2))
	self._picview:addChild(rotation_table,10)--]]
	local rotation_table = uikits.child(self._widget,ui.PIC_KD)
	local function touchEventRota(sender,eventType)
		if eventType == ccui.TouchEventType.moved then
			local pos = sender:getTouchMovePosition()
			local local_pos = rotation_table:convertToNodeSpace(pos) 
			if local_pos.y>sender.maxheight or local_pos.y < 0 then
				return
			end
			local cur_rotation_num = 0-math.ceil((local_pos.y-450)/450*30)
			if cur_rotation_num>0 then
				cur_rotation_num = cur_rotation_num+1
			end
			--rotation_num = rotation_num+cur_rotation_num
			back_pic:setRotation(rotation_num+cur_rotation_num)
			sender:setPositionY(local_pos.y)
		elseif eventType == ccui.TouchEventType.ended then
--[[			rotation_num = back_pic:getRotation()
			print('rotation_num1:::'..rotation_num)--]]
		end
	end

--[[    button_rota = ccui.Button:create()
    button_rota:setTouchEnabled(true)
    button_rota:loadTextures("errortitlenew/jt.png", "errortitlenew/jt.png", "")--]]
	local button_rota = uikits.child(self._widget,ui.PIC_JT)
	local rota_size = rotation_table:getContentSize()
	button_rota.maxheight = rota_size.height
    button_rota:setPosition(cc.p(rota_size.width/2,rota_size.height/2))        
    button_rota:addTouchEventListener(touchEventRota)
 --   rotation_table:addChild(button_rota)	
	
	local function touchEvent(sender,eventType)
        if eventType == ccui.TouchEventType.began then
			
        elseif eventType == ccui.TouchEventType.moved then
			local pos = sender:getTouchMovePosition()
			if sender.scale_but == 1 then
				if pos.y < sel_rect_size.y1 +20 or pos.y > s.height then
					return
				end
				if pos.x > sel_rect_size.x2 -20 or pos.x < 0 then
					return
				end				
				sel_rect_size.x1 = pos.x
				sel_rect_size.y2 = pos.y
			elseif sender.scale_but == 2 then
				if pos.y < sel_rect_size.y1 +20 or pos.y > s.height then
					return
				end
				if pos.x < sel_rect_size.x1 +20 or pos.x > s.width then
					return
				end				
				sel_rect_size.x2 = pos.x
				sel_rect_size.y2 = pos.y
			elseif sender.scale_but == 3 then
				if pos.x < sel_rect_size.x1 +20 or pos.x > s.width then
					return
				end	
				if pos.y > sel_rect_size.y2 -20 or pos.y < 0 then
					return
				end
				sel_rect_size.x2 = pos.x
				sel_rect_size.y1 = pos.y
			elseif sender.scale_but == 4 then
				if pos.x > sel_rect_size.x2 -20 or pos.x < 0 then
					return
				end		
				if pos.y > sel_rect_size.y2 -20 or pos.y < 0 then
					return
				end
				sel_rect_size.x1 = pos.x
				sel_rect_size.y1 = pos.y
			end
			self._picview:removeChildByTag(10000)
			local sel_rect = uikits.rect{x1 = sel_rect_size.x1,y1 = sel_rect_size.y1,x2 = sel_rect_size.x2,y2=sel_rect_size.y2,color=cc.c3b(255,0,0),fillColor=cc.c4f(0,0,0,0),linewidth=10}
			self._picview:addChild(sel_rect,1000,10000)	
			buttonTL:setPosition(cc.p(sel_rect_size.x1,sel_rect_size.y2)) 
			buttonTR:setPosition(cc.p(sel_rect_size.x2,sel_rect_size.y2)) 
			buttonBR:setPosition(cc.p(sel_rect_size.x2,sel_rect_size.y1))  
			buttonBL:setPosition(cc.p(sel_rect_size.x1,sel_rect_size.y1)) 
        elseif eventType == ccui.TouchEventType.ended then
			
        end
    end 	
		
    buttonTL = ccui.Button:create()
    buttonTL:setTouchEnabled(true)
    buttonTL:loadTextures("errortitlenew/jt2.png", "errortitlenew/jt2.png", "")
	buttonTL:setScale(2)
	buttonTL.scale_but = 1
    buttonTL:setPosition(cc.p(sel_rect_size.x1,sel_rect_size.y2))        
    buttonTL:addTouchEventListener(touchEvent)
    self._picview:addChild(buttonTL,1001,10001)

    buttonTR = ccui.Button:create()
    buttonTR:setTouchEnabled(true)
    buttonTR:loadTextures("errortitlenew/jt3.png", "errortitlenew/jt3.png", "")
	buttonTR:setScale(2)
	buttonTR.scale_but = 2
    buttonTR:setPosition(cc.p(sel_rect_size.x2,sel_rect_size.y2))        
    buttonTR:addTouchEventListener(touchEvent)
    self._picview:addChild(buttonTR,1002,10001)

    buttonBR = ccui.Button:create()
    buttonBR:setTouchEnabled(true)
    buttonBR:loadTextures("errortitlenew/jt2.png", "errortitlenew/jt2.png", "")
	buttonBR:setScale(2)
	buttonBR.scale_but = 3
    buttonBR:setPosition(cc.p(sel_rect_size.x2,sel_rect_size.y1))        
    buttonBR:addTouchEventListener(touchEvent)
    self._picview:addChild(buttonBR,1003,10001)
	
    buttonBL = ccui.Button:create()
    buttonBL:setTouchEnabled(true)
    buttonBL:loadTextures("errortitlenew/jt3.png", "errortitlenew/jt3.png", "")
	buttonBL:setScale(2)
	buttonBL.scale_but = 4
    buttonBL:setPosition(cc.p(sel_rect_size.x1,sel_rect_size.y1))        
    buttonBL:addTouchEventListener(touchEvent)
    self._picview:addChild(buttonBL,1004,10001)
	
	local function timer_update(time)
		local cur_sence = cc.Director:getInstance():getRunningScene()
		cur_sence:setPosition(cc.p(old_pos_x,old_pos_y))
		self._picview:removeChildByTag(10000)
		self._picview:removeChildByTag(10001)
		back_pic = ccui.ImageView:create()
		back_pic:setTouchEnabled(false)
		
		self.file_path = kits.get_local_directory()..'cache/'..temp_filename
		local plat_path = cc.FileUtils:getInstance():getWritablePath()..temp_filename
		self:copyfile(plat_path,self.file_path)

		self:uploadpic()			
		if schedulerEntry then
			scheduler:unscheduleScriptEntry(schedulerEntry)
		end
	end
	
	local function Cut_pic1()
		local pic_size_show = back_pic:getContentSize()
		
		local pic_pos_show_x,pic_pos_show_y = back_pic:getPosition()
		local layer_src = cc.Layer:create()
		local pic_src = ccui.ImageView:create()
		pic_src:loadTexture(self.file_path_src)
		local pic_size_src = pic_src:getContentSize()
		
		layer_src:addChild(pic_src)
		
		local scale_show = pic_size_src.width/pic_size_show.width
		local pic_pos_src_x = pic_size_src.width/2+(pic_pos_show_x-s.width/2)*scale_show
		local pic_pos_src_y = pic_size_src.height/2+(pic_pos_show_y-s.height/2)*scale_show
		print('s.width/2::'..s.width/2)
		print('pic_pos_show_x::'..pic_pos_show_x)
		print('pic_pos_src_x::'..pic_pos_src_x)
		
		local rect_w = (sel_rect_size.x2-sel_rect_size.x1)*scale_show
		local rect_h = (sel_rect_size.y2-sel_rect_size.y1)*scale_show
		local sel_range_x = 0
		local sel_range_y = 0
		if s.width/2 - x1 < pic_size_show.width/2 then
			sel_range_x = pic_size_show.width/2 - (s.width/2 - x1)
		end
		if s.height/2 - y1 < pic_size_show.height/2 then
			sel_range_y = pic_size_show.height/2 - (s.height/2 - y1)
		end
		print('sel_range_x::'..sel_range_x)
		sel_range_x = sel_range_x+(sel_rect_size.x1 - x1)
		sel_range_y = sel_range_y+(sel_rect_size.y1 - y1)
		pic_pos_src_x = pic_pos_src_x-sel_range_x*scale_show
		pic_pos_src_y = pic_pos_src_y-sel_range_y*scale_show
		print('sel_range_x::'..sel_range_x)
		print('pic_pos_src_x::'..pic_pos_src_x)
		pic_src:setPosition(cc.p(pic_pos_src_x,pic_pos_src_y))

		pic_src:setScale(back_pic:getScale())
		pic_src:setRotation(back_pic:getRotation())
		
		local texture = cc.RenderTexture:create(rect_w,rect_h)

		texture:begin()
		pic_src:visit()
		texture.my_end = texture["end"]
		texture:my_end()
		temp_filename = os.time()..'.jpg'
		texture:saveToFile(temp_filename, kCCImageFormatJPEG)	
		schedulerEntry = scheduler:scheduleScriptFunc(timer_update,0.01,false)
	end
	
	local function Cut_pic()	
		loadbox = loadingbox.open(self)

		local texture = cc.RenderTexture:create(sel_rect_size.x2-sel_rect_size.x1,sel_rect_size.y2-sel_rect_size.y1)
		local cur_sence = cc.Director:getInstance():getRunningScene()
		old_pos_x,old_pos_y = cur_sence:getPosition()
		cur_sence:setPosition(cc.p(0-sel_rect_size.x1, 0-sel_rect_size.y1))
		texture:begin()
		back_pic:visit()
		texture.my_end = texture["end"]
		texture:my_end()
		--self.file_path = kits.get_local_directory()..'cache/screenshot.png'
		temp_filename = os.time()..'.jpg'
		texture:saveToFile(temp_filename, kCCImageFormatJPEG)		
		schedulerEntry = scheduler:scheduleScriptFunc(timer_update,0.01,false)	
	end
--	button_cutpic:registerScriptTapHandler(Cut_pic)
	
--[[	local menu_rota = cc.Menu:create()
	local button_rota = cc.MenuItemImage:create('errortitlenew/t3.png', 'errortitlenew/t3.png')
	button_rota:setPosition(cc.p(400,100))
	menu_rota:addChild(button_rota)
	menu_rota:setPosition(cc.p(0, 0))
	self._picview:addChild(menu_rota,10)
	local function rota_callback(tag, sender)	
		label_status_cut:setVisible(false)
		label_status_rota:setVisible(true)
		label_status_move:setVisible(false)
		operate_type = 2
	end
	button_rota:setVisible(false)
	button_rota:registerScriptTapHandler(rota_callback)--]]

--[[	local menu_cut = cc.Menu:create()
	local button_cut = cc.MenuItemImage:create('errortitlenew/t4.png', 'errortitlenew/t4.png')
	button_cut:setPosition(cc.p(700,100))
	menu_cut:addChild(button_cut)
	menu_cut:setPosition(cc.p(0, 0))
	self._picview:addChild(menu_cut,10)
	local function cut_callback(tag, sender)	
		label_status_cut:setVisible(true)
		label_status_rota:setVisible(false)
		label_status_move:setVisible(false)
		operate_type = 1
	end
	button_cut:registerScriptTapHandler(cut_callback)--]]

--[[	local menu_move = cc.Menu:create()
	local button_move = cc.MenuItemImage:create('errortitlenew/t5.png', 'errortitlenew/t5.png')
	button_move:setPosition(cc.p(1000,100))
	menu_move:addChild(button_move)
	menu_move:setPosition(cc.p(0, 0))
	self._picview:addChild(menu_move,10)
	local function move_callback(tag, sender)	
		label_status_cut:setVisible(false)
		label_status_rota:setVisible(false)
		label_status_move:setVisible(true)
		operate_type = 8
	end
	button_move:registerScriptTapHandler(move_callback)--]]

--[[	local function onTouchEnded(touches, event)  
		print('3333333333333333')
		if operate_type == 2 then   
			rotation_begain = nil
		elseif operate_type == 1 then
			scale_begain = nil
		elseif operate_type > 2 and operate_type < 7 then
			change_rect_begain = nil
			operate_type = old_operate_type
		elseif operate_type == 8 then
			move_begain = nil
		end
	end--]]
	local newTouch
	local touchAction
	local oldx,oldy,oldscale
	local function onTouchMove(touches, event)  
		local count = #touches
		if count == 1 then
			if not newTouch then return end
			local img = back_pic
			local scale = img:getScaleX()
			local size = img:getContentSize()
			local p = touches[1]:getLocation()
			local sp = touches[1]:getStartLocation()			
			if touchAction == 1 or  touchAction == 3 then
				--偏移
				img:setPosition(cc.p(oldx+(p.x-sp.x),oldy+(p.y-sp.y)))
				touchAction = 3
			end
		elseif count == 2 then
			local p1 = touches[1]:getLocation()
			local sp1 = touches[1]:getStartLocation()
			local p2 = touches[2]:getLocation()
			local sp2 = touches[2]:getStartLocation()		
			local sd = math.sqrt((sp1.x-sp2.x)*(sp1.x-sp2.x) + (sp1.y-sp2.y)*(sp1.y-sp2.y))
			local d = math.sqrt((p1.x-p2.x)*(p1.x-p2.x) + (p1.y-p2.y)*(p1.y-p2.y))
			local img = back_pic
			local scale = d/sd
			if scale*oldscale < 4 and scale*oldscale > 0.3 then
				if newTouch then
					--定位缩放中心
					local cx = (p1.x+p2.x)/2
					local cy = (p1.y+p2.y)/2
					local p = img:convertToNodeSpace(cc.p(cx,cy))
					local scale = img:getScaleX()
					local size = img:getContentSize()
					 
					local ap = cc.p(p.x/(size.width),p.y/(size.height))
					local oldap = img:getAnchorPoint()
					local oldx,oldy = img:getPosition()
					local delta = {}
					delta.x = oldx + (ap.x - oldap.x)*size.width
					delta.y = oldy + (ap.y - oldap.y)*size.height
					img:setPosition( delta )
					img:setAnchorPoint(ap)
					newTouch=nil --双手缩放
				end
				touchAction = 2
				img:setScaleX(scale*oldscale)
				img:setScaleY(scale*oldscale)
			end
		end
	end
	local function onTouchBegan(touches, event)  
		newTouch = true
		touchAction = 1
		oldx,oldy = back_pic:getPosition()
		oldscale = back_pic:getScaleX()
		onTouchMove(touches, event)	
	end
    local listener_rect = cc.EventListenerTouchAllAtOnce:create()
	listener_rect:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCHES_BEGAN )
	listener_rect:registerScriptHandler(onTouchMove,cc.Handler.EVENT_TOUCHES_MOVED )
  --  listener_rect:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCHES_ENDED )
	self:setTouchEnabled(true)
	self._picview:setTouchEnabled(false)
    local eventDispatcher_rect = self:getEventDispatcher()
    eventDispatcher_rect:addEventListenerWithSceneGraphPriority(listener_rect, self)
	
	local function Rota_PIC()
		rotation_num = rotation_num - 90
		back_pic:setRotation(rotation_num)
		button_rota:setPosition(cc.p(rota_size.width/2,rota_size.height/2))
	end
	
	local but_rota = uikits.child(self._widget,ui.BUTTON_ROTA)
	uikits.event(but_rota,	
	function(sender,eventType)	
		Rota_PIC()
	end,"click")	
	
	local function SetButtonEnabled(is_show)
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
	
	local but_add = uikits.child(self._widget,ui.BUTTON_ADD)	
	uikits.event(but_add,	
	function(sender,eventType)	
		SetButtonEnabled(false)
		Cut_pic()						
	end,"click")

	local but_quit = uikits.child(self._widget,ui.BUTTON_QUIT)
	uikits.event(but_quit,	
		function(sender,eventType)	
			self.parent_layer.isneedupdate = 1
			uikits.popScene()						
	end,"click")		
end

function EditPic:release()
	
end

return EditPic