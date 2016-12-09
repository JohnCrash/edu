local uikits = require "uikits"
local kits = require "kits"
require  "ff"

local ui = {
	FILE = 'video/VideoPlayer_3.json',
	FILE_3_4 = 'video/VideoPlayer_3.json',
	designWidth = 1024,
	designHeight = 576,
	BACK = 'back',
}

local video = uikits.SceneClass("video",ui)

function video:init(b)
	if b then
		local size = uikits.getDR()
		local back = uikits.child(self._root,ui.BACK)
		uikits.event(back,function(sender)
			uikits.popScene()
		end)
		
		local movie = uikits.movieView{width=size.width,height=size.height}
		movie:open(self._arg.filename)
		
		self._root:addChild(movie)
		
		uikits.delay_call(movie,function(dt)
			local s = movie:getMovieSize()
			if s.width > 0 and s.height > 0 then
				local w = s.width * size.height / s.height
				local x = (size.width - w)/2
				movie:setContentSize(cc.size(w,size.height))
				movie:setPosition(cc.p(x,0))
				
				movie:play()		
				return false
			end
			return true		
		end,0.1)
	end
end

function video:release()
	
end

return video