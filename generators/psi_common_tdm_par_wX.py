import re
import argparse
import os

FILE_DIR = os.path.dirname(os.path.abspath(__file__))

parser = argparse.ArgumentParser()
parser.add_argument("-width", help="Width of the datapath", required=True, type=int)
parser.add_argument("-dir" , help="Output folder", required=False, default=".")
args = parser.parse_args()

width = args.width
path = args.dir

with open("{}/snippets/psi_common_tdm_par_wX.vhd".format(FILE_DIR)) as f:
    content = f.read()

content = re.sub("<WIDTH>", str(width), content)

with open("{}/psi_common_tdm_par_w{}.vhd".format(path, width), "w+") as f:
    f.write(content)