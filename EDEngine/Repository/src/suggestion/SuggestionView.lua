local uikits = require "uikits"
local kits = require "kits"
local json = require "json-c"
local login = require "login"
local cache = require "cache"
local loadingbox = require "loadingbox"
local messagebox = require "messagebox"
local SuggestionRet = require "suggestion/SuggestionRet"
local SuggestionView = class("SuggestionView")
SuggestionView.__index = SuggestionView

--local get_uesr_info_url = 'http://api.lejiaolexue.com/rest/userinfo/simple/current'
local ui = {
	FILE = 'suggestion/yijian169.json',
	FILE_3_4 = 'suggestion/yijian43.json',
	CHECKBOX_YIJIAN = 'jian',
	CHECKBOX_CUOWU = 'cuo',
	CHECKBOX_TOUSU = 'tou',
	BUTTON_BACK = 'tiao/fanhui',
	BUTTON_COMMIT = 'tiao/ti',
	EDIT_CONTENT = 'wen/wenzi',
}

function create()
	local scene = cc.Scene:create()				
	local cur_layer = uikits.extend(cc.Layer:create(),SuggestionView)		
	--cur_layer.screen_type = screen_type	
	
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

function SuggestionView:init()	
	local scheduler = cc.Director:getInstance():getScheduler()
	local back_pic = cc.Sprite:create('suggestion/11.jpg')
	local s = cc.Director:getInstance():getWinSize()
	back_pic:setPosition(cc.p(s.width/2,s.height/2))
	self:addChild(back_pic)
	local sel_rect_size = {x1 = s.width/2-100,y1 = s.height/2-100,x2 = s.width/2+100,y2=s.height/2+100}
	local sel_rect = uikits.rect{x1 = sel_rect_size.x1,y1 = sel_rect_size.y1,x2 = sel_rect_size.x2,y2=sel_rect_size.y2,color=cc.c3b(255,0,0),fillColor=cc.c4f(0,0,0,0),linewidth=10}
