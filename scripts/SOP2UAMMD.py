import sys

import itertools

from Topology import *

######################

cutOffFactor = 2.5

STERIC_INTERACTION = "steric;UnBound;Steric6;condition=intra,cutOffDst={}"

INTRA_ENERGY = 1.0
INTER_ENERGY = 1.0

MODELS = {"SOP_COVALENT":"covalent;Bond2;FeneConst_K_R0;K=20.15,R0=2.0",
          "SOP_NATIVE_CONTACT":"nativeContact;Bond2;LennardJonesType2"}

######################

COORD_IN  = sys.argv[1]
TOP_IN    = sys.argv[2]

OUT       = sys.argv[3]

top = Topology(COORD_IN,TOP_IN)

stericInfo = []

#maxSigma = 0
maxSigma = 3.8
for t1,t2 in itertools.product(top.propertiesLoaded["TYPES"],repeat=2):
    
    n1=(t1[0].split()[0])
    n2=(t2[0].split()[0])

    #r1=float(t1[0].split()[2])
    #r2=float(t2[0].split()[2])

    #sigma = r1+r2
    #maxSigma = max(maxSigma,sigma)

    #stericInfo.append(["{} {} 1.0 {}\n".format(n1,n2,round(r1+r2,2))])
    stericInfo.append(["{} {} 1.0 {}\n".format(n1,n2,round(3.8,2))])

top.addProperty(STERIC_INTERACTION.format(maxSigma*cutOffFactor),stericInfo)

for nc in top.propertiesLoaded["SOP_NATIVE_CONTACT"]:
    nc[2]=nc[2].replace("INTRA",str(INTRA_ENERGY))
    nc[2]=nc[2].replace("INTER",str(INTER_ENERGY))

toRenameModels = []
for p in top.propertiesLoaded.keys():
    if p in MODELS.keys():
        toRenameModels.append(p)

for p in toRenameModels:
    top.renamePropertyLoaded(p,MODELS[p])

top.write(OUT)

