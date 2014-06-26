local mt = require "mt"
local uikits = require "uikits"

-------------------------------------------------------
-- MT TEST
-------------------------------------------------------
--local result = mt.do_curl("GET","http://www.google.com","")
local function progress( obj )
	print( obj.state.."	"..obj.progress )

	if obj.state == "CANCEL" then
		print( "err code : "..obj.errcode )
		print( "err string : "..obj.errmsg )
	elseif obj.state == "FAILED" then
		print( "err code : "..obj.errcode )
		print( "err string : "..obj.errmsg )		
		print( "restart .... " )
		print( "offset : "..(obj.size/1024).." K")
		if obj.errcode == 33 then
			print( "服务器不支持断点续传!" )
		else
			obj:restart()
		end
	elseif obj.state == "OK" then
		print( "File Size :" .. obj.size )
		kits.write_local_file( "mindterm_4.1.5-doc.zip",obj.data )
	end
end

--local mh,msg = mt.new('GET','http://tech.cryptzone.com/download/MindTerm-4.1.5/mindterm_4.1.5-doc.zip','',progress)
--[[
local mh,msg = mt.new('GET','ftp://sourceware.org/pub/pthreads-win32/pthreads-w32-2-9-1-release.zip','',progress)

if mh then
	print( "State:"..mh.state  )
end
print("=====================")
print( mh )
print( msg )
print("=====================")
--]]
-------------------------------------------------------
-- UI TEST
-------------------------------------------------------
local function test_menu_back()
	local  layer = cc.Layer:create()
	local item1 = uikits.menuItemFont{caption='Back',
										event=function(tag,sender)
											cc.Director:getInstance():popScene()
										end}
	local m = uikits.menu{ items={item1},alignV=true}
	layer:addChild(m)
	return layer
end

local transitions = {
	SlideInB = cc.TransitionSlideInB,
	SlideInT = cc.TransitionSlideInT,
	SlideInL = cc.TransitionSlideInL,
	SlideInR = cc.TransitionSlideInR,
	RotoZoom = cc.TransitionRotoZoom,
	JumpZoom = cc.TransitionJumpZoom,
	MoveInL = cc.TransitionMoveInL,
	MoveInR = cc.TransitionMoveInR,
	MoveInT = cc.TransitionMoveInT,
	MoveInB = cc.TransitionMoveInB,
	ShrinkGrow = cc.TransitionShrinkGrow,
	FlipX = cc.TransitionFlipX,
	FlipY = TransitionFlipY,
	FlipAngular = cc.TransitionFlipAngular,
	Fade = cc.TransitionFade,
	CrossFade = cc.TransitionCrossFade,
	TurnOffTiles = cc.TransitionTurnOffTiles,
	SplitCols = cc.TransitionSplitCols,
	SplitRows = cc.TransitionSplitRows,
	FadeTR = cc.TransitionFadeTR,
	FadeBL = cc.TransitionFadeBL,
	FadeUp = cc.TransitionFadeUp,
	FadeDown = cc.TransitionFadeDown,
	PageTurn = cc.TransitionPageTurn,
	Progress = cc.TransitionProgress,
	ProgressRadialCCW = cc.TransitionProgressRadialCCW,
	ProgressRadialCW = cc.TransitionProgressRadialCW,
	ProgressHorizontal = cc.TransitionProgressHorizontal,
	ProgressVertical = cc.TransitionProgressVertical,
	ProgressInOut = cc.TransitionProgressInOut,
	ProgressOutIn = cc.TransitionProgressOutIn,
}
local LINE_SPACE = 0
local function test_menu( layer )
	uikits.initDR{}
	local lay = cc.Layer:create()

	local items = {}
	local i = 1
	for k,v in pairs(transitions) do
		items[#items+1] = uikits.menuItemFont{ caption = k,		
						x=0,y=i*LINE_SPACE,
						 event=function(tag,sender) 
								local scene = cc.Scene:create()
								scene:addChild(test_menu_back(), 0)
								cc.Director:getInstance():pushScene( v:create(1, scene) )
							end}
		i = i + 1
	end
	local ss = uikits.screenSize()
	local m = uikits.menu{items=items,alignV=true}
	local sv = uikits.scrollview{x=0,y=0,width=ss.width,height=ss.height,
				bgcolor=cc.c3b(255,0,0),bgcolor2=cc.c3b(0,0,255)}
	sv:addChild(m)
	sv:setInnerContainerSize(cc.size(ss.width,ss.height*2))
	lay:addChild( sv )

	layer:addChild( lay )
