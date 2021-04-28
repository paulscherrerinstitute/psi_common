#!/usr/bin/python3

import re
import argparse
import os

FILE_DIR = os.path.dirname(os.path.abspath(__file__))

parser = argparse.ArgumentParser()
parser.add_argument("-package", help="package name with type definition", required=True)
parser.add_argument("-datatype", help="data type name", required=True)
parser.add_argument("-postfix", help="postfix of the output entity, defaults to -datatype", required=False)
parser.add_argument("-resetval", help="reset value", required=True)
parser.add_argument("-dir" , help="Output folder", required=False, default=".")
args = parser.parse_args()

package = args.package
data_type = args.datatype
reset_val = args.resetval
path = args.dir

if args.postfix:
    postfix = args.postfix
else:
    postfix = data_type

with open("{}/snippets/psi_common_status_cc_reg_X.vhd".format(FILE_DIR)) as f:
    content = f.read()

content = re.sub("###PACKAGE###", str(package), content)
content = re.sub("###DATA_TYPE###", str(data_type), content)
content = re.sub("###POSTFIX###", str(postfix), content)
content = re.sub("###RESET_VAL###", str(reset_val), content)


with open("{}/psi_common_status_cc_reg_{}.vhd".format(path, postfix), "w+") as f:
    f.write(content)
