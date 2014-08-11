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
	
取单题内容	
	http://new.www.lejiaolexue.com/exam/handler/ExamStructure.ashx
	?q=item&exam_id=10f6cc6397464e829e10747b1c1ac800&item_id=004bf582a837441c81e40d3c0e43071b&_=1407726806982
	返回:
	{
		"Id": "8b085f68b5dd42b98e58d5ef6ee4cccb",
		"answer": 1,
		"apply_area1": 0,
		"apply_area2": 0,
		"apply_year": 0,
		"attachment": "{\"attachments\":[{\"group\":\"1\",\"id\":\"1\",\"mini_src\":\"f1f87e2f0934d70c3c16933c628767c3.mp3\",\"name\":null,\"type\":\"0\",\"value\":\"http:\\/\\/image.lejiaolexue.com\\/item_image\\/127\\/112\\/f1f87e2f0934d70c3c16933c628767c3.mp3\"}]}",
		"attachment_obj": [],
		"cnt_comment": 0,
		"cnt_favor": 0,
		"cnt_praise": 0,
		"cnt_refer": 0,
		"cnt_view": 0,
		"content": "<div class=wordsection1><div><div><div><div><div><p class=msonormal align=center style='margin:0cm;margin-bottom:.0001pt;\r\ntext-align:center'><b><span style='font-size:16.0pt;font-family:楷体_gb2312;\r\ncolor:green'>戴上声调帽儿，拼音变完整。</span></b></p>\r\n\r\n<p class=msonormal align=center style='margin:0cm;margin-bottom:.0001pt;\r\ntext-align:center'><span lang=en-us style='font-size:5.5pt'>&nbsp;</span></p>\r\n\r\n<p align=center style='text-align:center'><span lang=en-us><img mini_src=\"07d8fee86792b54e2c66efe464b5bfa0.jpg\" mini=\"http://image.lejiaolexue.com/item_image/139/354/07d8fee86792b54e2c66efe464b5bfa0.jpg\" src=\"http://image.lejiaolexue.com/item_image/139/354/07d8fee86792b54e2c66efe464b5bfa0.jpg\" /></span></p>\r\n\r\n<p align=center style='text-align:center'><span lang=en-us style='font-size:\r\n9.0pt'>&nbsp;</span></p>\r\n\r\n<p class=msonormal align=center style='text-align:center'><span lang=en-us>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span></p>\r\n\r\n<p><span lang=en-us><img mini_src=\"b0e3cc9558667bf999091bc754bac228.png\" mini=\"http://image.lejiaolexue.com/item_image/135/210/b0e3cc9558667bf999091bc754bac228.png\" src=\"http://image.lejiaolexue.com/item_image/135/210/b0e3cc9558667bf999091bc754bac228.png\" />",
		"correct_answer": "{\"answers\":[{\"id\":\"0\",\"value\":\"BDC\"}]}",
		"correct_answer_obj": [],
		"course": 10001,
		"difficulty": 50,
		"difficulty_name": "中等",
		"explain": "<span lang=en-us><img mini_src=\"2c1049b8559848ac1d97124a86fe894b.png\" mini=\"http://image.lejiaolexue.com/item_image/32/117/2c1049b8559848ac1d97124a86fe894b.png\" src=\"http://image.lejiaolexue.com/item_image/32/117/2c1049b8559848ac1d97124a86fe894b.png\" /></span></p></div></div></div></div></div></div>",
		"from_paper": null,
		"in_time": "/Date(1407395070467+0800)/",
		"in_time_ts": 0,
		"interact_type": 64,
		"item_id": "004bf582a837441c81e40d3c0e43071b",
		"item_id_num": 191738,
		"item_name": "连线",
		"item_type": 4,
		"last_time": "/Date(1407395070467+0800)/",
		"last_time_ts": 0,
		"options": "{\"char_num\":null,\"drag_position\":\"0\",\"item_type\":\"3\",\"oper\":null,\"options\":[{\"id\":\"1\",\"option\":\"A.\\\"<img mini_src=\\\"5d224e55a5895665c0cb1e8310cde599.jpg\\\" mini=\\\"http:\\/\\/image.lejiaolexue.com\\/item_image\\/989\\/154\\/5d224e55a5895665c0cb1e8310cde599.jpg\\\" src=\\\"http:\\/\\/image.lejiaolexue.com\\/item_image\\/989\\/154\\/5d224e55a5895665c0cb1e8310cde599.jpg\\\" \\/>\\\"\"},{\"id\":\"2\",\"option\":\"B.\\\"<img mini_src=\\\"1f8638d3406a80350ce90f80841e0acb.jpg\\\" mini=\\\"http:\\/\\/image.lejiaolexue.com\\/item_image\\/978\\/137\\/1f8638d3406a80350ce90f80841e0acb.jpg\\\" src=\\\"http:\\/\\/image.lejiaolexue.com\\/item_image\\/978\\/137\\/1f8638d3406a80350ce90f80841e0acb.jpg\\\" \\/>\\\"\"},{\"id\":\"3\",\"option\":\"C.\\\"<img mini_src=\\\"6f977624be7c33ce0cd1800391f4ba77.jpg\\\" mini=\\\"http:\\/\\/image.lejiaolexue.com\\/item_image\\/134\\/198\\/6f977624be7c33ce0cd1800391f4ba77.jpg\\\" src=\\\"http:\\/\\/image.lejiaolexue.com\\/item_image\\/134\\/198\\/6f977624be7c33ce0cd1800391f4ba77.jpg\\\" \\/>\\\"\"}],\"options2\":[{\"id\":\"1\",\"option\":\"A.\\\"<img mini_src=\\\"514b14883e1af96720a3fde60926b749.png\\\" mini=\\\"http:\\/\\/image.lejiaolexue.com\\/item_image\\/31\\/105\\/514b14883e1af96720a3fde60926b749.png\\\" src=\\\"http:\\/\\/image.lejiaolexue.com\\/item_image\\/31\\/105\\/514b14883e1af96720a3fde60926b749.png\\\" \\/>\\\"\"},{\"id\":\"2\",\"option\":\"B.\\\"<img mini_src=\\\"859770e1da627314810ef36f60325865.png\\\" mini=\\\"http:\\/\\/image.lejiaolexue.com\\/item_image\\/982\\/964\\/859770e1da627314810ef36f60325865.png\\\" src=\\\"http:\\/\\/image.lejiaolexue.com\\/item_image\\/982\\/964\\/859770e1da627314810ef36f60325865.png\\\" \\/>\\\"\"},{\"id\":\"3\",\"option\":\"C.\\\"<img mini_src=\\\"089314e570e497da7dccab13dfb0b966.png\\\" mini=\\\"http:\\/\\/image.lejiaolexue.com\\/item_image\\/32\\/291\\/089314e570e497da7dccab13dfb0b966.png\\\" src=\\\"http:\\/\\/image.lejiaolexue.com\\/item_image\\/32\\/291\\/089314e570e497da7dccab13dfb0b966.png\\\" \\/>\\\"\"},{\"id\":\"4\",\"option\":\"D.\\\"<img mini_src=\\\"e15247bf0c8b0afb219788883ad34f8a.png\\\" mini=\\\"http:\\/\\/image.lejiaolexue.com\\/item_image\\/206\\/247\\/e15247bf0c8b0afb219788883ad34f8a.png\\\" src=\\\"http:\\/\\/image.lejiaolexue.com\\/item_image\\/206\\/247\\/e15247bf0c8b0afb219788883ad34f8a.png\\\" \\/><\\/span>\\\"\"}],\"sort_char\":\"\"}",
		"options_obj": {
			"drag_position": 0,
			"item_type": 0,
			"options": [],
			"options2": [],
			"sort_char": null
		},
		"parent_item_id": "",
		"real_score": 1,
		"ref_item_id": "",
		"score": 10,
		"section_name": "汉语拼音（b p m f）",
		"sub_count": 0,
		"sub_sort": 0,
		"tag": 0,
		"tag_apply": 7,
		"tag_detail": 1,
		"tag_method": 115,
		"tag_open": 1,
		"tag_original": 1,
		"test_point": null,
		"user_author": 0,
		"user_author_name": "",
		"user_owner": 0,
		"version": 1
	}