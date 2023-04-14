# ======================================================================
# Collection of functions for renaming symbols in VHDL files
# Benoît Stef - @PSI - WBBA/311
# Radoslaw Rybaniec - PSI
# ======================================================================
import pandas as pd
import re
import os

import json

DICT = {}

def set_refactor_database(db_file_i, fix_case = True, add_tb = True):
    """Set a database with refactor names"""
    global DICT
    f = open(db_file_i,'r')
    db = json.load(f)
    if fix_case:
        db2 = json.loads(json.dumps(db))
        # make lowercase copy
        for comp_name,comp_dict in db.items():
            for from_name, to_name in comp_dict.items():
                db2[comp_name][from_name.lower()] = to_name
        db = db2
    if add_tb:
        for suffix in ('_tb',):# '_tb_pkg'):
            db2 = json.loads(json.dumps(db))
            for comp_name,comp_dict in db.items():
                db2[comp_name+suffix] = {}
                for from_name, to_name in comp_dict.items():
                    db2[comp_name+suffix][from_name] = to_name
            db = db2
    add_dict = {'psi_common_axi_master_simple_tb_pkg' : 'psi_common_axi_master_simple_tb',
                'psi_common_axi_master_full_tb_pkg' : 'psi_common_axi_master_full_tb',
                'psi_common_axi_master_simple_tb_case_simple_tf' : 'psi_common_axi_master_simple_tb_pkg',
                'psi_common_axi_master_simple_tb_case_axi_hs' : 'psi_common_axi_master_simple_tb_pkg',
                'psi_common_axi_master_simple_tb_case_internals' : 'psi_common_axi_master_simple_tb_pkg',
                'psi_common_axi_master_simple_tb_case_max_transact' : 'psi_common_axi_master_simple_tb_pkg',
                'psi_common_axi_master_simple_tb_case_simple_tf' : 'psi_common_axi_master_simple_tb_pkg',
                'psi_common_axi_master_simple_tb_case_special' : 'psi_common_axi_master_simple_tb_pkg',
                'psi_common_axi_master_simple_tb_case_split' : 'psi_common_axi_master_simple_tb_pkg',
                'psi_common_axi_master_full_tb_case_simple_tf' : 'psi_common_axi_master_full_tb_pkg',
                'psi_common_axi_master_full_tb_case_axi_hs' : 'psi_common_axi_master_full_tb_pkg',
                'psi_common_axi_master_full_tb_case_user_hs' : 'psi_common_axi_master_full_tb_pkg',
                'psi_common_axi_master_full_tb_case_internals' : 'psi_common_axi_master_full_tb_pkg',
                'psi_common_axi_master_full_tb_case_max_transact' : 'psi_common_axi_master_full_tb_pkg',
                'psi_common_axi_master_full_tb_case_full_tf' : 'psi_common_axi_master_full_tb_pkg',
                'psi_common_axi_master_full_tb_case_special' : 'psi_common_axi_master_full_tb_pkg',
                'psi_common_axi_master_full_tb_case_split' : 'psi_common_axi_master_full_tb_pkg',
                'psi_common_axi_master_full_tb_case_large' : 'psi_common_axi_master_full_tb_pkg',
                }


    for k,v in add_dict.items():
        db[k] = db[v]
    DICT = json.loads(json.dumps(db))
    
def conv_fun(comp_name, signal, make_lower_case = False, use_all = False):
    ret = ''
    if DICT == {}:
        raise "Please use set_refactor_database first"
    try:
        if make_lower_case:
            signal_lower_case = signal.lower()
        else:
            signal_lower_case = signal
        ret = DICT[comp_name][signal_lower_case]
    except:
        try:
            if use_all:
                ret = DICT['#ALL#'][signal_lower_case]
            else:
                ret = signal
        except:
            ret = signal
    return ret

