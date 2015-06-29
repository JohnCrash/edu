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

return {
	setTeacherClass=setTeacherClass,
	setChildInfo=setChildInfo,
	getTeacherClass=getTeacherClass,
	getChildInfo=getChildInfo,	
}