end

local function test_page( layer )
	local ss = uikits.screenSize()
	uikits.initDR{}
	local sp = uikits.pageview{bgcolor=cc.c3b(128,128,128),
									x = 32,y=32,width=ss.width-64,height=ss.height-64,
									event=function(sender,eventType)
										if eventType == ccui.PageViewEventType.turning then
											print( 'page '..sender:getCurPageIndex() + 1 )
										end
									end}
	math.randomseed(os.time())
	for i = 1,32 do
		local lay1 = uikits.layout{bgcolor=cc.c3b(math.random(0,255),math.random(0,255),math.random(0,255)),
		bgcolor2=cc.c3b(math.random(0,255),math.random(0,255),math.random(0,255))}
		lay1:addChild(uikits.text{caption='Page '..i,fontSize=32})
		sp:addPage(lay1)
	end
	layer:addChild(sp)
end

local function test( layer )
	local ss = uikits.screenSize()
	uikits.initDR{}
	
	local sv = uikits.scrollview{width=ss.width,height=ss.height,
	event=function(sender,type)
		if type == SCROLLVIEW_EVENT_SCROLLING then
			print( "SCROLLVIEW_EVENT_SCROLLING")
		elseif type == SCROLLVIEW_EVENT_SCROLL_TO_TOP then
			print('SCROLLVIEW_EVENT_SCROLL_TO_TOP')
		elseif type == SCROLLVIEW_EVENT_SCROLL_TO_BOTTOM then
			print('SCROLLVIEW_EVENT_SCROLL_TO_BOTTOM')
		end
	end
	}
	layer:addChild(sv)
	
	local h = 0
	for i = 1,32 do
		local ox,oy = 32,32
		local t = uikits.text{caption="Text"..i,fontSize=30,eventClick=function(sender) print("text click")end}
		local y = oy + (i-1)*t:getSize().height
		h = h + t:getSize().height
		t:setPosition{x=ox,y=y}
		sv:addChild(t)
		--checkbox
		local c = uikits.checkbox{x=ox+t:getSize().width,y=y,check=i%2==1 and true or false,
						eventSelect=function (sender,b) print(b) end}
		sv:addChild(c)
		--button
		local b = uikits.button{x=ox+t:getSize().width+c:getSize().width,y=y,
											fontSize=32,width=320,height=c:getSize().height,
											caption="Button 中文"..i,
											eventClick=function (sender) print('click') end}
		sv:addChild(b)
		--slider
		local s = uikits.slider{width=320,height=c:getSize().height,
										x=b:getPosition()+b:getSize().width,y= y,percent=i*100/32,
										eventPercent=function (sender,percent) print(percent) end}
		sv:addChild(s)
		--edit
		local e = uikits.editbox{caption='Input here:',
			x=s:getPosition()+s:getSize().width,y= y}
		sv:addChild(e)
		--image
		local img = uikits.image{image='cocosui/sliderballnormal.png',x=e:getPosition()+e:getSize().width,y=y}
		sv:addChild(img)
		local img2 = uikits.image{image='cocosui/button.png',x=img:getPosition()+img:getSize().width,y=y,
		scale9=true,width=64,height=32,touch=true}
		sv:addChild(img2)
	end
	sv:setInnerContainerSize{width=ss.width+64,height=h+64}
end

return {
	scroll = test,
	page = test_page,
	menu = test_menu
}