# ======================================================================
def instantiation_refactor (file_name_i, file_name_o):
    """Refactor instatnitaions maps from a database
    Keyword arguments:
    file_name_i -- the file to convert
    """
    ports = []
    name = []
    vector = []
    size = []
    desc = []
    cmt = []
    direction = []
    # helpers
    count = 0
    start = 0
    gene = 0
    exep = 0
    # definition for generic processing
    gName = []
    gType = []
    gVal = []
    gDesc = []
    gCmt = []

    # ======================================================================
    # RegExp specific to vhdl - compiled match pattern
    # ======================================================================
    start_instantiation_map = re.compile(r'\s*generic\s+map|\s*port\s+map')
    end_instatiation_map = re.compile(r'\s*\)\s*;')
    component_instantiation = re.compile(r'\s*\w+\s*:\s*entity\s*\w+\.(psi_common_\w+)')
    #instantiation_assignment = re.compile(r'(\s*)(\w+\s*)(\s*=>\s*)(\w+)(.*)', re.DOTALL)
    # version which also includes aaa(1) => bbb,
    #instantiation_assignment = re.compile(r'(\s*)(\w+)(\s*\(.*\))?(\s*=>.*)', re.DOTALL)
    # version which also includes port map(aaa(1) => bbb,
    instantiation_assignment = re.compile(r'(\s*|\s*port\s+map\s*\(s*|\s*generic\s+map\s*\(s*)(\w+)(\s*\(.*\))?(\s*=>.*)', re.DOTALL)
    
    # ======================================================================
    # Process Parsing file and list creation
    # ======================================================================
    out_lines = []
    with open(file_name_i, encoding='latin-1') as fh:  # open text file
            out_lines = []
            lines = [l for l in fh.readlines()]
            comp_name = ''
            for l in lines:
                is_line_modified = False
                splited = l.split('--')
                l = splited[0]
                if len(splited) > 1:
                    comment = ''.join(['--'+splited[i] for i in range(1,len(splited))])
                else:
                    comment = ''
                exep = 0
                if grp := re.match(component_instantiation, l):
                    comp_name = grp[1]
                    print(comp_name)
                # check start of entity
                if re.match(start_instantiation_map, l):
                    start = 1
                elif re.match(end_instatiation_map, l):
                    start = 0
                    #break

                if start == 1:
                    if grp := re.match(instantiation_assignment, l):
                        is_line_modified = True;
                        #l = grp[1]+conv_fun(comp_name,grp[2])+grp.groups('')[3]+grp[4]
                        if grp[3]:
                            l = grp[1]+conv_fun(comp_name,grp[2])+grp[3]+grp[4]
                        else:
                            l = grp[1]+conv_fun(comp_name,grp[2])+grp[4]
                out_lines += l+comment

    with open(file_name_o, 'w') as fo:
        for l in out_lines:
            fo.writelines(l)




def entity_declaration_parser (file_name_i):
    """Create dictionary of all generics and ports for later refactoring
    Keyword arguments:
    file_name_i -- the file to convert
    Returns dictionary with generics and ports for refactoring"""

    RET = {}
    # ======================================================================
    # RegExp specific to vhdl - compiled match pattern
    # ======================================================================
    start_entity_declaration = re.compile(r'\s*entity\s+(\w+)\s+is', re.IGNORECASE)
    end_entity_declaration = re.compile(r'\s*end\s+entity', re.IGNORECASE)
    
    start_port_declaration = re.compile(r'\s+port\s+', re.IGNORECASE)
    start_generic_declaration = re.compile(r'\s+generic\s+', re.IGNORECASE)

    #port_declaration = re.compile(r'\(|\s+(\w+)\s*:', re.IGNORECASE)
    # also include something like port(aa : 
    #port_declaration = re.compile(r'(?:\(}|\s+)(\w+)\s*:', re.IGNORECASE)
    port_declaration = re.compile(r'(\w+)\s*:', re.IGNORECASE)

    
    # ======================================================================
    # Process Parsing file and list creation
    # ======================================================================
    with open(file_name_i, encoding='latin-1') as fh:  # open text file
        out_lines = []
        start = False
        lines = [l for l in fh.readlines()]
        comp_name = ''
        for l in lines:
            is_line_modified = False
            splited = l.split('--')
            l = splited[0]
            exep = 0
            if grp := re.match(start_entity_declaration, l):
                comp_name = grp[1]
                #print(comp_name)
                RET[comp_name] = {}
                start = True
            elif grp := re.match(end_entity_declaration, l):
                start = False

            if start:
                if grp := re.search(port_declaration, l):
                    port_name = grp[1]
                    RET[comp_name][port_name] = port_name
    #print(RET)
    return RET

