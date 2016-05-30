local kits=require("kits")
local mt=require("mt")
local login=require("login")
local json=require("json-c")
local popup=require("qwxt/popup")

local interface="http://app.lejiaolexue.com/qwxt/qwxt.ashx"
local localDebug=cc.UserDefault:getInstance():getStringForKey("localDebug")
if localDebug and localDebug~="" then
	interface=localDebug			--http://localhost:1764/qwxt.ashx
end

local function post(url,form,callback)
	local ret,msg=mt.new("POST",url,login.cookie(),function(obj)
		if obj.state=="OK" or obj.state=="CANCEL" or obj.state=="FAILED"  then
			if obj.state=="OK" and obj.data then
				callback(true,json.decode(obj.data))
			else
				callback(false,obj.errmsg)
			end
		end
	end,form)
	if not ret then
		callback(false,msg)
	end
end

local send=0

--发送请求
local function internalSendRequest(method,param,callback,waiting,retry,sameScene)
	--默认重试3次
	retry=retry or 3

	--组装通信协议
	local protocol={}
	protocol.m=method
	protocol.icp=false
	protocol.v=param
	send=(send+1)%100
	protocol.rid=string.format("qwxt%d%02d",os.time(),send)

	local function onError(msg)
		if callback then
			if callback(false,msg) then
				waiting.flag=false
				return
			end
		end
		waiting.flag=false
		popup.tip(msg)
	end

	--发送
	local ss
	if sameScene then
		ss=cc.Director:getInstance():getRunningScene()
	end
	post(interface,kits.encode_url(json.encode(protocol)),function(success,obj)
		if sameScene then
			--不在同一场景里就把数据丢弃，回调函数可能找不到界面元素了
			local rs=cc.Director:getInstance():getRunningScene()
			if ss~=rs then
				waiting.flag=false
				return
			end
		end

		if success then
			--通信正常
			--检查返回的数据是否有问题
			if type(obj)~="table" then
				onError(obj)
				return
			elseif not obj.c or obj.rid~=protocol.rid then
				onError(obj.msg)
				return
			end
			if obj.c~=200 then
				--服务器返回码不正确
				onError(obj.msg)
				return
			end
			--获得了正确的数据
			if callback then
				callback(true,obj.v)
				waiting.flag=false
				if obj.v and type(obj.v)=="table" and obj.v.tip and obj.v.tip~="" then popup.tip(obj.v.tip) end
			end
		else
			--通信出错
			if retry and retry>0 then
				popup.msgBox({text="由于网络原因，加载出错了，重试一下吧！",title="温馨提示"},function(ok)
					if ok then
						internalSendRequest(method,param,callback,waiting,retry-1,sameScene)
					else
						onError(obj)
					end
				end)
			else
				onError(obj)
			end
		end
	end)
end

local function sendRequest(method,param,callback,waitParam,retry,sameScene)
	--回调处理默认需要在同一场景内
	sameScene=sameScene or true

	local waiting={flag=true}
	if not waitParam then
		internalSendRequest(method,param,callback,waiting,retry,sameScene)
	else
		internalSendRequest(method,param,callback,waiting,retry,sameScene)
		require("qwxt/public").showWaiting(waitParam.node,function()
			while waiting.flag do
				coroutine.yield()
			end
		end,waitParam.onFinished,waitParam.text)
	end
end

--获取用户信息
local function getUserInfo(callback,waitParam)
	sendRequest("get_user_info",nil,callback,waitParam)
end

--获取用户宝藏列表
local function getUserBaozang(callback,waitParam)
	sendRequest("get_user_baozang",nil,callback,waitParam)
end

--获取用户奖状列表
local function getUserJiangzhuang(callback,waitParam)
	sendRequest("get_user_jiangzhuang",nil,callback,waitParam)
end

--获取选择的教材id
local function getSelectedBook(subjectId,callback,waitParam)
	local param={v1=subjectId}
	sendRequest("get_selected_book",param,callback,waitParam,0)
end

--保存选择的教材id
local function setSelectedBook(subjectId,versionId,bookId,callback,waitParam)
	local param={subjectId=subjectId,versionId=versionId,bookId=bookId}
	sendRequest("set_selected_book",param,callback,waitParam,0)
end

--获取教材版本列表
local function getVersions(subjectId,callback,waitParam)
	local param={v1=subjectId}
	sendRequest("get_book_versions",param,callback,waitParam)
end

--获取教材列表
local function getBooks(subjectId,versionId,callback,waitParam)
	local param={subjectId=subjectId,versionId=versionId}
	sendRequest("get_version_books",param,callback,waitParam)
end

--获取单元信息
local function getUnits(subjectId,versionId,bookId,callback,waitParam)
	local param={subjectId=subjectId,versionId=versionId,bookId=bookId}
	sendRequest("get_units",param,callback,waitParam)
end

--获取单元信息
local function getClasses(subjectId,versionId,bookId,unitId,callback,waitParam)
	local param={subjectId=subjectId,versionId=versionId,bookId=bookId,unitId=unitId}
	sendRequest("get_classes",param,callback,waitParam)
end

--双倍充值
local function newShuangbei(callback,waitParam)
	sendRequest("new_shuangbei",nil,callback,waitParam,0)
end

--请求出题
local function getProblem(subjectId,nodeId,nodeType,callback,waitParam)
	local param={subjectId=subjectId,nodeId=nodeId,nodeType=nodeType}
	sendRequest("get_problem",param,callback,waitParam)
end

