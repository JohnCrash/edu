#Make XML file from dir

import os
import sys
import hashlib
import json

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
					if(len(dir)>0): #has dir
						item.append({'name':dir+"/"+d,'md5':md5val})
						print dir+"/"+d,"\t",md5val
					else:
						item.append({'name':d,'md5':md5val})
						print d,"\t",md5val
					
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
    
if __name__ == "__main__":
	xmlpath = "./filelist.xml"
	if(len(sys.argv)>1):
		if(os.path.isdir('src/'+sys.argv[1]) and os.path.isdir('res/'+sys.argv[1])):
			os.chdir('src/'+sys.argv[1])
			root = []
			ldir('.',root)
			write_json(root)
			os.chdir('../..')
			os.chdir('res/'+sys.argv[1])
			root = []
			ldir('.',root)
			write_json(root)			
		else:
			print "Directory src/"+sys.argv[1]," or res/"+sys.argv[1]," is not exist!"
	else:
		print "Please input project name,examples:update homework"
