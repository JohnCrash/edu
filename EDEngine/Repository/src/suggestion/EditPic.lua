local crash = require "crash"
local uikits = require "uikits"
local cache = require "cache"
local kits = require "kits"
local login = require "login"
local json = require "json-c"
local loadingbox = require "loadingbox"

local ui = {
	FILE = 'suggestion/editpic_new.json',
	FILE_3_4 = 'suggestion/editpic43_new.json',
	PIC_VIEW = 'Pic_view',
	BUTTON_QUIT = 'mainmenu/fanhui',
	BUTTON_ADD = 'mainmenu/Button_wc',
}

local EditPic = class("EditPic")
EditPic.__index = EditPic

function EditPic.create(parent_layer,file_path)
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),EditPic)
	scene:addChild(layer)
	layer.parent_layer = parent_layer
	layer.file_path = file_path
	
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

local buttonTL
local buttonTR
local buttonBR
local buttonBL
local loadbox
local url = 'http://file-stu.lejiaolexue.com/rest/user/upload/hw'
local temp_filename

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
	local but_add = uikits.child(self._widget,ui.BUTTON_ADD)	
	uikits.event(but_add,	
	function(sender,eventType)	
		self:uploadpic()						
	end,"click")
		local data
	local file

	local but_quit = uikits.child(self._widget,ui.BUTTON_QUIT)
	uikits.event(but_quit,	
		function(sender,eventType)	
			self.parent_layer.isneedupdate = 1
			uikits.popScene()						
	end,"click")		
	
	self._picview = uikits.child(self._widget,ui.PIC_VIEW)
	local scheduler = cc.Director:getInstance():getScheduler()
--	local back_pic = cc.Sprite:create('suggestion/11.jpg')
	local s = self._picview:getContentSize()
--	back_pic:setPosition(cc.p(s.width/2,s.height/2))
    local back_pic = ccui.ImageView:create()
--	back_pic:setTouchEnabled(true)
--	self.file_path = kits.get_local_directory()..'res/suggestion/11.jpg'
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
	
--	local pic_size = back_pic:getContentSize()
	local sel_rect_size = {x1 = s.width/2-100,y1 = s.height/2-100,x2 = s.width/2+100,y2=s.height/2+100}
	local sel_rect = uikits.rect{x1 = sel_rect_size.x1,y1 = sel_rect_size.y1,x2 = sel_rect_size.x2,y2=sel_rect_size.y2,color=cc.c3b(255,0,0),fillColor=cc.c4f(0,0,0,0),linewidth=10}

	self._picview:addChild(sel_rect,1000,10000)
	
	local rotation_table = cc.Sprite:create('suggestion/kd.png')
	rotation_table:setPosition(cc.p(s.width-100,s.height/2))
	self._picview:addChild(rotation_table,10)
	
	local function touchEventRota(sender,eventType)
		if eventType == ccui.TouchEventType.moved then
			local pos = sender:getTouchMovePosition()
			local local_pos = rotation_table:convertToNodeSpace(pos) 
			if local_pos.y>sender.maxheight or local_pos.y < 0 then
				return
			end
			rotation_num = 0-math.ceil((local_pos.y-450)/450*180)
			if rotation_num>0 then
				rotation_num = rotation_num+1
			end
			back_pic:setRotation(rotation_num)
			sender:setPositionY(local_pos.y)
		end
	end

    button_rota = ccui.Button:create()
    button_rota:setTouchEnabled(true)
    button_rota:loadTextures("suggestion/jt.png", "suggestion/jt.png", "")
	local rota_size = rotation_table:getContentSize()
	button_rota.maxheight = rota_size.height
    button_rota:setPosition(cc.p(rota_size.width/2,rota_size.height/2))        
    button_rota:addTouchEventListener(touchEventRota)
    rotation_table:addChild(button_rota)	
	
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
    buttonTL:loadTextures("suggestion/jt2.png", "suggestion/jt2.png", "")
	buttonTL:setScale(2)
	buttonTL.scale_but = 1
    buttonTL:setPosition(cc.p(sel_rect_size.x1,sel_rect_size.y2))        
    buttonTL:addTouchEventListener(touchEvent)
    self._picview:addChild(buttonTL,1001,10001)

    buttonTR = ccui.Button:create()
    buttonTR:setTouchEnabled(true)
    buttonTR:loadTextures("suggestion/jt3.png", "suggestion/jt3.png", "")
	buttonTR:setScale(2)
	buttonTR.scale_but = 2
    buttonTR:setPosition(cc.p(sel_rect_size.x2,sel_rect_size.y2))        
    buttonTR:addTouchEventListener(touchEvent)
    self._picview:addChild(buttonTR,1002,10001)

    buttonBR = ccui.Button:create()
    buttonBR:setTouchEnabled(true)
    buttonBR:loadTextures("suggestion/jt2.png", "suggestion/jt2.png", "")
	buttonBR:setScale(2)
	buttonBR.scale_but = 3
    buttonBR:setPosition(cc.p(sel_rect_size.x2,sel_rect_size.y1))        
    buttonBR:addTouchEventListener(touchEvent)
    self._picview:addChild(buttonBR,1003,10001)
	
    buttonBL = ccui.Button:create()
    buttonBL:setTouchEnabled(true)
    buttonBL:loadTextures("suggestion/jt3.png", "suggestion/jt3.png", "")
	buttonBL:setScale(2)
	buttonBL.scale_but = 4
    buttonBL:setPosition(cc.p(sel_rect_size.x1,sel_rect_size.y1))        
    buttonBL:addTouchEventListener(touchEvent)
    self._picview:addChild(buttonBL,1004,10001)
	