--提交答案
local function submitAnswer(problemId,answer,callback,waitParam)
	local param={problemId=problemId,answer=answer}
	sendRequest("submit_answer",param,callback,waitParam)
end

--后悔药
local function regret(problemId,callback,waitParam)
	local param={v1=problemId}
	sendRequest("regret",param,callback,waitParam)
end

--排行榜
local function getRankData(rank,rankParam,callback,waitParam)
	local param={v1=rank,v2=rankParam}
	sendRequest("get_rank",param,callback,waitParam)
end

--设置背景音乐开关
local function setBGMusic(musicOn,zuotiMusicOn,callback,waitParam)
	local param={v1=musicOn,v2=zuotiMusicOn}
	sendRequest("set_background_music",param,callback,waitParam,0)
end

--邮寄奖状
local function mailJiangzhuang(jiangzhuangId,receiver,address,phoneNumber,callback,waitParam)
	local param={v1=jiangzhuangId,v2=receiver,v3=address,v4=phoneNumber}
	sendRequest("mail_jiangzhuang",param,callback,waitParam,0)
end

--获取同学信息
local function getClassmateInfo(userId,callback,waitParam)
	local param={v1=userId}
	sendRequest("get_classmate_info",param,callback,waitParam)
end

--获取会员有效期价格表
local function getExpireTimePrice(callback,waitParam)
	sendRequest("get_expiretime_price",nil,callback,waitParam)
end

--购买会员有效期
local function rechargeExpireTime(priceId,callback,waitParam)
	local param={v1=priceId}
	sendRequest("recharge_expiretime",param,callback,waitParam)
end

--获取银币价格表
local function getYinbiPrice(callback,waitParam)
	sendRequest("get_yinbi_price",nil,callback,waitParam)
end

--购买银币
local function rechargeYinbi(priceId,callback,waitParam)
	local param={v1=priceId}
	sendRequest("recharge_yinbi",param,callback,waitParam,0)
end

--使用充值卡
local function rechargeByCard(cardId,callback,waitParam)
	local param={v1=cardId}
	sendRequest("recharge_by_card",param,callback,waitParam,0)
end

--支付
local function pay(order,callback)
	--支付参数
	local pay_table=
	{
		order_no=order.order_no,
		total_money=order.total_money,
		product_info=order.product_info,
		product_count=order.product_count,
		app_id=order.app_id,
		pay_type=order.pay_type,
		user_context=order.user_context,
	}
	local t=json.encode(pay_table)
	local form="t="..t.."&c="..order.sign
	--发送请求支付
	local waiting=true
	post("http://pay.lejiaolexue.com/PayHandler.ashx?s=app",form,function(success,data)
		if success and data then
			if data.result and data.result==200 then
				--支付成功
				callback(true)
				waiting=false
			elseif data.msg then
				--支付失败
				local s=data.msg
				if data.result==620 then
					s=s.."\n亲爱的，你的乐币不足，请选择充值乐币。\n\n如需查看如何充值乐币，请点击“确认”；\n已了解，请点击“取消”关闭对话框。"
					popup.msgBox({text=s,title="温馨提示"},function(ok)
						callback(false)
						waiting=false
						if ok then
							performWithDelay(cc.Director:getInstance():getRunningScene(),function()
								cc.Director:getInstance():pushScene(require("qwxt/public").createScene("chong"))
							end,0)
						end
					end)
				else
					popup.msgBox({text=s,title="温馨提示"},function(ok)
						callback(false)
						waiting=false
					end,true)
				end
			else
				popup.msgBox({text="支付接口返回的数据有异常",title="温馨提示"},function(ok)
					callback(false)
					waiting=false
				end,true)
			end
		else
			popup.msgBox({text="请求支付接口时出现网络错误",title="温馨提示"},function(ok)
				callback(false)
				waiting=false
			end,true)
		end
	end)
	require("qwxt/public").showWaiting(nil,function()
		while waiting do
			coroutine.yield()
		end
	end,_,"正在进行支付......")
end

--获取活动列表
local function getActivityList(callback,waitParam)
	sendRequest("get_activity_list",nil,callback,waitParam)
end

--获取活动排行榜
local function getActivityRank(activityId,callback,waitParam)
	local param={v1=activityId}
	sendRequest("get_activity_rank",param,callback,waitParam)
end

--获取奖状快递信息
local function getExpressInfo(jiangzhuangId,callback,waitParam)
	local param={v1=jiangzhuangId}
	sendRequest("get_express_info",param,callback,waitParam)
end

return 
{
	getUserInfo=getUserInfo,
	getUserBaozang=getUserBaozang,
	getUserJiangzhuang=getUserJiangzhuang,
	getSelectedBook=getSelectedBook,
	setSelectedBook=setSelectedBook,
	getVersions=getVersions,
	getBooks=getBooks,
	getUnits=getUnits,
	getClasses=getClasses,
	newShuangbei=newShuangbei,
	getProblem=getProblem,
	submitAnswer=submitAnswer,
	regret=regret,
	getRankData=getRankData,
	setBGMusic=setBGMusic,
	mailJiangzhuang=mailJiangzhuang,
	getClassmateInfo=getClassmateInfo,
	getExpireTimePrice=getExpireTimePrice,
	rechargeExpireTime=rechargeExpireTime,
	getYinbiPrice=getYinbiPrice,
	rechargeYinbi=rechargeYinbi,
	rechargeByCard=rechargeByCard,
	pay=pay,
	getActivityList=getActivityList,
	getActivityRank=getActivityRank,
	getExpressInfo=getExpressInfo,
}