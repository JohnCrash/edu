local kits = require 'kits'
local cache = require 'cache'
local json = require 'json-c'

local course={
	[101]="综合科目",
	[10001]="小学语文",
	[10002]="小学数学",
	[10003]="小学英语",
	[10005]="小学英语笔试",
	[10009]="(小学)信息技术",
	[10010]="(小学)安全知识",
	[10011]="(小学)智力百科",
	[11005]="小学英语听力",
	[20001]="初中语文",
	[20002]="初中数学",
	[20003]="初中英语",
	[20004]="初中物理",
	[20005]="初中化学",
	[20006]="初中政治",
	[20007]="初中生物",
	[20008]="初中地理",
	[20009]="初中历史",
	[30001]="高中语文",
	[30002]="高中数学",
	[30003]="高中英语",
	[30004]="高中物理",
	[30005]="高中化学",
	[30006]="高中政治",
	[30007]="高中生物",
	[30008]="高中地理",
	[30009]="高中历史",
}

local topics={
	[1]="判断",
	[2]="单选",
	[3]="多选",
	[4]="连线",
	[5]="填空",
	[6]="选择",
	[7]="横排序",
	[8]="竖排序",
	[9]="点图单选",
	[10]="点图多选",
	[11]="单拖放",
	[12]="多拖放",
	[13]="完形",
	[14]="复合",
	[15]="主观有答案",
	[16]="主观无答案",
}

local course_icon={
	[0] = {name="综合科目",logo="zhonghe.png"},
	[101]={name="综合科目",logo="zhonghe.png"},
	[10001]={name="小学语文",logo="chinese1.jpg"},
	[10002]={name="小学数学",logo="math.jpg"},
	[10003]={name="小学英语",logo="english.jpg"},
	[10005]={name="小学英语笔试",logo="english.jpg"},
	[10009]={name="(小学)信息技术",logo="infomation.jpg"},
	[10010]={name="(小学)安全知识",logo=""},
	[10011]={name="(小学)智力百科",logo=""},
	[11005]={name="小学英语听力",logo="english.jpg"},
	[20001]={name="初中语文",logo="chinese1.jpg"},
	[20002]={name="初中数学",logo="math.jpg"},
	[20003]={name="初中英语",logo="english.jpg"},
	[20004]={name="初中物理",logo="physics.jpg"},
	[20005]={name="初中化学",logo="chemistry.jpg"},
	[20006]={name="初中政治",logo="politics.jpg"},
	[20007]={name="初中生物",logo="biolody.jpg"},
	[20008]={name="初中地理",logo="geography.jpg"},
	[20009]={name="初中历史",logo="history.jpg"},
	[30001]={name="高中语文",logo="chinese1.jpg"},
	[30002]={name="高中数学",logo="math.jpg"},
	[30003]={name="高中英语",logo="english.jpg"},
	[30004]={name="高中物理",logo="physics.jpg"},
	[30005]={name="高中化学",logo="chemistry.jpg"},
	[30006]={name="高中政治",logo="politics.jpg"},
	[30007]={name="高中生物",logo="biolody.jpg"},
	[30008]={name="高中地理",logo="geography.jpg"},
	[30009]={name="高中历史",logo="history.jpg"},
}

local function read_topics_cache( pid )
	local result = kits.read_cache( pid )
	if result then
		local t = json.decode(result)
		if t then
			return t
		else
			print('error : t = nil, read_topics_cache pid = '..tostring(pid))
		end
	else
		print('error : result = nil , read_topics_cache pid = '..tostring(pid))
	end
end

local function write_topics_cache( pid,t )
	local result = json.encode( t,2 )
	if result then
		kits.write_cache( pid,result )
	else
		print('error : result = nil, write_topics_cache pid = '..tostring(pid))
	end
end

return 
{
	read = read_topics_cache,
	write = write_topics_cache,
	course_map = course,
	topics_map = topics,
	course_icon = course_icon,
}