--[[	local label_status_cut = cc.Sprite:create('suggestion/t4.png')
	label_status_cut:setPosition(cc.p(s.width/2,s.height*4/5))
	self._picview:addChild(label_status_cut,10)
	local label_status_rota = cc.Sprite:create('suggestion/t3.png')
	label_status_rota:setPosition(cc.p(s.width/2,s.height*4/5))
	self._picview:addChild(label_status_rota,10)
	local label_status_move = cc.Sprite:create('suggestion/t5.png')
	label_status_move:setPosition(cc.p(s.width/2,s.height*4/5))
	self._picview:addChild(label_status_move,10)
	label_status_cut:setVisible(true)
	label_status_rota:setVisible(false)
	label_status_move:setVisible(false)
	operate_type = 1--]]
	
	local menu = cc.Menu:create()
	local button_cutpic = cc.MenuItemImage:create('suggestion/ti1.png', 'suggestion/ti2.png')
	button_cutpic:setPosition(cc.p(100,100))
	menu:addChild(button_cutpic)
	menu:setPosition(cc.p(0, 0))
	self._picview:addChild(menu,10)
	
	local function timer_update(time)
		local cur_sence = cc.Director:getInstance():getRunningScene()
		cur_sence:setPosition(cc.p(old_pos_x,old_pos_y))
		
		self._picview:removeChildByTag(10001)
		back_pic = ccui.ImageView:create()
		back_pic:setTouchEnabled(false)
		
		self.file_path = kits.get_local_directory()..'cache/'..temp_filename
		local plat_path = cc.FileUtils:getInstance():getWritablePath()..temp_filename
		self:copyfile(plat_path,self.file_path)

		back_pic:loadTexture(self.file_path)
		back_pic:setPosition(cc.p(s.width/2,s.height/2))
--		back_pic:addTouchEventListener(touchEventPic)
		self._picview:addChild(back_pic,1,10001)
		
		--sel_rect_size = {x1 = s.width/2-100,y1 = s.height/2-100,x2 = s.width/2+100,y2=s.height/2+100}
		sel_rect_size.x1 = s.width/2-100
		sel_rect_size.y1 = s.height/2-100
		sel_rect_size.x2 = s.width/2+100
		sel_rect_size.y2 = s.height/2+100
		self._picview:removeChildByTag(10000)
		local sel_rect = uikits.rect{x1 = sel_rect_size.x1,y1 = sel_rect_size.y1,x2 = sel_rect_size.x2,y2=sel_rect_size.y2,color=cc.c3b(255,0,0),fillColor=cc.c4f(0,0,0,0),linewidth=10}
		self._picview:addChild(sel_rect,1000,10000)	
		buttonTL:setPosition(cc.p(sel_rect_size.x1,sel_rect_size.y2)) 
		buttonTR:setPosition(cc.p(sel_rect_size.x2,sel_rect_size.y2)) 
		buttonBR:setPosition(cc.p(sel_rect_size.x2,sel_rect_size.y1))  
		buttonBL:setPosition(cc.p(sel_rect_size.x1,sel_rect_size.y1)) 
					
		if schedulerEntry then
			scheduler:unscheduleScriptEntry(schedulerEntry)
		end
	end
	
	
	local function Cut_pic(tag, sender)	
		local texture = cc.RenderTexture:create(sel_rect_size.x2-sel_rect_size.x1,sel_rect_size.y2-sel_rect_size.y1)
		local cur_sence = cc.Director:getInstance():getRunningScene()
		old_pos_x, old_pos_y= cur_sence:getPosition()
		cur_sence:setPosition(cc.p(0-sel_rect_size.x1, 0-sel_rect_size.y1))
		texture:begin()
		back_pic:visit()
		texture.my_end = texture["end"]
		texture:my_end()
		--self.file_path = kits.get_local_directory()..'cache/screenshot.png'
		temp_filename = os.time()..'.png'
		texture:saveToFile(temp_filename, kCCImageFormatPNG)		
		schedulerEntry = scheduler:scheduleScriptFunc(timer_update,0.01,false)	
	end
	button_cutpic:registerScriptTapHandler(Cut_pic)
	
--[[	local menu_rota = cc.Menu:create()
	local button_rota = cc.MenuItemImage:create('suggestion/t3.png', 'suggestion/t3.png')
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
	local button_cut = cc.MenuItemImage:create('suggestion/t4.png', 'suggestion/t4.png')
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
	local button_move = cc.MenuItemImage:create('suggestion/t5.png', 'suggestion/t5.png')
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
	local oldx,oldy,oldscale
	local function onTouchMove(touches, event)  
		local count = #touches
		print('count::::'..count)
		if not newTouch then return end
		if count == 1 then
			local img = back_pic
			local scale = img:getScaleX()
			local size = img:getContentSize()
			local p = touches[1]:getLocation()
			local sp = touches[1]:getStartLocation()			
			img:setPosition(cc.p(oldx+(p.x-sp.x),oldy+(p.y-sp.y)))
		elseif count == 2 then
			local p1 = touches[1]:getLocation()
			local sp1 = touches[1]:getStartLocation()
			local p2 = touches[2]:getLocation()
			local sp2 = touches[2]:getStartLocation()		
			local sd = math.sqrt((sp1.x-sp2.x)*(sp1.x-sp2.x) + (sp1.y-sp2.y)*(sp1.y-sp2.y))
			local d = math.sqrt((p1.x-p2.x)*(p1.x-p2.x) + (p1.y-p2.y)*(p1.y-p2.y))
			local img = back_pic
			local scale = d/sd
			img:setScaleX(scale*oldscale)
			img:setScaleY(scale*oldscale)
		end
	end
	local function onTouchBegan(touches, event)  
		newTouch = true
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
end

function EditPic:release()
	
end

return EditPic