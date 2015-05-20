#Make XML file from dir

import os
import sys
import hashlib
import json
import string
import shutil

current_path = ""

def mmd5(name,bstr):
	if bstr == True:
		md5ret = hashlib.md5(name.encode('utf-8')).hexdigest()
	else:
		if os.path.isdir(name) == True:
			print name, "is a dir, can not make md5"
			return 0;
		md5file = open(name,'rb')
		if(md5file):
			md5ret = hashlib.md5(md5file.read()).hexdigest()
			md5file.close()
		else:
			md5ret = 'error'
	return md5ret

def copyfile(src,des,md5):
	try:
		os.makedirs(os.path.split(des)[0])
	except OSError  as err:
		pass
	try:
		shutil.copy(src,des+"_"+md5)
	except OSError as err:
		print "ERROR copy failed! "
		print "ERROR src : "+src
		print "ERROR des : "+des
		print "ERROR md5 : "+md5
	
def ldir(proot,item):
	bdir = os.path.isdir(proot)
	if(len(proot)>1 and proot[0]=='.' and proot[1]=='/'):
		dir = proot[2:]
	elif(proot[0]=='.'):
		dir = proot[1:]		
	else:
		dir = proot
	if bdir == False:
		print "[",proot,"] is not a dirpath"
	else:
		plist = os.listdir(proot);
		for d in plist:
			childdir = proot +"/" +  d
			if True == os.path.isdir(childdir):
				ldir(childdir,item)
			else:
				if(d!='filelist.json' and d!='version.json'):
					md5val = mmd5(childdir,False)
					copyfile(childdir,"../../output/"+current_path+"/"+childdir,md5val)
					low = string.lower(d)
					if(len(dir)>0): #has dir
						if low != 'thumbs.db' and low != 'resume.lua' and low[0]!='.':
							item.append({'name':dir+"/"+d,'md5':md5val})
							print dir+"/"+d,"\t",md5val
						else:
							print "found ",d
					else:
						if low != 'thumbs.db' and low != 'resume.lua'  and low[0]!='.':
							item.append({'name':d,'md5':md5val})
							print d,"\t",md5val
						else:
							print "found ",d
					
def write_json(root):
	filelist = open('filelist.json','w')
	if(filelist):
		filelist.write(json.dumps(root))
		filelist.close()
	else:
		print "Can't open file filelist.json"
	version = 1
	try:
		version_file = open('version.json','rb')
		if(version_file):
			version_json = json.loads(version_file.read())
			if(version_json and version_json["version"]):
				version = version_json["version"] + 1
			else:
				print "verson.json decode error"
			version_file.close()
	except IOError:
		print "Can't open version.json"
		print "create version.json set version=1"
		
	version_file = open('version.json','wb')
	if(version_file):
		version_file.write(json.dumps({"version":version}))
		version_file.close()	
	
def copyjson(dir):
	try:
		shutil.copy(dir+"/version.json","output/"+dir+"/version.json")
		shutil.copy(dir+"/filelist.json","output/"+dir+"/filelist.json")
	except OSError as err:
		print "ERROR copy version.json failed"
		
if __name__ == "__main__":
	if(len(sys.argv)>1):
		if(os.path.isdir('src/'+sys.argv[1]) and os.path.isdir('res/'+sys.argv[1])):
			try:
				shutil.rmtree("output/src")
			except OSError  as err:
				print "ERROR rmtree output/src"
			try:
				shutil.rmtree("output/res")		
			except OSError  as err:
				print "ERROR rmtree output/src"
			os.chdir('src/'+sys.argv[1])
			current_path = "src/"+sys.argv[1]
			root = []
			ldir('.',root)
			write_json(root)
			os.chdir('../..')
			os.chdir('res/'+sys.argv[1])
			current_path = "res/"+sys.argv[1]
			root = []
			ldir('.',root)
			write_json(root)
			os.chdir('../..')
			copyjson("src/"+sys.argv[1])
			copyjson("res/"+sys.argv[1])
		elif(os.path.isdir('class/'+sys.argv[1])):
			os.chdir('class/'+sys.argv[1])
			root=[]
			ldir('.',root)
			write_json(root)
			os.chdir('../..')
			print "Copy to z:/v7/class/"+sys.argv[1]
			if os.path.isdir('z:/v7/class/'+sys.argv[1]) :
				shutil.rmtree('z:/v7/class/'+sys.argv[1])
			shutil.copytree('class/'+sys.argv[1],'z:/v7/class/'+sys.argv[1])
			print "Done."
		else:
			print "Directory src/"+sys.argv[1]," or res/"+sys.argv[1]," is not exist!"
	else:
		print "Please input project name,example :update homework"
