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


取得作业
		http://new.www.lejiaolexue.com/paper/handler/LoadPaperItem.ashx
	参数pid,uid
		?pid=93ca856727be4c09b8658935e81db8b8&uid=122097
		
单题答案暂存
	http://new.www.lejiaolexue.com/student/handler/WorkItem.ashx
	参数:
		examId:16190cacb1554279a0cd8dc8004e7c83
		itemId:004bf582a837441c81e40d3c0e43071b
		teacherId:122097
