# ======================================================================
# Libreary refactoring script from version 2.x.x -> 3.x.x
# Benoît Stef - WBBA 311
# Radoslaw Rybaniec - WBBA 314
# ======================================================================
import re
import os
from os import listdir
from os.path import isfile, join
from hdlrefactor import entity_declaration_parser, entity_declaration_refactor, set_refactor_database, instantiation_refactor, symbol_refactor, tcl_generics_refactor

from pathlib import Path

set_refactor_database("./migration_from_v2_to_v3_db.json")

for path in Path('../../hdl').rglob('*.vhd*'):
    path = str(path)
    print("Refactoring " + path)
    entity_declaration_refactor(path, path)
    instantiation_refactor(path, path)
    symbol_refactor(path, path)
    
for path in Path('../../testbench').rglob('*.vhd*'):
    path = str(path)
    print("Refactoring " + path)
    entity_declaration_refactor(path, path)
    instantiation_refactor(path, path)
    symbol_refactor(path, path)
    

#TCL
path = "../../sim/config.tcl"
print("Refactoring " + path)
tcl_generics_refactor(path,path)

