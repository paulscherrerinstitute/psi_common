# ======================================================================
# Script that generates one MD file table for an entity port of HDL file
# Benoît Stef - @PSI - WBBA/311
# Used for library psi_lib
# Do not work for pkg & testbench only vHDL/RTL file
# ======================================================================
import pandas as pd
import re
import os

# ======================================================================
def hdl2md (file_name_i, path_name_o, psi_lib):
    """Create MD file out of VHDL entity file.
    Keyword arguments:
    file_name_i -- the file to convert
    path_name_o -- the path where to create the Md file
    psi_lib -- if true psi_lib add logo to md file corresponding to PSI LIB structure"""
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
    start_port = re.compile(r'port')
    end_entity = re.compile(r'end')
    start_generic = re.compile(r'generic')
    end_element = re.compile(r'[);]|[*);]]|[*);*]]')


    # ======================================================================
    # Process Parsing file and list creation
    # ======================================================================
    with open(file_name_i) as fh:  # open text file
        lines = [l.strip() for l in fh.readlines()]
        for l in lines:
            exep = 0
            # check start of entity
            if re.match(start_port, l.lower()):
                start = 1
            elif re.match(end_entity, l.lower()):
                start = 0
                break

            if re.match(start_generic, l.lower()):
                gene = 1
            elif (re.match(start_port, l.lower())) and (gene == 1):
                exep = 1
                gene = 0

            # process parsing of generics
            if gene == 1 or exep == 1:
                parts = re.sub('\s+', ' ', l.lower()).split(':')
                # print(parts)
                if len(parts) > 1:
                    if gene == 1:
                        gName.append(parts[0])
                        gType.append(parts[1].split()[0])
                        gCmt = parts[-1].split( '--' )
                        if len(gCmt) == 2:
                            gDesc.append(parts[-1].split('--')[1])
                        else:
                            gDesc.append('N.A')

            # Process parsing of ports
            if start == 1:
                parts = re.sub('\s+', ' ', l.lower()).split(':')
                if len(parts) == 2:
                    ports = parts[0].strip()
                    vector = parts[-1].split('(')

                    # extract port of the file and put into lists
                    if ports:
                        if not(ports[0:2] == "--"):
                            if re.match(r'port',ports):
                                name.append(ports.split('(')[-1])
                            else:
                                name.append(ports)
                            size.append(vector[-1].split(" ")[0])
                            cmt.append(parts[-1].split(';')[-1])
                            direction.append((vector[0].strip()[0]))

                            # description auto
                            if cmt[count]:
                                if len(parts[-1].split('--')) == 2: # re.match(r'[--]',parts[-1]):
                                    desc.append(parts[-1].split('--')[-1])
                                else:
                                    desc.append( "N.A" )
                            else:
                                desc.append("N.A" )
                            count += 1

    # ======================================================================
    # Debug print
    # ======================================================================
    #print(name)
    #print(direction)
    #print(size)
    #print(desc)

    #print(gName)
    #print(gType)
    #print(gVal)
    #print(gDesc)

    # ======================================================================
    # Create dict to feed into pandas Data Frame to write MD file
    # ======================================================================
    for i in range(0, len(size)):
        if not size[i] or size[i] == '0':
            size[i] = '1'

    md_name = os.path.basename(fh.name)
    md_name = md_name.split('.')
    # print(md_name)
    df1 = pd.DataFrame({"Name": gName, "type": gType, "Description": gDesc})
    df1 = df1.set_index('Name')
    df2 = pd.DataFrame({"Name": name, "In/Out": direction, "Length": size, "Description": desc})
    df2 = df2.set_index('Name')

    # ======================================================================
    # Format MD file
    # ======================================================================
    f = open(path_name_o+"/"+md_name[0]+".md", "w+")  # write into file
    if psi_lib:
        f.write('<img align="right" src="../doc/psi_logo.png">')
    f.write('\n')
    f.write('***\n')
    f.write('\n')
    f.write('# '+md_name[0])
    f.write('\n')
    f.write(" - VHDL source: ["+md_name[0]+"]("+file_name_i+")\n")
    if psi_lib:
        f.write(" - Testbench source: ["+md_name[0]+"_tb.vhd](../testbench/"+md_name[0]+"_tb/"+md_name[0]+"_tb.vhd)\n")
    f.write('\n')
    f.write('### Description')
    f.write('\n')
    f.write("*INSERT YOUR TEXT*")
    f.write('\n')
    f.write('\n')
    f.write('### Generics\n')
    f.write(df1.to_markdown())
    f.write('\n')
    f.write('\n')
    f.write('### Interfaces\n')
    f.write(df2.to_markdown())

    f.close()
    return  print("[INFO]: "+md_name[0]+".vhd MD File created")

def hdl2md1():
    print('enter file name path + file to convert:')
    fileName = input()
    print('enter path to paste md file:')
    pathName = input()
    hdl2md(fileName, pathName)
    return
