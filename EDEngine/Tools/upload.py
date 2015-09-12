#
import os
import sys
import hashlib
import json
import string
import shutil
import ftplib

ftp = ftplib.FTP()

ftp_directory='luaapp/debug'
local_output = 'output'

def open_ftp(host,port,pwd):
	try:		
		ftp.connect(host,port)
		print ftp.login('upgrade_ftp',pwd)
		print ftp.getwelcome()
		print "connect "+host+":"+str(port)+" success"
		return True
	except ftplib.all_errors as e:
		print "fpt connect "+host+":"+str(port)+" failed!"
		return False
		
def close_ftp():
	try:
		ftp.quit()
		ftp.close()
		print "close success"
	except ftplib.all_errors as e:
		print "fpt close failed!"
		
def download_file(sf,lf):
	try:
		ftp.retrbinary('RETR '+sf,open(lf,'wb').write)
		return True
	except ftplib.all_errors as e:
		return False
	except IOError as e:
		return False
		
def upload_file(sf,lf):
	try:
		ftp.storbinary('STOR '+sf,open(lf,'rb'))
		return True
	except ftplib.all_errors as e:
		return False
	except IOError as e:
		return False
		
def size_file(sf):
	try:
		return ftp.size(sf)
	except ftplib.all_errors as e:
		return -1
		
def checkdir(sf):
	try:
		curdir = ftp.pwd()
		ftp.cwd(sf)
		ftp.cwd(curdir)
		return True
	except ftplib.all_errors as e:
		return False
		
def mkdir(sf):
	try:
		ftp.mkd(sf)
		return True
	except ftplib.all_errors as e:
		return False
		
def mkdir2(sf):
	ps = []
	cur = sf
	while True:
		a = os.path.split(cur)
		ps.append(a[0])
		if a[1]==cur:
			break
		cur = a[0]
	for i in  reversed(ps):
		try:
			if checkdir(i)!=True:
				ftp.mkd(i)
		except ftplib.all_errors as e:
			return True
	return True
		
def check_rootdir(lf):
	if checkdir(lf)==True :
		return True
	else:
		return mkdir(lf)
		
def size_local_file(lf):
	try:
		fp = open(lf,'rb')
		fp.seek(0,os.SEEK_END)
		return fp.tell()
	except IOError as e:
		return -1

recursive_error = 0
upload_count = 0

def upload_file2(sf,lf):
	global upload_count
	if upload_file(sf,lf)!=True:
		if mkdir2(sf)==True:
			if upload_file(sf,lf)==True:
				fs = size_file(sf)
				ls = size_local_file(lf)			
				if fs!=-1 and fs==ls :
					print "upload file : "+str(lf)+" success"
					upload_count = upload_count+1
					return True
				else:
					print "upload file : "+str(sf)+" form "+str(lf)+" failed!"
					print "	server file length : "+str(fs)
					print "	local file length : "+str(ls)
					return False
			else:
				print "upload file : "+str(sf)+" form "+str(lf)+" failed!"
				return False
		else:
			print "upload file : "+str(sf)+" form "+str(lf)+" failed!"
			print "	can not create directory "+str(sf)
			return False
	else:
		fs = size_file(sf)
		ls = size_local_file(lf)			
		if fs!=-1 and fs==ls :
			print "upload file : "+str(lf)+" success"
			upload_count = upload_count+1
			return True
		else:
			print "upload file : "+str(sf)+" form "+str(lf)+" failed!"
			print "	server file length : "+str(fs)
			print "	local file length : "+str(ls)
			return False
	
def synchronize_file(sf,lf):
	global recursive_error
	fs = size_file(sf)
	ls = size_local_file(lf)
	if ls!=-1 and fs!=-1 and fs==ls :
		return True
	elif ls!=-1 and fs!=-1 and fs!=ls:
		if upload_file2(sf,lf)==True:
			return True
		else:
			recursive_error = 1
			return False
	elif fs==-1 and ls!=-1:
		if upload_file2(sf,lf)==True:
			return True
		else:
			recursive_error = 1
			return False
	else:
		print "synchronize_file can not read local file "+str(lf)
		recursive_error = 1
		return False
	
def recursive_dir(sf,proot):
	global recursive_error
	global local_output
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
				recursive_dir(sf,childdir)
			else:
				if(d!='filelist.json' and d!='version.json'):
					synchronize_file(sf+childdir[len(local_output):],childdir)
					if recursive_error!=0 :
						return
							
def synchronize_dir(sf,lf):
	global recursive_error
	global upload_count
	global local_output
	if os.path.isdir(lf) :
		recursive_dir(sf,lf)
		if recursive_error==0:
			a = lf[len(local_output):]
			upload_file2(sf+a+'/filelist.json',lf+'/filelist.json')
			upload_file2(sf+a+'/version.json',lf+'/version.json')
	else:
		print "synchronize_dir local directory "+str(lf)+" is not exist"

if __name__ == "__main__":
	if(len(sys.argv)>1):
		if open_ftp('211.154.173.152',2121,sys.argv[2]) == True :
			td_src = '/src/'+sys.argv[1]
			td_res = '/res/'+sys.argv[1]
			check_rootdir(ftp_directory)
			check_rootdir(ftp_directory+"/src")
			check_rootdir(ftp_directory+"/res")
			if len(sys.argv)>3 and sys.argv[3] == '-onlysrc':
				synchronize_dir(ftp_directory,local_output+td_src)			
			elif len(sys.argv)>3 and sys.argv[3] == '-onlyres':
				synchronize_dir(ftp_directory,local_output+td_res)							
			else:
				synchronize_dir(ftp_directory,local_output+td_src)
				synchronize_dir(ftp_directory,local_output+td_res)				
			close_ftp()
			if recursive_error==0:
				os._exit(0)
			else:
				os._exit(-1)
	else:
		print "Please input project name,example :upload homework ftp_password [-onlysrc]"
		os._exit(-1)