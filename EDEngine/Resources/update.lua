require "Cocos2d"
local kits = require "kits"
local uikits = require "uikits"
local cache = require "cache"
local md5 = require "md5"
local json = require "json-c"

--local local_dir = cc.FileUtils:getInstance():getWritablePath()
local local_dir = 'f:/test/'
local platform = CCApplication:getInstance():getTargetPlatform()
local update_server = 'http://192.168.2.211:81/lgh/new/'

local ui = {
	FILE = 'loadscreen/jiazhan.json',
	FILE_43 = 'loadscreen/43/jiazhan.json',
	PROGRESS = 'bo2',
	EXIT_BUTTON = 'exit',
	TRY_BUTTON = 'try',
}

local UpdateProgram = class("UpdateProgram")
UpdateProgram.__index = UpdateProgram

--根据filelist.json来跟新文件
local function update_directory(dir)
	
end

local function download_file(t)
	local url = update_server..t
	local local_file = local_dir..t
	local fbuf = kits.http_get(url)
	if fbuf then
		kits.write_file(local_file,fbuf)
		return true
	end
end

local function update_one_by_one(t)
	if t then
		if t.download then
			return download_file(t.download)
		elseif t.mkdir then
			kits.make_directory(t.mkdir)
			return true
		elseif t.remove then
			--delete file
			kits.del_local_file(t.remove)
		elseif t.remove_dir then
			--delete directory
			kits.del_local_directory(t.remove_dir)
		else
			kits.log('update_one_by_one unkown operation')
		end
	else
		kits.log('update_one_by_one t=nil')
	end
end

local function check_directory(dir)
		local res_url = update_server..'res/'..dir..'/version.json'
		local src_url = update_server..'src/'..dir..'/version.json'
		local res_local = local_dir..'res/'..dir..'/version.json'
		local src_local = local_dir..'src/'..dir..'/version.json'
		--只有在确定下载成功的情况下才跟新
		local res = kits.http_get(res_url,'',2)
		if res then
			local src = kits.http_get(src_url,'',2)
			if src then
				local res_v = json.decode(res)
				local src_v = json.decode(src)
				if res_v and src_v and type(res_v)=='table' and type(src_v)=='table'
					and res_v.version and src_v.version then
					--比较本地和网络版本
					local l_res_v = kits.read_file(res_local)
					local l_src_v = kits.read_file(src_local)
					if not l_res_v then return true end --没有本地版本文件，需要跟新
					if not l_src_v then return true end
					local j_res_v = json.decode(l_res_v)
					local j_src_v = json.decode(l_res_v)
					if j_res_v.version and j_src_v.version and
					j_res_v.version==res_v.version and j_src_v.version==src_v.version then
						return false --完全相同不需要跟新
					else
						return true --需要跟新
					end
				else
					kits.log('check_directory  version file error!')
					return false,true --下传失败,本次不跟新
				end
			else
				kits.log('check_directory '..tostring(src_url)..' failed')
				return false,true --下传失败,本次不跟新
			end
		else
			kits.log('check_directory '..tostring(res_url)..' failed')
			return false,true --下传失败,本次不跟新
		end
end

local function check_update(t)
	t.need_updates={}
	for i,v in pairs(t.updates) do
		local b,err = check_directory(v)
		if err then --如果网络错误不在等待，直接不跟新
			return false
		end
		if b then
			table.insert(t.need_updates,v) --将需要跟新的都加入到，需要跟新列表
		end
	end
	return (not #t.need_updates == 0)
end

function UpdateProgram.create(t)
	if t and type(t)=='table' and t.updates and t.run 
	and type(t.updates)=='table' and type(t.run)=='function' then
		--不需要跟新直接启动
		if not check_update(t) then
			local scene = t.run()
			if scene then
				cc.Director:getInstance():runWithScene(scene)
			else
				kits.log('ERROR UpdateProgram:init run return nil')
			end
			return
		end
		--需要跟新,打开启动界面
		local scene = cc.Scene:create()
		local layer = uikits.extend(cc.Layer:create(),UpdateProgram)
		
		scene:addChild(layer)
		
		local function onNodeEvent(event)
			if "enter" == event then
				layer._args = t
				layer:init()
			elseif "exit" == event then
				layer:release()
			end
		end	
		layer:registerScriptHandler(onNodeEvent)
		cc.Director:getInstance():runWithScene(scene)
	else
		kit.log('ERROR UpdateProgram.create invalid param')
	end
end

function UpdateProgram:update()
	if self._first then
		self._first = false
		self._count = 0
		self._filelist = {}
		--收集目录中需要跟新个文件
		for i,v in pairs(self._args.need_updates) do
			update_directory(v)
		end
		self._maxcount = #self._filelist
	else
		self._count = self._count+1
		if self._count > self._maxcount then
			--操作完成
			local scene = self._args.run()
			cc.Director:getInstance():replaceScene(scene)
		else
			update_one_by_one(self._filelist[self._count])
		end
	end
end

function UpdateProgram:init()
	if not self._root then
		self._root = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE_43}
		self._progress = uikits.child(self._root,ui.PROGRESS)
		self._exit = uikits.child(self._root,ui.EXIT_BUTTON)
		self._try = uikits.child(self._root,ui.TRY_BUTTON)
		self:addChild(self._root)
	end
	self._first = true
	self._progress:setPercent(0)
	self._scheduler = self:getScheduler()
	if self._scheduler then
		self._sid = self._scheduler:scheduleScriptFunc(function()
			self:update()
		end,0.1,false)
	end
end

function UpdateProgram:release()
	if self._scheduler and self._sid then
		self._scheduler:unscheduleScriptEntry(self._sid)
		self._sid = nil
	end
end

return UpdateProgram