def entity_declaration_refactor (file_name_i, file_name_o):
    """Create MD file out of VHDL entity file.
    Keyword arguments:
    file_name_i -- the file to convert
    file_name_o -- output file, can be the same as file_name_i
    Returns dictionary with generics and ports for refactoring"""

    # ======================================================================
    # RegExp specific to vhdl - compiled match pattern
    # ======================================================================
    start_entity_declaration = re.compile(r'\s*entity\s+(\w+)\s+is', re.IGNORECASE)
    end_entity_declaration = re.compile(r'\s*end\s+entity', re.IGNORECASE)
    
    start_port_declaration = re.compile(r'\s+port\s+', re.IGNORECASE)
    start_generic_declaration = re.compile(r'\s+generic\s+', re.IGNORECASE)

    port_declaration = re.compile(r'(\s*)(\w+)(\s*:.*)', re.IGNORECASE | re.DOTALL)

    # ======================================================================
    # Process Parsing file and list creation
    # ======================================================================
    out_lines = []
    start = False
    with open(file_name_i, encoding='latin-1') as fh:  # open text file
            out_lines = []
            lines = [l for l in fh.readlines()]
            comp_name = ''
            for l in lines:
                is_line_modified = False
                splited = l.split('--')
                l = splited[0]
                if len(splited) > 1:
                    comment = ''.join(['--'+splited[i] for i in range(1,len(splited))])
                else:
                    comment = ''
                exep = 0
                if grp := re.match(start_entity_declaration, l):
                    comp_name = grp[1]
                    start = True
                elif grp := re.match(end_entity_declaration, l):
                    start = False
                
                if start:
                    if grp := re.match(port_declaration, l):
                        is_line_modified = True;
                        l = grp[1]+conv_fun(comp_name,grp[2])+grp[3]

                out_lines += l+comment

    with open(file_name_o, 'w') as fo:
        for l in out_lines:
            fo.writelines(l)
        
def symbol_refactor(file_name_i, file_name_o):
    """Replace all symbols in the file
    Keyword arguments:
    file_name_i -- the file to convert
    file_name_o -- output file, can be the same as file_name_i
    Returns dictionary with generics and ports for refactoring"""

    # ======================================================================
    # RegExp specific to vhdl - compiled match pattern
    # ======================================================================
    symbol = re.compile(r'[^\w]*(\w+)', re.IGNORECASE | re.DOTALL)
    #symbol_plus = re.compile(r'([^\w]*)(\w+)', re.IGNORECASE | re.DOTALL)
    symbol_plus = re.compile(r'(\w+)', re.IGNORECASE | re.DOTALL)
    start_entity_declaration = re.compile(r'\s*(entity|package)\s+(\w+)\s+is', re.IGNORECASE)
    
    # ======================================================================
    # Process Parsing file and list creation
    # ======================================================================
    out_lines = []
    start = False
    with open(file_name_i, encoding='latin-1') as fh:  # open text file
            out_lines = []
            lines = [l for l in fh.readlines()]
            comp_name = ''
            for l in lines:
                is_line_modified = False
                splited = l.split('--')
                l = splited[0]
                if len(splited) > 1:
                    comment = ''.join(['--'+splited[i] for i in range(1,len(splited))])
                else:
                    comment = ''
                exep = 0
                if grp := re.match(start_entity_declaration, l):
                    comp_name = grp[2]
                #symbols = re.findall(symbol, l)
                #for s in symbols:
                #    re.sub(
                # def ps(m):
                #     print(m.group(1))
                #     return m.group(1)
                l = re.sub(symbol_plus, lambda m: conv_fun(comp_name,m.group(1), True, True), l)
                # if start:
                #     if grp := re.match(port_declaration, l):
                #         is_line_modified = True;
                #         l = grp[1]+conv_fun(comp_name,grp[2])+grp[3]

                out_lines += l+comment

    with open(file_name_o, 'w') as fo:
        for l in out_lines:
            fo.writelines(l)


def tcl_generics_refactor(file_name_i, file_name_o):
    """Replace all generics in the tcl config file
    Keyword arguments:
    file_name_i -- the file to convert
    file_name_o -- output file, can be the same as file_name_i
    Returns dictionary with generics and ports for refactoring"""

    # ======================================================================
    # RegExp specific to vhdl - compiled match pattern
    # ======================================================================
    generic = re.compile(r'(-g)(\w+)', re.IGNORECASE | re.DOTALL)
    start_entity_declaration = re.compile(r'\s*create_tb_run\s*\"(\w+)\"', re.IGNORECASE)
    
    # ======================================================================
    # Process Parsing file and list creation
    # ======================================================================
    out_lines = []
    start = False
    with open(file_name_i, encoding='latin-1') as fh:  # open text file
            out_lines = []
            lines = [l for l in fh.readlines()]
            comp_name = ''
            for l in lines:
                is_line_modified = False
                splited = l.split('#')
                l = splited[0]
                if len(splited) > 1:
                    comment = ''.join(['#'+splited[i] for i in range(1,len(splited))])
                else:
                    comment = ''
                exep = 0
                if grp := re.match(start_entity_declaration, l):
                    comp_name = grp[1]
                l = re.sub(generic, lambda m: m.group(1)+conv_fun(comp_name,m.group(2), True, True), l)

                out_lines += l+comment

    with open(file_name_o, 'w') as fo:
        for l in out_lines:
            fo.writelines(l)
