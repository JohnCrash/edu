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
需要在被调试代码中插入代码
require "mobdebug".start("127.0.0.1",8172)
lua环境主动连接,debuger 被动监听
协议:
	SETB source line
		设置断点
	DELB source line
		删除断点
	EXEC chunk
		执行
	LOAD size name
		装入模块
	SETW exp
		执行表达式 return (exp)
	DELW index
-------------------------------
	RUN
		继续执行,直到下一个断点
	STEP
		执行到下一行,能进入函数内部
	OVER
		执行到下一行,跳过函数体
	OUT
		执行到当前函数返回
	EXIT
		退出调试器
	可能的返回:
	202 Paused (source) (line)
	203 Paused (source) (line)
	204 Output (stream) (size)
	401 Error in Execution (size)
-------------------------------		
	BASEDIR dir
		设置目录
		成功返回200 OK
		失败返回400 Bad Request
	SUSPEND
		没有返回
	STACK
		报告stack trace
	OUTPUT stream mode$
		俘获并且重定向stream
		成功返回200 OK
		失败返回400 Bad Request		
成功返回"200 OK\n"
失败返回"400 Bad Request\n"
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
