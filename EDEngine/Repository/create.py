import os
import sys
import hashlib
import json
import codecs
from datetime import datetime

base = ["7c3064bb858e619b9f02fef85432f162",
	"b50a67aa2ed2183bee9b804ce7dbdefd",
	"8bb51443e440190b892996b8c2864672",
	"8736daf38faaa28693f922843cc0c5aa",
	"b34d6d7a5652cf3bbe6388d5770dbe95",
	"6e8c7a6612998e78186585e468010f95"]
	
def create_class(classid,superid,name,desc):
	if(os.path.isdir('class/'+classid)):
		print "class "+classid,"is existed"
	elif(len(superid)==0 or (not os.path.isdir('class/'+superid) and not superid in base)):
		print "superid ",superid,"is not exist"
	else:
		os.mkdir('class/'+classid)
		descFile = open('class/'+classid+'/desc.json','w')
		descFile.write('{\n')
		descFile.write('	"classid":"'+classid+'",\n')
		descFile.write('	"superid":"'+superid+'",\n')
		descFile.write('	"name":"'+name+'",\n')
		descFile.write('	"comment":"'+desc+'",\n')
		descFile.write('	"pedigree":[\n')
		if superid in base:
			if superid=="7c3064bb858e619b9f02fef85432f162":
				pass
			else:
				descFile.write('		"7c3064bb858e619b9f02fef85432f162"\n')	
		else:
			#read super desc.json file
			sdescFile = open('class/'+superid+'/desc.json','rb')
			if sdescFile:
				try:
					superdesc = json.loads(sdescFile.read().decode('utf-8-sig'))
				except UnicodeDecodeError:
					print "==UnicodeDecodeError=="
					descFile.close()
					
				if superdesc and superdesc["superid"]:
					descFile.write('		"'+superdesc["superid"]+'",\n')
				if superdesc and superdesc["pedigree"]:
					count = 0
					for x in superdesc["pedigree"]:
						if count != 0:
							descFile.write(',\n')
						count = count+1
						descFile.write('		"'+x+'"')
				else:
					print "Warning super class has not pedigree ",superid
		descFile.write('	],\n')
		descFile.write('	"version":1\n')
		descFile.write('}\n')
		descFile.close()
		print "create ",classid," done!"
		
if __name__=="__main__":
	classid=hashlib.md5(datetime.now().ctime()).hexdigest()
	name = ""
	desc = ""
	superid = ""
	for v in sys.argv:
		if v[0:8] == 'superid=':
			superid = v[8:]
		elif v[0:5]== 'name=':
			name = v[5:]
		elif v[0:5]== 'desc=':
			desc = v[5:]
	create_class(classid,superid,name,desc)