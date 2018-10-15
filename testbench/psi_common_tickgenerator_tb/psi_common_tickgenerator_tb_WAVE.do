##############################################################################
#  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
#  Authors: Patric Bucher
##############################################################################

onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix decimal -radixshowbase 0 /psi_common_tickgenerator_tb/g_CLK_IN_MHZ
add wave -noupdate /psi_common_tickgenerator_tb/t_CLK
add wave -noupdate -radix decimal -radixshowbase 0 /psi_common_tickgenerator_tb/g_TICK_WIDTH
add wave -noupdate /psi_common_tickgenerator_tb/clock
add wave -noupdate -divider Ticks
add wave -noupdate /psi_common_tickgenerator_tb/tick1us
add wave -noupdate /psi_common_tickgenerator_tb/tick1ms
add wave -noupdate /psi_common_tickgenerator_tb/tick1sec
TreeUpdate [SetDefaultTree]
update
WaveRestoreZoom {0 ns} {10 us}
