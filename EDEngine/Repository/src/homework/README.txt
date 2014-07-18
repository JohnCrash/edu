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
http://new.www.lejiaolexue.com/student/handler/GetStudentItemList.ashx?teacherId=12297&examId=00231a8e919e4c6cbfaa601462adf49d
2.学生提交作业的顺序列表.
http://new.www.lejiaolexue.com/student/handler/GetSubmitPaperSequence.ashx?teacherId=122097&examId=00231a8e919e4c6cbfaa601462adf49d


统计

分支合并		
lua_cocos2dx_manual.cpp
	5514
<<<<<<< my-branch
    if (argc == 0)
=======
    if (argc >= 3 && argc <= 6)
>>>>>>> e1b29a8ef61248ec047b17be921e031d0d637904