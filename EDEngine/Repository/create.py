import os
import sys
import hashlib
import json
import codecs
from datetime import datetime

base = {
	"Root":"7c3064bb858e619b9f02fef85432f162",
	"Node":"7cd2ed98a8dc8ca1994a7438d563e596",
	"SplashScene":"b50a67aa2ed2183bee9b804ce7dbdefd",
	"LoadingScene":"8bb51443e440190b892996b8c2864672",
	"Dialog":"f9e6338b892d9da54fc0668d5f1bd19c",
	"MessageBox":"8736daf38faaa28693f922843cc0c5aa",
	"Spin":"b34d6d7a5652cf3bbe6388d5770dbe95",
	"ProgressBox":"6e8c7a6612998e78186585e468010f95",
	"Scene":"d55f6d9cbb48b6f402b8122b97ed2dc1",
	"PhysicsScene":"fe3b5a71265217def35a0633f8e85c6f",
	"Layer":"685316259b01edf58a85d6705a4541ad",
	"Widget":"67f40d28c8cb0b5141b7d8dca355ad58",
	"Layout":"d00696dff16c2e217c24cc1fed8ba49e",
	"Button":"e051f121c6a2ec01bae324c270f55ee5",
	"ScrollView":"a8e99a03bc830f5d2d904be27302d0c2",
	"Text":"ba6864653e414016e9f1848ee5986654",
	"ProgressBar":"9b954ac14796cf7c24c4a5863c3f5b93",
	"ScrollBar":"3257930559cf3e68453bd537e08f63ff",
	"PopupMenu":"b5141f9ea3bfc7f45fda60e8f44dde41",
	"BaiduVoice":"5b16c70370e6791975778195b421524b",
	"Game":"9bb2c0c57a6b6a3763875bbf71b8a0c2",
	"Sprite":"5e0c81c61dcebe5b27b6c6c54b5b4414",
	"Item":"f84f4bfc387cdc692c07ab1cc16da18d",
	}

level2 = {
	"Node":"7cd2ed98a8dc8ca1994a7438d563e596",
	"Dialog":"f9e6338b892d9da54fc0668d5f1bd19c",
	"Game":"9bb2c0c57a6b6a3763875bbf71b8a0c2",
	"Scene":"d55f6d9cbb48b6f402b8122b97ed2dc1",
}

def create_class(classid,superid,name,desc):
	if(os.path.isdir('class/'+classid)):
		print "class "+classid,"is existed"
	elif(len(superid)==0 or (not os.path.isdir('class/'+superid) and (not superid in base.keys()) and (not superid in base.values()))):
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
			if superid=="7c3064bb858e619b9f02fef85432f162" or "Root":
				pass
			elif superid in level2:
				descFile.write('		"Root"\n')	
			else:
				descFile.write('		You need to manually fill\n')	
		else:
			#read super desc.json file
			sdescFile = open('class/'+superid+'/desc.json','rb')
			if sdescFile:
				try:
					superdesc = json.loads(sdescFile.read().decode('utf-8-sig'))
				except UnicodeDecodeError:
					print "==UnicodeDecodeError=="
					descFile.close()
					return
					
				if superdesc and superdesc["superid"]:
					descFile.write('		"'+superdesc["superid"]+'",\n')
				if superdesc and superdesc["pedigree"]:
					idx = 1
					count = len(superdesc["pedigree"])
					for x in superdesc["pedigree"]:
						descFile.write('		"'+x+'"')
						if count != idx:
							descFile.write(',\n')
						idx = idx+1
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
	if len(superid)==0 :
		print "create superid=SUPERID name=NAME desc=DESCRIPT\n"
	else:
		create_class(classid,superid,name,desc)