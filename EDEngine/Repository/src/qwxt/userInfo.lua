--用户信息
userInfo=userInfo or
{
	uid=tonumber(require("login").uid()),		--用户id
	name="",						--名字
	notStudent=false,				--是否学生账号
	xueduan=1,						--学段
	expireDays=0,					--会员有效期剩余天数
	yinbi=0,						--银币
	level=0,						--等级
	exp=0,							--经验值
	baozangCount=0,					--宝藏数
	jiangzhuangCount=0,				--奖状数
	shuangbei=0,					--双倍题数

	subjectData=nil,				--选择的科目数据 {id,name,img,background,map,danyuanBackground,zuotiBackground,liandui,versions}(versions为数组)
	versionData=nil,				--选择的教材版本数据 {id,name,books}(books为数组)
	bookData=nil,					--选择的教材数据 {id,name,units}(units为数组)
	unitData=nil,					--选择的的单元数据 {id,name,progress,totalCount,rightCount,nodeType,classes}(classes为数组)
	classData=nil,					--选择的课数据 {id,name,progress,totalCount,rightCount,nodeType}
									--nodeType定义：1--神秘宝屋；2--秘境探险；3--课练习
}
userInfo.selectSubject=function(subjectData)
	if userInfo.subjectData==nil or userInfo.subjectData.id~=subjectData.id then
		userInfo.subjectData=subjectData
		userInfo.versionData=nil
		userInfo.bookData=nil
		userInfo.unitData=nil
		userInfo.classData=nil
	end
end

--做题统计
problemCount=problemCount or
{
	total=0,
	wrong=0,
	yinbi=0,
	exp=0,
}
--重置做题统计
problemCount.reset=function()
	problemCount.total=0
	problemCount.wrong=0
	problemCount.yinbi=0
	problemCount.exp=0
end
--增加做题统计
problemCount.addCount=function(yinbi,exp,right)
	problemCount.total=problemCount.total+1
	if not right then
		problemCount.wrong=problemCount.wrong+1
	end
	problemCount.yinbi=problemCount.yinbi+yinbi
	problemCount.exp=problemCount.exp+exp
end
