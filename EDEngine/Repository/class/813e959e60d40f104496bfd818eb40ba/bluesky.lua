local kits = require "kits"
local uikits = require "uikits"
local base = require "base"
local factory = require "factory"

local MountainUUID = "033b3be83c70075bbe5f98cc9f634a27"
local cloudUUID = "4abdf31c00f3d1dc7c5870188fef0481"
local wayUUID = "a01ee8a3db56d31570a9307e56d91c3f"

return {
	ccCreate=function(self)
		super.ccCreate(self)
		local m = factory.create(MountainUUID)
		m:doAction("1")
		self:addChild(m)
		print("BlueSky")
	end,
	test=function(self)
		super.test(self)
	end,
}