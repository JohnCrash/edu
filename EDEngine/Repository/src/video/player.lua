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
		local status = uikits.child(self._root,"Image_3")
		local sn = -1
		local movie = uikits.movieView{width=size.width,height=size.height}
		movie:open(self._arg.filename)
		
		self._root:addChild(movie)
		local binit = false
		uikits.delay_call(movie,function(dt)
			if cc_isobj(movie) then
				local s = movie:getMovieSize()
				if not binit and s.width > 0 and s.height > 0 then
					local w = s.width * size.height / s.height
					local x = (size.width - w)/2
					movie:setContentSize(cc.size(w,size.height))
					movie:setPosition(cc.p(x,0))
					
					movie:play()		
					binit = true
				end
				if movie:isError() then
					if sn ~= 0 then
						status:setVisible(true)
						status:loadTexture("video/warning.png")
						sn = 0
					end
				elseif movie:isReconnect() then
					if sn ~= 1 then
						status:setVisible(true)
						status:loadTexture("video/reconnect.png")
						sn = 1
					end
				elseif movie:isSeeking() then
					if sn ~= 2 then
						status:setVisible(true)
						status:loadTexture("video/seeking.jpg")
						sn = 2
					end
				elseif not movie:isOpen() then
					if sn ~= 3 then
						status:setVisible(true)
						status:loadTexture("video/loading.png")
						sn = 3
					end
				elseif movie:isPause() then
					if sn ~= 4 then
						status:setVisible(true)
						status:loadTexture("video/th.jpg")
						sn = 4
					end				
				else
					if sn ~= -1 then
						status:setVisible(false)
						sn = -1
					end
				end
				return true
			end
		end,0.01)
	end
end

function video:release()
	
end

return video