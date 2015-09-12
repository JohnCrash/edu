import os
import sys
import hashlib
import json
import string
import shutil

tar_directory = 'z:/debug'
src_directory = 'g:/source/Edu/EDEngine/proj.win32/Debug.win32'
recursive_error = 0
cpfile_count = 0

def copy_file(tar,src):
	global cpfile_count
	global recursive_error
	try:
		os.makedirs(os.path.split(tar)[0])
	except OSError  as err:
		pass
	try:
		shutil.copy(src,tar)
		print 'copy to '+tar+' success'
		cpfile_count = cpfile_count + 1
	except OSError as err:
		print "ERROR copy failed! "
		print "ERROR src : "+src
		print "ERROR tar : "+tar
		recursive_error=1		
	
def copy_dir(tar,proot):
	global recursive_error
	if recursive_error!=0 :
		return
	if(len(proot)>1 and proot[0]=='.' and proot[1]=='/'):
		dir = proot[2:]
	elif(proot[0]=='.'):
		dir = proot[1:]		
	else:
		dir = proot
	if os.path.isdir(proot) == False:
		print "[",proot,"] is not a dirpath"
	else:
		plist = os.listdir(proot);
		for d in plist:
			childdir = proot +"/" +  d
			if True == os.path.isdir(childdir):
				copy_dir(tar+"/"+d,childdir)
			else:
				if(d!='filelist.json' and d!='version.json'):
					copy_file(tar+"/"+d,childdir)
					if recursive_error!=0 :
						return
	
if __name__ == "__main__":
	if(len(sys.argv)>1):
		td_src = '/src/'+sys.argv[1]
		td_res = '/res/'+sys.argv[1]
		print "==========COPY FILE============="
		if len(sys.argv)>3 and sys.argv[3] == '-onlysrc':
			copy_dir(tar_directory+td_src,src_directory+td_src)				
		elif len(sys.argv)>3 and sys.argv[3] == '-onlyres':
			copy_dir(tar_directory+td_res,src_directory+td_res)							
		else:
			copy_dir(tar_directory+td_src,src_directory+td_src)
			copy_dir(tar_directory+td_res,src_directory+td_res)	
		if recursive_error==0 and cpfile_count!=0:
			print "==========UPDATE============="
			if len(sys.argv)>3:
				if os.system('update.py '+sys.argv[1]+' '+sys.argv[3])==0:
					print "==========UPLOAD============="
					if os.system('upload.py '+sys.argv[1]+' '+sys.argv[2]+' '+sys.argv[3])==0:
						print "==========DONE============="
			else:
				if os.system('update.py '+sys.argv[1])==0:
					print "==========UPLOAD============="
					if os.system('upload.py '+sys.argv[1]+' '+sys.argv[2])==0:
						print "==========DONE============="				
	else:
		print "Please input project name,example :release homework ftp_password [-onlysrc]"