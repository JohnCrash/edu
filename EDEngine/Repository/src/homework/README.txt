homework.lua 入口
loadingbox.lua 加载，网络错误等公用对话栏
workloading.lua 加载界面,进入界面
worklist.lua 作业表
workflow.lua 作业
	12种题型已经实现。
	编辑的问题，
	本地缓冲完成。
subjective.lua 主观题
commit.lua 提交
score.lua 提交结果
topics.lua 和题相关的缓冲


取得卷面 (老师端)
	http://new.www.lejiaolexue.com/paper/handler/LoadPaperItem.ashx
	参数pid,uid
		?pid=93ca856727be4c09b8658935e81db8b8&uid=122097
可能的数据结构:
	{
		"detail": [
			{
				"Id": "cd432d4d56474a99913ca255653ab3aa",
				"item_id": "9aec352705e94eac94171466838884a0",
				"item_oper": "",
				"item_oper_param1": 0,
				"item_parent": "9f88850d71324bd58dd0aef5706442d5",
				"item_type": 1,
				"paper_id": "15f4383c2ca948498de13a6933c9445b",
				"part_id": 2,
				"score": 230,
				"sort_stru": 1,
				"stru_id": 1,
				"tag": 2
			},
			...		
		],
	    "frame": [
			{
				"item_type": 14,
				"paper_id": "15f4383c2ca948498de13a6933c9445b",
				"part_id": 2,
				"score": "0",
				"score_show": 1,
				"stru_desc": "",
				"stru_id": 1,
				"stru_name": "复合",
				"tag_show": 1
			}
		],
		"item": null,
		"part": [
			{
				"paper_id": "15f4383c2ca948498de13a6933c9445b",
				"part_desc": "请点击修改第I卷的文字说明",
				"part_id": 1,
				"part_name": "第I卷（选择题）",
				"part_visible": 0
			},
			...
		]		
	}
	
单题提交		
	http://new.www.lejiaolexue.com/student/handler/SubmitAnswer.ashx
	参数:
		examId:900af39af9914b19a8b903acadfb86c1
		itemId:568f6630cf764f0cb8b7d5d7459c5e3f
		answer:A "填空用,分割"
		times:4 --做题用时
		tid:122097
	
取单题答案
	http://new.www.lejiaolexue.com/student/handler/WorkItem.ashx
	参数:
		examId:16190cacb1554279a0cd8dc8004e7c83
		itemId:004bf582a837441c81e40d3c0e43071b
		teacherId:122097

取作业列表
	http://new.www.lejiaolexue.com/student/handler/WorkList.ashx
	参数:
		p 页
提交作业
	http://new.www.lejiaolexue.com/student/SubmitPaper.aspx
	参数:
		examId=82b050ed3f4c44c3b76c92e5eb7e0c5c
		tid=122097
取结果
	http://new.www.lejiaolexue.com/paper/handler/LoadPaperItem.ashx
	同取作业
	参数pid,uid
		isright - 0错
		

取头像
seg1= (userId/10000)%100
seg2= (userId/100)%100
type =  
	face1: 1,// 在线头像、回复头像、访客头像 30x30
     face2: 2,//微博头像 50x50
     face3: 3,//
     face4: 4,//
http://image.lejiaolexue.com/ulogo/seg1/seg2/userId_type.jpg

提交顺序
1.学生端，取作业.
	http://new.www.lejiaolexue.com/student/handler/GetStudentItemList.ashx
	参数:
		teacherId
		examId
		teacherId=12297&examId=00231a8e919e4c6cbfaa601462adf49d
2.学生提交作业的顺序列表.
	http://new.www.lejiaolexue.com/student/handler/GetSubmitPaperSequence.ashx
	参数:
		teacherId
		examId	
	teacherId=122097&examId=00231a8e919e4c6cbfaa601462adf49d


老师端
取待批作业列表
	http://new.www.lejiaolexue.com/exam/handler/examhandler.ashx
	action:search
	exam-status:
	exam-tag:
	in-time:0
	in-time-begin:2013-11-11 11:11:11
	in-time-end:2014-08-05                           #搜索的时间范围
	course:0
	返回结构:
	{
		"cur_page": 1,
		"page": [
			{
				"book_version": 0,
				"cnt_class": 1,
				"cnt_student": 4,
				"course": 0,
				"course_name": "综合科目",
				"exam_id": "9e2358edd2454923a5d2178b2acea78b",
				"exam_name": "2014年07月16日一键导入试卷",
				"exam_type": 11,
				"finish_time": "/Date(1406287560000+0800)/",
				"in_time": "/Date(1406201190443+0800)/",
				"real_score":100,
				"items": 7,
				"node_section": 0,
				"node_section_name": "",
				"node_unit": 0,
				"node_vol": 0,
				"open_time": "/Date(1406201160000+0800)/",
				"paper_id": "15f4383c2ca948498de13a6933c9445b",
				"period": 1,
				"score_type": 2,
				"span_time": 30,
				"state": 1,
				"tag_comment": 0,
				"tag_parentcheck": 0,
				"tag_selfcheck": 1,
				"tag_solution": 1,
				"teacher_id": 122097
			},
		],
		...
		"total_item": 36,
		"total_page": 4	
	}
	
取班级	
	http://new.www.lejiaolexue.com/exam/handler/examhandler.ashx
	?action=brief&examid=f823cf1e1f8d454bb85295468a452019
	返回结构:
	[
		{
			"class_id": 141442,
			"class_name": "四年级三班",
			"cnt_group": 0,
			"cnt_student": 4,
			"cnt_student_mark": 1,
			"cnt_student_submit": 1,
			"exam_id": "f823cf1e1f8d454bb85295468a452019",
			"has_score": 0,
			"paper_id": "b3f0a76890eb4c0496437ad45023739a",
			"real_score": 0,
			"school_id": 126453,
			"state": 1,
			"teacher_id": 122097
		}
	]

取得作业成绩,全班的统计	
	http://new.www.lejiaolexue.com/exam/handler/ExamStatistic.ashx
	?q=table&exam_id=9e2358edd2454923a5d2178b2acea78b&c_id=141442
	返回结构:
	{"ave_score":0,"highest_score":0,"lowest_score":0,"median":0,"st_dev":0}

班级作业的统计信息
	http://new.www.lejiaolexue.com/exam/handler/examstatistic.ashx
	?q=rank&exam_id=9e2358edd2454923a5d2178b2acea78b&c_id=141442&has_score=1
	返回结构: 其中status = 10 or 11 表示已经提交
	[
		{
			"correct": 25,
			"id": 1,
			"real_score": 3,
			"score": 30,
			"status": 0,
			"student_id": 125907,
			"student_name": "杨朝来",
			"time": 3
		},
		...
	]