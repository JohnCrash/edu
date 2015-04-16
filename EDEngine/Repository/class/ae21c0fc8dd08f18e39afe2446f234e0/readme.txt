关卡定义说明
{
	skin: 关卡皮肤固定可选1,..
	character: 角色固定可选1,...
	section:[ 关卡题目组
		{ --第一题
			type:1
			...具体数据见下面
		},
	]
}

具体的关卡类型
type=1,默认道路占位

type=2,算式,搭桥
pattern:"" ,举例1?+2?=??，?代表可选
select:"",可选集合1,2,3,3
ismuti:true,false,可选集是不是可以重新复用

type=3,拆墙
patterns:[
	pattern:"6?+2=??",
	select:"",
	ismuti:"",
]

type=4,隧道
数据类型等同于type=2,只不过是消除