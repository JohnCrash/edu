import os

def mkdir2(sf,func):
	ps = []
	cur = sf
	while True:
		a = os.path.split(cur)
		ps.append(a[0])
		if a[1]==cur:
			break
		cur = a[0]
	for i in  reversed(ps):
		func(i)
		
def callback(s):
	print '['+s
	
if __name__ == '__main__':
	mkdir2('hello/p/world/a.c',lambda print s)