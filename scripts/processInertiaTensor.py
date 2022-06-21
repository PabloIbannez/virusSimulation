import sys
import numpy as np
from numpy import linalg as LA

inName  = sys.argv[1]
outName = sys.argv[2]

I = np.load(inName)

Idiag = [LA.eig(i) for i in I]
