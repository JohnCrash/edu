--
-- Lua Debug 0.1
--[[
iRobot lua debuger协议
==========================
lua环境主动连接,debuger 被动监听
协议:
1由lua环境发送到debuger的消息
	break<source>@line
		断点被触发
	info:msg
		信息提取
	error<>
		程序出错
	error<source>@line
		程序出错
2由debuger向lua环境发送的消息
	get<name>
		取变量
	traceback
		取调用堆栈
	tracefront
		
	reset
		重启lua环境
	bp<source>@line
		设置断点
	clear<source>@line
	clearall
		清除全部的断点
	step
		单步
	continue
		运行
	stepin
		单步进入函数体
==========================
mobdebug lua debuger协议
==========================
lua环境主动连接,debuger 被动监听
协议:
1由lua环境发送到debuger的消息
	
2由debuger向lua环境发送的消息
==========================
--]]
local socket = require 'socket'
local debug = require 'debug'

local tcp
local function connect_debuger(address,port,timeout)
	local err
	tcp,err = socket.tcp()
	if tcp then
		tcp:settimeout(timeout or 1)
		local res,err = tcp:connect(address,port)
		if res then
			--成功连接
		else
			print('connect debuger error:"'..tostring(err)..'"')
		end
	else
		print('debuger error:"'..tostring(err)..'"')
	end
end
