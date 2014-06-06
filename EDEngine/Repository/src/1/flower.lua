
local scheduler = cc.Director:getInstance():getScheduler()

local function delay_call(func,param,delay)
	local schedulerID
	if func == nil then
		print( "func = nil?")
		return
	end
	if not schedulerID then
		local function delay_call_func()
			scheduler:unscheduleScriptEntry(schedulerID)
			schedulerID = nil		
			func(self,param)
		end
		schedulerID = scheduler:scheduleScriptFunc(delay_call_func,delay,false)
	end	
end

--粒子系统(礼花)
function LavaFlow()
	local layer,ss,N
	print("=========================================")
	layer = cc.LayerColor:create(cc.c4b(0,0,0,255))
	ss = cc.Director:getInstance():getWinSize()
	N = 3
	local function flower()
		layer:setColor(cc.c3b(0, 0, 0))
		local plist = 'Particles/ExplodingRing.plist'
		local emitter = {}
		for i = 1,N do
			emitter[i] = cc.ParticleSystemQuad:create(plist)
			emitter[i]:setPosition(cc.p(ss.width*(i+1)/ (N+2),ss.height / 1.25))
			emitter[i]:setStartColor(cc.c4f(0,0,0,1))
		end
		
		local batch = cc.ParticleBatchNode:createWithTexture(emitter[1]:getTexture())

		for i = 1,N do
			batch:addChild(emitter[i], 0)
		end

		layer:addChild(batch, 10)
	end
	--先起来然后开花
	local amgr = cc.Director:getInstance():getActionManager()
	for i = 1,N do
		local emitter = cc.ParticleSystemQuad:create("Particles/lightDot.plist")
		local x = ss.width*(i+1)/ (N+2) - ss.width/2 --(N+1)/ (2*(N+2))
		local action = cc.MoveBy:create(0.8,cc.p(x,ss.height / 1.25))
		amgr:addAction( action,emitter,true)
		layer:addChild(emitter)
		emitter:setPosition(ss.width / 2, 0)
	end
	delay_call( flower,0,0.9 )
	return layer
end
