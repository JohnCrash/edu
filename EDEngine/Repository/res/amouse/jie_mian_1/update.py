#Make XML file from dir

import os
import sys
import hashlib
from xml.etree.ElementTree import ElementTree
from xml.etree.ElementTree import Element
from xml.etree.ElementTree import SubElement
from xml.etree.ElementTree import dump
from xml.etree.ElementTree import Comment
from xml.etree.ElementTree import tostring

book = ElementTree()
root = Element("filelist")
book._setroot(root)

def	mmd5(name,bstr):
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
	return md5ret


def	ldir(proot,item):
	bdir = os.path.isdir(proot);
	if bdir == False:
		print "[",proot,"] is not a dirpath"
	else:
		plist = os.listdir(proot);
		for d in plist:
			childdir = proot +"/" +  d
			if True == os.path.isdir(childdir):
				subitem = Element("directory",{"name" : d.decode('gbk')})
				item.append(subitem)
				print "<director>",childdir
				ldir(childdir,subitem)
			else:
				md5val = mmd5(childdir,False)
				subitem = Element("file",{"name" : d.decode('gbk'),"md5" : md5val})
				item.append(subitem)
				print "[",d,"] <file>, md5: [",md5val,"]"

def	listxml(path):
	xmlhead = """<?xml version="1.0" encoding="UTF-8"?>\n"""
	f = open(path,"r+b")
	buf = f.read()
	f.seek(0);
	f.write(xmlhead)
	while(1):
		dex = buf.find(">")
		if len(buf) <= 0 or dex <= 0:
			break
		wbuf = buf[0:dex+1]
		buf = buf[dex + 1:]
		f.write(wbuf + "\n")
#		print wbuf
	f.close()

if __name__ == "__main__":
	xmlpath = "./filelist.xml"
	ldir(sys.argv[1],root)
	book.write(xmlpath,"utf-8")
	listxml(xmlpath)
	print "exit"
