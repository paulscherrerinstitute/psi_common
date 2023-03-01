# ======================================================================
# Libreary refactoring script from version 2.x.x -> 3.x.x
# This script will parse entity declarations from two library versions
# and generate a JSON file which allows for smooth refactoring
# Benoît Stef - WBBA 311
# Radoslaw Rybaniec - WBBA 314
# ======================================================================
import re
import os
from os import listdir
from os.path import isfile, join
from hdlrefactor import entity_declaration_parser

from pathlib import Path

import json

import argparse

# Create command-line argument parser
parser = argparse.ArgumentParser()
# Add positional argument
parser.add_argument('old_library_dir')
parser.add_argument('new_library_dir')
parser.add_argument('json_db_name')
# Parse arguments from terminal
args = parser.parse_args()

old_library_dir = args.old_library_dir
new_library_dir = args.new_library_dir
json_db_name = args.json_db_name


# use default database for psi_common_logic_pkg
database = {"#ALL#": {

        "ZerosVector" : "zeros_vector",
        "OnesVector" : "ones_vector",
        "PartiallyOnesVector" : "partially_ones_vector",
        "ShiftLeft" : "shift_left",
        "ShiftRight" : "shift_right",
        "BinaryToGray" : "binary_to_gray",
        "GrayToBinary" : "gray_to_binary",
        "PpcOr" : "ppc_or",
        "IntToStdLogic" : "int_to_std_logic",
        "ReduceOr" : "reduce_or",
        "ReduceAnd" : "reduce_and",
        "To01X" : "to_01X",
        "InvertBitOrder" : "invert_bit_order",

        "ClockRatioN_g" : "clock_ratio_n_g",
        "ClockRatioD_g" : "clock_ratio_d_g",
        "Ratio_g" : "ratio_g",
        "HandleRdy_g" : "handle_rdy_g",
        "AxiThrottling_g" : "axi_throttling_g",
        "UseMem_g" : "use_mem_g"
        }
}

#ignore those ports
blacklist  = ["rst_pol_g",]

for path in Path(old_library_dir).rglob('*.vhd'):
    path = str(path)
    print("Parsing " + path)
    entity_db = entity_declaration_parser(path)
    for k,v in entity_db.items():
        for b in blacklist:
            v.pop(b, None)
        database[k] = v;

for path in Path(new_library_dir).rglob('*.vhd'):
    path = str(path)
    print("Parsing " + path)
    entity_db = entity_declaration_parser(path)
    for k,v in entity_db.items():
        #for p0,p1 in zip(database[k].keys(), v.values()):
        #print(database[k].keys())
        for b in blacklist:
            v.pop(b, None)
        merge = dict(zip(database[k].keys(), v.values()))
        database[k] = merge;

with open(json_db_name, "w") as f:
    json.dump(database, f, indent=3);



