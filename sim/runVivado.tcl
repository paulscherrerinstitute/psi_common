##############################################################################
#  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
#  Authors: Oliver Bruendler
##############################################################################

#Load dependencies
source -quiet ../../../TCL/PsiSim/PsiSim.tcl

#Import psi::sim library
namespace import psi::sim::*

#Initialize Simulation (by exact name because vivado has a command called init)
init -vivado

#Configure
source -quiet ./config.tcl

#Run Simulation
puts "------------------------------"
puts "-- Compile"
puts "------------------------------"
compile_files -all -clean
puts "------------------------------"
puts "-- Run"
puts "------------------------------"
run_tb -all
puts "------------------------------"
puts "-- Check"
puts "------------------------------"

run_check_errors "###ERROR###"