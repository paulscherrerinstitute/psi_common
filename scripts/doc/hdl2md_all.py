# ======================================================================
# Script that generate MD file template for PSI library
# Benoît Stef - WBBA 311
# ======================================================================
import pandas as pd
import re
import os
from os import listdir
from os.path import isfile, join
from hdl2md import hdl2md

print('select path with files to convert:')
path_file = input()
print('select path to copy MD files:')
md_file = input()
print('Is psi_lib ? (true or false):')
psi_lib = input()
# ======================================================================
# Discard pkg from the entire repo
# ======================================================================
c = 0
onlyfiles = [f for f in listdir(path_file) if isfile(join(path_file, f))]
nPop = []
newList = []

for p in range(0, len(onlyfiles)):
    test = onlyfiles[p].split('pkg')
    if len(test) == 2:
        nPop.append(p)
        # print(test)
    else:
        newList.append(onlyfiles[p])

# ======================================================================
# Lists creation loop, file by file
# ======================================================================
i = 0
for i in range (0, len(onlyfiles)):
    hdl2md(path_file + '/' + onlyfiles[i], md_file, psi_lib)

print("---------------------------------------- ")
print("[INFO]: All library succesfully MD filed ")