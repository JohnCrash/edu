local _tc
local _ci

local function setTeacherClass(v)
	_tc = v
end

local function setChildInfo(v)
	_ci = v
end

local function getTeacherClass()
	return _tc
end

local function getChildInfo()
	return _ci
end

local _attach_uid
local function setAttachChildUID( uid )
	_attach_uid = uid
end

local function getAttachChildUID()
	if _attach_uid and _attach_uid>0 then
		return _attach_uid
	end
	return require "login".uid()
end

local _buy_v1
local _buy_v2
local _buy_v3
local function setBuyVoteInfo(v1,v2,v3)
	_buy_v1 = v1
	_buy_v2 = v2
	_buy_v3 = v3
end

local function getBuyVoteInfo(v1,v2,v3)
	return _buy_v1,_buy_v2,_buy_v3
end

return {
	setTeacherClass=setTeacherClass,
	setChildInfo=setChildInfo,
	getTeacherClass=getTeacherClass,
	getChildInfo=getChildInfo,	
	setAttachChildUID = setAttachChildUID,
	getAttachChildUID = getAttachChildUID,
	setBuyVoteInfo = setBuyVoteInfo,
	getBuyVoteInfo = getBuyVoteInfo,
}