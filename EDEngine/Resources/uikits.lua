require "Cocos2d"
require "Cocos2dConstants"
require "Opengl"
require "OpenglConstants"
require "StudioConstants"
require "GuiConstants"

function InitDesignResolutionMode()
	local director = cc.Director:getInstance()
	local glview = director:getOpenGLView()
	local ss = glview:getFrameSize()
	
	director:setContentScaleFactor(1)
	glview:setDesignResolutionSize(ss.width,ss.height,)
end