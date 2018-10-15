##############################################################################
#  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
#  Authors: Patric Bucher
##############################################################################

# Close 
quietly quit -sim 

# Compile 
vcom -work work -2002 -explicit -vopt ../../../psi_tb/hdl/psi_tb_txt_util.vhd
vcom -work work -2002 -explicit -vopt ../../hdl/psi_common_tickgenerator.vhd
vcom -work work -2002 -explicit -vopt ./psi_common_tickgenerator_tb.vhd

# Run
vsim -t ps -novopt work.psi_common_tickgenerator_tb
do psi_common_tickgenerator_tb_WAVE.do
run -all
