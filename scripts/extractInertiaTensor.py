import sys
import numpy as np

inName  = sys.argv[1] 
outName = sys.argv[2] 

I = np.loadtxt(inName)
#Remove first column
I=I[:,1:]

I=np.asarray([i.reshape(3,3) for i in I])

np.save(outName,I)