--	local sel_rect = self:setRectPos(sel_rect_size.x1,sel_rect_size.x2,sel_rect_size.y1,sel_rect_size.y2)
	self:addChild(sel_rect,1000,10000)
	
	local rotation_table = cc.Sprite:create('suggestion/kd.png')
	rotation_table:setPosition(cc.p(s.width-100,s.height/2))
	self:addChild(rotation_table)
	
	local function touchEventRota(sender,eventType)
		if eventType == ccui.TouchEventType.moved then
			local pos = sender:getTouchMovePosition()
			local local_pos = rotation_table:convertToNodeSpace(pos) 
			if local_pos.y>sender.maxheight or local_pos.y < 0 then
				return
			end
			--print('pos.y::'..math.ceil((local_pos.y-500)/500*180))
			rotation_num = 0-math.ceil((local_pos.y-500)/500*180)
			if rotation_num>0 then
				rotation_num = rotation_num+1
			end
			print('pos.y::'..rotation_num)
			back_pic:setRotation(rotation_num)
			sender:setPositionY(local_pos.y)
		end
	end

    button_rota = ccui.Button:create()
    button_rota:setTouchEnabled(true)
    button_rota:loadTextures("suggestion/jt.png", "suggestion/jt.png", "")
	local rota_size = rotation_table:getContentSize()
	--print('rota_size.width::'..rota_size.width..'::rota_size.height::'..rota_size.height)
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
			self:removeChildByTag(10000)
			local sel_rect = uikits.rect{x1 = sel_rect_size.x1,y1 = sel_rect_size.y1,x2 = sel_rect_size.x2,y2=sel_rect_size.y2,color=cc.c3b(255,0,0),fillColor=cc.c4f(0,0,0,0),linewidth=10}
			self:addChild(sel_rect,1000,10000)	
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
    self:addChild(buttonTL,1001,10001)

    buttonTR = ccui.Button:create()
    buttonTR:setTouchEnabled(true)
    buttonTR:loadTextures("suggestion/jt3.png", "suggestion/jt3.png", "")
	buttonTR:setScale(2)
	buttonTR.scale_but = 2
    buttonTR:setPosition(cc.p(sel_rect_size.x2,sel_rect_size.y2))        
    buttonTR:addTouchEventListener(touchEvent)
    self:addChild(buttonTR,1002,10001)

    buttonBR = ccui.Button:create()
    buttonBR:setTouchEnabled(true)
    buttonBR:loadTextures("suggestion/jt2.png", "suggestion/jt2.png", "")
	buttonBR:setScale(2)
	buttonBR.scale_but = 3
    buttonBR:setPosition(cc.p(sel_rect_size.x2,sel_rect_size.y1))        
    buttonBR:addTouchEventListener(touchEvent)
    self:addChild(buttonBR,1003,10001)
	
    buttonBL = ccui.Button:create()
    buttonBL:setTouchEnabled(true)
    buttonBL:loadTextures("suggestion/jt3.png", "suggestion/jt3.png", "")
	buttonBL:setScale(2)
	buttonBL.scale_but = 4
    buttonBL:setPosition(cc.p(sel_rect_size.x1,sel_rect_size.y1))        
    buttonBL:addTouchEventListener(touchEvent)
    self:addChild(buttonBL,1004,10001)
	
	local label_status_cut = cc.Sprite:create('suggestion/t4.png')
	label_status_cut:setPosition(cc.p(s.width/2,s.height*4/5))
	self:addChild(label_status_cut)
	local label_status_rota = cc.Sprite:create('suggestion/t3.png')
	label_status_rota:setPosition(cc.p(s.width/2,s.height*4/5))
	self:addChild(label_status_rota)
	local label_status_move = cc.Sprite:create('suggestion/t5.png')
	label_status_move:setPosition(cc.p(s.width/2,s.height*4/5))
	self:addChild(label_status_move)
	label_status_cut:setVisible(true)
	label_status_rota:setVisible(false)
	label_status_move:setVisible(false)
	operate_type = 1
	
	local menu = cc.Menu:create()
	local button_cutpic = cc.MenuItemImage:create('suggestion/ti1.png', 'suggestion/ti2.png')
	button_cutpic:setPosition(cc.p(100,100))
	menu:addChild(button_cutpic)
	menu:setPosition(cc.p(0, 0))
	self:addChild(menu)
	
	local function timer_update(time)
		local cur_sence = cc.Director:getInstance():getRunningScene()
		cur_sence:setPosition(cc.p(old_pos_x,old_pos_y))
		if schedulerEntry then
		--	loadbox:removeFromParent()
			scheduler:unscheduleScriptEntry(schedulerEntry)
		end
	end
	
	
	local function Cut_pic(tag, sender)	
		local texture = cc.RenderTexture:create(sel_rect_size.x2-sel_rect_size.x1,sel_rect_size.y2-sel_rect_size.y1)
		local cur_sence = cc.Director:getInstance():getRunningScene()
		old_pos_x, old_pos_y= cur_sence:getPosition()
		cur_sence:setPosition(cc.p(0-sel_rect_size.x1, 0-sel_rect_size.y1))
		--[[texture:setPosition(cc.p(sel_rect_size.x1, sel_rect_size.y1))--]]
		texture:begin()
		back_pic:visit()
	--	cur_sence:visit()
		texture.my_end = texture["end"]
		texture:my_end()
		texture:saveToFile('screenshot.png', kCCImageFormatPNG)	
	--	loadbox = loadingbox.open(self)
		schedulerEntry = scheduler:scheduleScriptFunc(timer_update,0.01,false)	
	end
	button_cutpic:registerScriptTapHandler(Cut_pic)
	
	local menu_rota = cc.Menu:create()
	local button_rota = cc.MenuItemImage:create('suggestion/t3.png', 'suggestion/t3.png')
	button_rota:setPosition(cc.p(400,100))
	menu_rota:addChild(button_rota)
	menu_rota:setPosition(cc.p(0, 0))
	self:addChild(menu_rota)
	local function rota_callback(tag, sender)	
		label_status_cut:setVisible(false)
		label_status_rota:setVisible(true)
		label_status_move:setVisible(false)
		operate_type = 2
	end
	button_rota:setVisible(false)
	button_rota:registerScriptTapHandler(rota_callback)

	local menu_cut = cc.Menu:create()
	local button_cut = cc.MenuItemImage:create('suggestion/t4.png', 'suggestion/t4.png')
	button_cut:setPosition(cc.p(700,100))
	menu_cut:addChild(button_cut)
	menu_cut:setPosition(cc.p(0, 0))
	self:addChild(menu_cut)
	local function cut_callback(tag, sender)	
		label_status_cut:setVisible(true)
		label_status_rota:setVisible(false)
		label_status_move:setVisible(false)
		operate_type = 1
	end
	button_cut:registerScriptTapHandler(cut_callback)

	local menu_move = cc.Menu:create()
	local button_move = cc.MenuItemImage:create('suggestion/t5.png', 'suggestion/t5.png')
	button_move:setPosition(cc.p(1000,100))
	menu_move:addChild(button_move)
	menu_move:setPosition(cc.p(0, 0))
	self:addChild(menu_move)
	local function move_callback(tag, sender)	
		label_status_cut:setVisible(false)
		label_status_rota:setVisible(false)
		label_status_move:setVisible(true)
		operate_type = 8
	end
	button_move:registerScriptTapHandler(move_callback)

	local function onTouchEnded(touches, event)  
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
	end
	local function onTouchMove(touches, event)  
		local location = touches[1]:getLocation()
		if operate_type == 2 then
			if rotation_begain == nil then
				rotation_begain = location
			end
			local pic_x,pic_y = back_pic:getPosition()
			local angle1 = cc.pToAngleSelf(cc.pSub(rotation_begain, cc.p(pic_x,pic_y)))
			local angle2 = cc.pToAngleSelf(cc.pSub(location, cc.p(pic_x,pic_y)))
			local angle = (angle1 - angle2) * 180 / 3.14
			rotation_all = rotation_all+angle
			print('rotation_all::'..rotation_all)
			back_pic:setRotation(rotation_all)
			rotation_begain = location	
		elseif 	operate_type == 1 then
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
					--back_pic:setScale(rotation_all)
					scale_all = scale_all-scale_per
					back_pic:setScale(scale_all)
					--back_pic:runAction(CCScaleTo:create(0.1,scale_all))--»Ö¸´
				end
			else
				local t=pos_end-pos_begain
				if t>=scale_dis and scale_all<5 then
					scale_all = scale_all+scale_per
					back_pic:setScale(scale_all)
					--back_pic:runAction(CCScaleTo:create(0.1,scale_all))--·Å´ó
				end				
			end	
			scale_begain = location	
		elseif operate_type > 2 and operate_type < 7 then	
			if change_rect_begain == nil then
				change_rect_begain = location
			end		
			if operate_type == 3 then
				if location.x > sel_rect_size.x2 -20 or location.x < 0 then
					return
				end
				sel_rect_size.x1 = location.x 
			elseif operate_type == 4 then
				if location.x < sel_rect_size.x1 +20 or location.x > s.width then
					return
				end
				sel_rect_size.x2 = location.x
			elseif operate_type == 5 then
				if location.y > sel_rect_size.y2 -20 or location.y < 0 then
					return
				end			
				sel_rect_size.y1 = location.y
			elseif operate_type == 6 then
				if location.y < sel_rect_size.y1 +20 or location.y > s.height then
					return
				end
				sel_rect_size.y2 = location.y
			end		
			self:removeChildByTag(10000)
			local sel_rect = uikits.rect{x1 = sel_rect_size.x1,y1 = sel_rect_size.y1,x2 = sel_rect_size.x2,y2=sel_rect_size.y2,color=cc.c3b(255,0,0),fillColor=cc.c4f(0,0,0,0),linewidth=10}
			self:addChild(sel_rect,1000,10000)	
			buttonTL:setPosition(cc.p(sel_rect_size.x1,sel_rect_size.y2)) 
			buttonTR:setPosition(cc.p(sel_rect_size.x2,sel_rect_size.y2)) 
			buttonBR:setPosition(cc.p(sel_rect_size.x2,sel_rect_size.y1))  
			buttonBL:setPosition(cc.p(sel_rect_size.x1,sel_rect_size.y1)) 
		elseif 	operate_type == 8 then	
			if move_begain == nil then
				move_begain = location
			end		
			local pic_x,pic_y = back_pic:getPosition()
			--print('pic_x111::'..pic_x..'::pic_y111::'..pic_y)
			pic_x = pic_x+(location.x-move_begain.x)
			pic_y = pic_y+(location.y-move_begain.y)
			--print('pic_x222::'..pic_x..'::pic_y222::'..pic_y)
			back_pic:setPosition(cc.p(pic_x,pic_y))
			move_begain = location	
		end
	end
	local function onTouchBegan(touches, event)  
	--	if operate_type == 1 then
			local location = touches[1]:getLocation()
			old_operate_type = operate_type
			if location.x > sel_rect_size.x1 -5 and location.x < sel_rect_size.x1 +5 then
				if location.y > sel_rect_size.y1 and location.y < sel_rect_size.y2 then
					change_rect_begain = location
					operate_type = 3
				end
			elseif location.x > sel_rect_size.x2 -5 and location.x < sel_rect_size.x2 +5 then
				if location.y > sel_rect_size.y1 and location.y < sel_rect_size.y2 then
					operate_type = 4
					change_rect_begain = location
				end		
			elseif location.y > sel_rect_size.y1 -5 and location.y < sel_rect_size.y1 +5 then
				if location.x > sel_rect_size.x1 and location.x < sel_rect_size.x2 then
					operate_type = 5
					change_rect_begain = location
				end
			elseif location.y > sel_rect_size.y2 -5 and location.y < sel_rect_size.y2 +5 then
				if location.x > sel_rect_size.x1 and location.x < sel_rect_size.x2 then
					operate_type = 6
					change_rect_begain = location
				end		
			end		
	--	end
	end

--[[    local listener = cc.EventListenerTouchAllAtOnce:create()
	listener:registerScriptHandler(onTouchMove,cc.Handler.EVENT_TOUCHES_MOVED )
    listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCHES_ENDED )

    local eventDispatcher = back_pic:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, back_pic)--]]
	
    local listener_rect = cc.EventListenerTouchAllAtOnce:create()
	listener_rect:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCHES_BEGAN )
	listener_rect:registerScriptHandler(onTouchMove,cc.Handler.EVENT_TOUCHES_MOVED )
    listener_rect:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCHES_ENDED )

    local eventDispatcher_rect = self:getEventDispatcher()
    eventDispatcher_rect:addEventListenerWithSceneGraphPriority(listener_rect, self)
	
end

function SuggestionView:release()

end
return {
create = create,
}