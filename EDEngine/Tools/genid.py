import os
import hashlib
from datetime import datetime
if __name__=="__main__":
	print hashlib.md5(datetime.now().ctime()).hexdigest()