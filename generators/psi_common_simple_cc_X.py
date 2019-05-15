import re
import argparse
import os

FILE_DIR = os.path.dirname(os.path.abspath(__file__))

parser = argparse.ArgumentParser()
parser.add_argument("-postfix", help="name postfix for the generated entity", required=True)
parser.add_argument("-dir" , help="Output folder", required=False, default=".")
parser.add_argument("-ports", nargs="+", help="ports in the form <name>=<width> <name>=<width> ...", required=True)
args = parser.parse_args()


### Startup ###
ports = {}
for port in args.ports:
    info = port.split("=")
    a = str()
    ports[info[0].strip()] = int(info[1].strip())
sumWidth = sum(ports.values())

### Print Ports ###
print("Ports:")
for name, width in sorted(ports.items()):
    print("{:12s}{}".format(name, width))

### Generate File ###
with open("{}/snippets/psi_common_simple_cc_X.vhd".format(FILE_DIR)) as f:
    content = f.read()

content = re.sub("<WIDTH>", str(sumWidth), content)
content = re.sub("<POSTFIX>", args.postfix, content)
data_in = []
data_out = []
data_merge = []
data_unmerge = []
nextIdx = 0
for name, width in sorted(ports.items()):
    data_in.append("\t\t{:16s}: in \tstd_logic_vector({} downto 0);".format(name+"A", width-1))
    data_out.append("\t\t{:16s}: out\tstd_logic_vector({} downto 0);".format(name+"B", width - 1))
    data_merge.append("\tMergedA({} downto {}) <= {};".format(nextIdx+width-1, nextIdx, name+"A"))
    data_unmerge.append("\t{} <= MergedB({} downto {});".format(name+"B", nextIdx+width-1, nextIdx))
    nextIdx += width
content = re.sub("<DATA_IN>", "\n".join(data_in), content)
content = re.sub("<DATA_OUT>", "\n".join(data_out), content)
content = re.sub("<DATA_MERGE>", "\n".join(data_merge), content)
content = re.sub("<DATA_UNMERGE>", "\n".join(data_unmerge), content)

with open("{}/psi_common_simple_cc_{}.vhd".format(args.dir, args.postfix), "w+") as f:
    f.write(content)