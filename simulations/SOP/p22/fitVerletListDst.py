import os
import numpy as np

for vld in np.linspace(9.5,9.5*2,20):
    with open("options.dat","r+") as f:
        with open("tmp.dat","w") as ft:
            for line in f:
                if("VerletListDst" in line):
                    ft.write("VerletListDst {}\n".format(vld))
                else:
                    ft.write(line)

    os.system("mv tmp.dat options.dat")
    os.system("../../../bin/vsim options.dat 2> log.err")

    with open("log.err","r") as f:
        for line in f:
            if "Mean FPS" in line:
                print(vld,line)

os.system("rm log.err")
