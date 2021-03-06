##############################################################################
#  Copyright (c) 2018-2020 by Paul Scherrer Institute, Switzerland
#  Copyright (c) 2020 by Enclustra GmbH, Switzerland
#  All rights reserved.
#  Authors: Oliver Bruendler, Benoit Stef
##############################################################################

#Constants
set LibPath "../.."

#Import psi::sim library
namespace import psi::sim::*

#Set library
add_library psi_common

#suppress messages
compile_suppress 135,1236,1370
run_suppress 8684,3479,3813,8009,3812

# Library
add_sources $LibPath {
	psi_common/hdl/psi_common_array_pkg.vhd \
	psi_common/hdl/psi_common_math_pkg.vhd \
	psi_common/hdl/psi_common_logic_pkg.vhd \
	psi_tb/hdl/psi_tb_txt_util.vhd \
	psi_tb/hdl/psi_tb_compare_pkg.vhd \
	psi_tb/hdl/psi_tb_activity_pkg.vhd \
	psi_tb/hdl/psi_tb_axi_pkg.vhd \
	psi_tb/hdl/psi_tb_i2c_pkg.vhd \
} -tag lib

# project sources
add_sources "../hdl" {
	psi_common_pulse_cc.vhd \
	psi_common_simple_cc.vhd \
	psi_common_status_cc.vhd \
	psi_common_bit_cc.vhd \
	psi_common_tdp_ram.vhd \
	psi_common_sdp_ram.vhd \
	psi_common_sync_fifo.vhd \
	psi_common_async_fifo.vhd \
	psi_common_tickgenerator.vhd \
	psi_common_strobe_generator.vhd \
	psi_common_strobe_divider.vhd \
	psi_common_delay.vhd \
	psi_common_wconv_n2xn.vhd \
	psi_common_wconv_xn2n.vhd \
	psi_common_sync_cc_n2xn.vhd \
	psi_common_sync_cc_xn2n.vhd \
	psi_common_pl_stage.vhd \
	psi_common_multi_pl_stage.vhd \
	psi_common_par_tdm.vhd \
	psi_common_tdm_par.vhd \
	psi_common_tdm_par_cfg.vhd \
	psi_common_arb_priority.vhd \
	psi_common_arb_round_robin.vhd \
	psi_common_tdm_mux.vhd \
	psi_common_pulse_shaper.vhd \
	psi_common_clk_meas.vhd \
	psi_common_spi_master.vhd \
	psi_common_axi_master_simple.vhd \
	psi_common_axi_master_full.vhd \
	psi_common_axi_slave_ipif.vhd \
	psi_common_axi_slave_ipif64.vhd \
	psi_common_tdp_ram_be.vhd \
	psi_common_i2c_master.vhd \
	psi_common_ping_pong.vhd \
	psi_common_delay_cfg.vhd \
	psi_common_pulse_shaper_cfg.vhd \
	psi_common_watchdog.vhd \
	psi_common_dont_opt.vhd \
	psi_common_axi_multi_pl_stage.vhd \
	psi_common_par_tdm_cfg.vhd \
	psi_common_axilite_slave_ipif.vhd \
	psi_common_watchdog.vhd \
	psi_common_debouncer.vhd \
  psi_common_trigger_analog.vhd \
	psi_common_trigger_digital.vhd \
  psi_common_dyn_sft.vhd \
  psi_common_ramp_gene.vhd \
  psi_common_pulse_generator_ctrl_static.vhd \
  psi_common_par_ser.vhd \
  psi_common_ser_par.vhd \
  psi_common_spi_master_cfg.vhd \
  psi_common_find_min_max.vhd \
  psi_common_min_max_mean.vhd \
} -tag src

# testbenches
add_sources "../testbench" {
	psi_common_simple_cc_tb/psi_common_simple_cc_tb.vhd \
	psi_common_status_cc_tb/psi_common_status_cc_tb.vhd \
	psi_common_sync_fifo_tb/psi_common_sync_fifo_tb.vhd \
	psi_common_async_fifo_tb/psi_common_async_fifo_tb.vhd \
	psi_common_logic_pkg_tb/psi_common_logic_pkg_tb.vhd \
	psi_common_tickgenerator_tb/psi_common_tickgenerator_tb.vhd \
	psi_common_strobe_generator_tb/psi_common_strobe_generator_tb.vhd \
	psi_common_strobe_divider_tb/psi_common_strobe_divider_tb.vhd \
	psi_common_delay_tb/psi_common_delay_tb.vhd \
	psi_common_wconv_n2xn_tb/psi_common_wconv_n2xn_tb.vhd \
	psi_common_wconv_xn2n_tb/psi_common_wconv_xn2n_tb.vhd \
	psi_common_sync_cc_n2xn_tb/psi_common_sync_cc_n2xn_tb.vhd \
	psi_common_sync_cc_xn2n_tb/psi_common_sync_cc_xn2n_tb.vhd \
	psi_common_pl_stage_tb/psi_common_pl_stage_tb.vhd \
	psi_common_multi_pl_stage_tb/psi_common_multi_pl_stage_tb.vhd \
	psi_common_par_tdm_tb/psi_common_par_tdm_tb.vhd \
	psi_common_tdm_par_tb/psi_common_tdm_par_tb.vhd \
	psi_common_tdm_par_cfg_tb/psi_common_tdm_par_cfg_tb.vhd \
	psi_common_arb_priority_tb/psi_common_arb_priority_tb.vhd \
	psi_common_arb_round_robin_tb/psi_common_arb_round_robin_tb.vhd \
	psi_common_tdm_mux_tb/psi_common_tdm_mux_tb.vhd \
	psi_common_pulse_shaper_tb/psi_common_pulse_shaper_tb.vhd \
	psi_common_clk_meas_tb/psi_common_clk_meas_tb.vhd \
	psi_common_spi_master_tb/psi_common_spi_master_tb.vhd \
	psi_common_axi_master_simple_tb/psi_common_axi_master_simple_tb_pkg.vhd \
	psi_common_axi_master_simple_tb/psi_common_axi_master_simple_tb_case_simple_tf.vhd \
	psi_common_axi_master_simple_tb/psi_common_axi_master_simple_tb_case_axi_hs.vhd \
	psi_common_axi_master_simple_tb/psi_common_axi_master_simple_tb_case_split.vhd \
	psi_common_axi_master_simple_tb/psi_common_axi_master_simple_tb_case_max_transact.vhd \
	psi_common_axi_master_simple_tb/psi_common_axi_master_simple_tb_case_special.vhd \
	psi_common_axi_master_simple_tb/psi_common_axi_master_simple_tb_case_internals.vhd \
	psi_common_axi_master_simple_tb/psi_common_axi_master_simple_tb.vhd \
	psi_common_axi_master_full_tb/psi_common_axi_master_full_tb_pkg.vhd \
	psi_common_axi_master_full_tb/psi_common_axi_master_full_tb_case_simple_tf.vhd \
	psi_common_axi_master_full_tb/psi_common_axi_master_full_tb_case_axi_hs.vhd \
	psi_common_axi_master_full_tb/psi_common_axi_master_full_tb_case_user_hs.vhd \
	psi_common_axi_master_full_tb/psi_common_axi_master_full_tb_case_large.vhd \
	psi_common_axi_master_full_tb/psi_common_axi_master_full_tb.vhd \
	psi_common_axi_slave_ipif_tb/psi_common_axi_slave_ipif_tb.vhd \
	psi_common_axi_slave_ipif64_tb/psi_common_axi_slave_ipif64_tb.vhd \
	psi_common_axi_slave_ipif64_tb/psi_common_axi_slave_ipif64_sram_tb.vhd \
	psi_common_tdp_ram_be_tb/psi_common_tdp_ram_be_tb.vhd \
	psi_common_i2c_master_tb/psi_common_i2c_master_tb.vhd \
	psi_common_ping_pong_tb/psi_common_ping_pong_tb.vhd \
	psi_common_ping_pong_tb/psi_common_ping_pong_tdm_burst_tb.vhd \
	psi_common_delay_cfg_tb/psi_common_delay_cfg_tb.vhd \
	psi_common_pulse_shaper_cfg_tb/psi_common_pulse_shaper_cfg_tb.vhd \
	psi_common_watchdog_tb/psi_common_watchdog_tb.vhd \
	psi_common_axi_multi_pl_stage_tb/psi_common_axi_multi_pl_stage_tb.vhd \
	psi_common_par_tdm_cfg_tb/psi_common_par_tdm_cfg_tb.vhd \
  psi_common_debouncer_tb/psi_common_debouncer_tb.vhd \
  psi_common_trigger_analog_tb/psi_common_trigger_analog_tb.vhd \
	psi_common_trigger_digital_tb/psi_common_trigger_digital_tb.vhd \
	psi_common_axilite_slave_ipif_tb/psi_common_axilite_slave_ipif_tb.vhd \
	psi_common_debouncer_tb/psi_common_debouncer_tb.vhd \
  psi_common_dyn_sft_tb/psi_common_dyn_sft_tb.vhd \
  psi_common_ramp_gene_tb/psi_common_ramp_gene_tb.vhd \
  psi_common_pulse_generator_ctrl_static_tb/psi_common_pulse_generator_ctrl_static_tb.vhd \
  psi_common_par_ser_tb/psi_common_par_ser_tb.vhd \
  psi_common_ser_par_tb/psi_common_ser_par_tb.vhd \
  psi_common_spi_master_cfg_tb/psi_common_spi_master_cfg_tb.vhd \
  psi_common_find_min_max_tb/psi_common_find_min_max_tb.vhd \
  psi_common_min_max_mean_tb/psi_common_min_max_mean_tb.vhd \
} -tag tb

#TB Runs
create_tb_run "psi_common_min_max_mean_tb"
tb_run_add_arguments \
  "-gclock_cycle_g=100 -gsigned_data_g=true -gdata_length_g=16 -gaccu_length_g=64" \
  "-gclock_cycle_g=10 -gsigned_data_g=false -gdata_length_g=8 -gaccu_length_g=16" \
  "-gclock_cycle_g=10 -gsigned_data_g=true -gdata_length_g=24 -gaccu_length_g=48" \
  "-gclock_cycle_g=10 -gsigned_data_g=false -gdata_length_g=32 -gaccu_length_g=40"
add_tb_run

create_tb_run "psi_common_find_min_max_tb"
tb_run_add_arguments \
  "-glength_g=16 -gsigned_g=true -gmode_g=MIN -gdisplay_g=false" \
  "-glength_g=16 -gsigned_g=false -gmode_g=MIN -gdisplay_g=false" \
  "-glength_g=16 -gsigned_g=true -gmode_g=MAX -gdisplay_g=false" \
  "-glength_g=16 -gsigned_g=false -gmode_g=MAX -gdisplay_g=false"
add_tb_run

create_tb_run "psi_common_spi_master_cfg_tb"
tb_run_add_arguments \
	"-gSpiCPOL_g=0 -gSpiCPHA_g=0 -gLsbFirst_g=false -gMaxTransWidth_g=8" \
	"-gSpiCPOL_g=0 -gSpiCPHA_g=1 -gLsbFirst_g=false -gMaxTransWidth_g=16" \
	"-gSpiCPOL_g=1 -gSpiCPHA_g=0 -gLsbFirst_g=false -gMaxTransWidth_g=24" \
	"-gSpiCPOL_g=1 -gSpiCPHA_g=1 -gLsbFirst_g=false -gMaxTransWidth_g=8" \
	"-gSpiCPOL_g=0 -gSpiCPHA_g=0 -gLsbFirst_g=true -gMaxTransWidth_g=8" \
	"-gSpiCPOL_g=0 -gSpiCPHA_g=1 -gLsbFirst_g=true -gMaxTransWidth_g=8"
add_tb_run

create_tb_run "psi_common_pulse_generator_ctrl_static_tb"
tb_run_add_arguments \
	"-glength_g=16 -gfreq_clk_g=100e6 -gstr_freq_g=12e6 -gstep_dw_g=5 -gstep_up_g=10 -gstep_fll_g=50 -gstep_flh_g=60"\
	"-glength_g=16 -gfreq_clk_g=100e6 -gstr_freq_g=1e6  -gstep_dw_g=17 -gstep_up_g=29 -gstep_fll_g=301 -gstep_flh_g=400"\
  "-glength_g=16 -gfreq_clk_g=100e6 -gstr_freq_g=10e6 -gstep_dw_g=129 -gstep_up_g=738 -gstep_fll_g=12302 -gstep_flh_g=8789"
add_tb_run

create_tb_run "psi_common_ramp_gene_tb"
add_tb_run

create_tb_run "psi_common_par_ser_tb"
tb_run_add_arguments \
  "-glength_g=8 -gmsb_g=true -gratio_g=4"\
  "-glength_g=16 -gmsb_g=false -gratio_g=1"\
  "-glength_g=32 -gmsb_g=true -gratio_g=5"
add_tb_run

create_tb_run "psi_common_ser_par_tb"
add_tb_run

create_tb_run "psi_common_delay_cfg_tb"
tb_run_add_arguments \
	"-gMaxDelay_g=50" \
	"-gMaxDelay_g=100"
add_tb_run

create_tb_run "psi_common_pulse_shaper_cfg_tb"
tb_run_add_arguments \
	"-gHoldOffEna_g=false -gMaxDuration_g=24" \
	"-gHoldOffEna_g=true -gMaxDuration_g=16"
add_tb_run

create_tb_run "psi_common_simple_cc_tb"
tb_run_add_arguments \
	"-gClockRatioN_g=3 -gClockRatioD_g=1" \
	"-gClockRatioN_g=101 -gClockRatioD_g=100" \
	"-gClockRatioN_g=99 -gClockRatioD_g=100" \
	"-gClockRatioN_g=3 -gClockRatioD_g=10"
add_tb_run

create_tb_run "psi_common_status_cc_tb"
tb_run_add_arguments \
	"-gClockRatioN_g=3 -gClockRatioD_g=1" \
	"-gClockRatioN_g=101 -gClockRatioD_g=100" \
	"-gClockRatioN_g=99 -gClockRatioD_g=100" \
	"-gClockRatioN_g=3 -gClockRatioD_g=10"
add_tb_run

create_tb_run "psi_common_sync_fifo_tb"
tb_run_add_arguments \
	"-gAlmFullOn_g=true -gAlmEmptyOn_g=true -gDepth_g=32 -gRdyRstState_g=1" \
	"-gAlmFullOn_g=true -gAlmEmptyOn_g=true -gDepth_g=32 -gRdyRstState_g=0" \
	"-gAlmFullOn_g=false -gAlmEmptyOn_g=false -gDepth_g=128 -gRamBehavior_g=RBW" \
	"-gAlmFullOn_g=false -gAlmEmptyOn_g=false -gDepth_g=128 -gRamBehavior_g=WBR"
add_tb_run

create_tb_run "psi_common_async_fifo_tb"
tb_run_add_arguments \
	"-gAlmFullOn_g=true -gAlmEmptyOn_g=true -gDepth_g=32 -gRamBehavior_g=RBW -gRdyRstState_g=1" \
	"-gAlmFullOn_g=true -gAlmEmptyOn_g=true -gDepth_g=32 -gRamBehavior_g=RBW -gRdyRstState_g=0" \
	"-gAlmFullOn_g=false -gAlmEmptyOn_g=false -gDepth_g=128 -gRamBehavior_g=RBW" \
	"-gAlmFullOn_g=false -gAlmEmptyOn_g=false -gDepth_g=128 -gRamBehavior_g=WBR"
add_tb_run

create_tb_run "psi_common_tickgenerator_tb"
tb_run_add_arguments \
	"-gg_CLK_IN_MHZ=125 -gg_TICK_WIDTH=3"
add_tb_run

create_tb_run "psi_common_logic_pkg_tb"
add_tb_run

create_tb_run "psi_common_strobe_generator_tb"
tb_run_add_arguments \
	"-gfreq_clock_g=256300000 -gfreq_strobe_g=1230000" \
	"-gfreq_clock_g=26300000 -gfreq_strobe_g=123000"
add_tb_run

create_tb_run "psi_common_strobe_divider_tb"
tb_run_add_arguments \
	"-gRatio_g=6" \
	"-gRatio_g=13" \
	"-gRatio_g=1" \
	"-gRatio_g=0"
add_tb_run

create_tb_run "psi_common_delay_tb"
tb_run_add_arguments \
	"-gResource_g=BRAM" \
	"-gResource_g=SRL" \
	"-gResource_g=AUTO" \
	"-gResource_g=BRAM -gDelay_g=3 -gRamBehavior_g=RBW" \
	"-gResource_g=BRAM -gDelay_g=3 -gRamBehavior_g=WBR"
add_tb_run

create_tb_run "psi_common_wconv_n2xn_tb"
add_tb_run

create_tb_run "psi_common_wconv_xn2n_tb"
add_tb_run

create_tb_run "psi_common_sync_cc_n2xn_tb"
tb_run_add_arguments \
	"-gRatio_g=2" \
	"-gRatio_g=4"
add_tb_run

create_tb_run "psi_common_sync_cc_xn2n_tb"
tb_run_add_arguments \
	"-gRatio_g=2" \
	"-gRatio_g=4"
add_tb_run

create_tb_run "psi_common_pl_stage_tb"
tb_run_add_arguments \
	"-gHandleRdy_g=true" \
	"-gHandleRdy_g=false"
add_tb_run

create_tb_run "psi_common_multi_pl_stage_tb"
tb_run_add_arguments \
	"-gHandleRdy_g=true" \
	"-gHandleRdy_g=false"
add_tb_run

create_tb_run "psi_common_par_tdm_tb"
add_tb_run

create_tb_run "psi_common_tdm_par_tb"
add_tb_run

create_tb_run "psi_common_tdm_par_cfg_tb"
add_tb_run

create_tb_run "psi_common_arb_priority_tb"
add_tb_run

create_tb_run "psi_common_arb_round_robin_tb"
add_tb_run

create_tb_run "psi_common_tdm_mux_tb"
tb_run_add_arguments \
	"-gstr_del_g=0" \
	"-gstr_del_g=5"
add_tb_run

create_tb_run "psi_common_pulse_shaper_tb"
tb_run_add_arguments \
	"-gHoldIn_g=true" \
	"-gHoldIn_g=false"
add_tb_run

create_tb_run "psi_common_clk_meas_tb"
add_tb_run

create_tb_run "psi_common_spi_master_tb"
tb_run_add_arguments \
	"-gSpiCPOL_g=0 -gSpiCPHA_g=0 -gLsbFirst_g=false" \
	"-gSpiCPOL_g=0 -gSpiCPHA_g=1 -gLsbFirst_g=false" \
	"-gSpiCPOL_g=1 -gSpiCPHA_g=0 -gLsbFirst_g=false" \
	"-gSpiCPOL_g=1 -gSpiCPHA_g=1 -gLsbFirst_g=false" \
	"-gSpiCPOL_g=0 -gSpiCPHA_g=0 -gLsbFirst_g=true" \
	"-gSpiCPOL_g=0 -gSpiCPHA_g=1 -gLsbFirst_g=true"
add_tb_run

create_tb_run "psi_common_ping_pong_tb"
tb_run_add_arguments \
	"-gfreq_data_clk_g=100E6 -gratio_str_g=20 -gfreq_mem_clk_g=120E6 -gch_nb_g=16 -gsample_nb_g=500 -gdat_length_g=16 -gtdm_g=false" \
	"-gfreq_data_clk_g=100E6 -gratio_str_g=2 -gfreq_mem_clk_g=120E6 -gch_nb_g=1 -gsample_nb_g=500 -gdat_length_g=24 -gtdm_g=false" \
	"-gfreq_data_clk_g=100E6 -gratio_str_g=10 -gfreq_mem_clk_g=120E6 -gch_nb_g=4 -gsample_nb_g=6 -gdat_length_g=16 -gtdm_g=true" \
	"-gfreq_data_clk_g=100E6 -gratio_str_g=50 -gfreq_mem_clk_g=120E6 -gch_nb_g=16 -gsample_nb_g=256 -gdat_length_g=16 -gtdm_g=true"
add_tb_run

create_tb_run "psi_common_axi_master_simple_tb"
#Vivado does not support unconstrained records as required by this TB
tb_run_skip Vivado
tb_run_add_arguments \
	"-gImplWrite_g=true -gImplRead_g=true" \
	"-gImplWrite_g=true -gImplRead_g=false" \
	"-gImplWrite_g=false -gImplRead_g=true"
add_tb_run

create_tb_run "psi_common_axi_master_full_tb"
#Vivado does not support unconstrained records as required by this TB
tb_run_skip Vivado
tb_run_add_arguments \
	"-gDataWidth_g=16 -gImplRead_g=true -gImplWrite_g=true" \
	"-gDataWidth_g=32 -gImplRead_g=true -gImplWrite_g=true" \
   "-gDataWidth_g=16 -gImplRead_g=false -gImplWrite_g=true" \
   "-gDataWidth_g=16 -gImplRead_g=true -gImplWrite_g=false"
add_tb_run

create_tb_run "psi_common_axi_slave_ipif_tb"
#Vivado does not support unconstrained records as required by this TB
tb_run_skip Vivado
tb_run_add_arguments \
	"-gNumReg_g=4 -gUseMem_g=true -gAxiThrottling_g=0" \
	"-gNumReg_g=4 -gUseMem_g=true -gAxiThrottling_g=3" \
	"-gNumReg_g=4 -gUseMem_g=false -gAxiThrottling_g=0"
add_tb_run

create_tb_run "psi_common_axi_slave_ipif64_tb"
#Vivado does not support unconstrained records as required by this TB
tb_run_skip Vivado
tb_run_add_arguments \
	"-gUseMem_g=true -gAxiThrottling_g=3" 
add_tb_run

create_tb_run "psi_common_axi_slave_ipif64_sram_tb"
#Vivado does not support unconstrained records as required by this TB
tb_run_skip Vivado
tb_run_add_arguments \
	"-gUseMem_g=true -gAxiThrottling_g=3"
add_tb_run

create_tb_run "psi_common_tdp_ram_be_tb"
add_tb_run

create_tb_run "psi_common_i2c_master_tb"

#Vivado does not support unconstrained records as required by this TB
#a GHDL bug prevents this TB to run in Version 0.36. The bug is reported. Maybe test again in future.
tb_run_skip "Vivado GHDL"
tb_run_add_arguments \
	"-gInternalTriState_g=true" \
	"-gInternalTriState_g=false"
add_tb_run

create_tb_run "psi_common_trigger_analog_tb"
add_tb_run

create_tb_run "psi_common_trigger_digital_tb"
add_tb_run

create_tb_run "psi_common_ping_pong_tdm_burst_tb"
add_tb_run

create_tb_run "psi_common_watchdog_tb"
add_tb_run

create_tb_run "psi_common_axi_multi_pl_stage_tb"
add_tb_run

create_tb_run "psi_common_par_tdm_cfg_tb"
add_tb_run

create_tb_run "psi_common_axilite_slave_ipif_tb"
#Vivado does not support unconstrained records as required by this TB
tb_run_skip Vivado
tb_run_add_arguments \
	"-gNumReg_g=4 -gUseMem_g=true" \
	"-gNumReg_g=4 -gUseMem_g=false"
add_tb_run

create_tb_run "psi_common_debouncer_tb"
add_tb_run

create_tb_run "psi_common_dyn_sft_tb"
tb_run_add_arguments \
	"-gDirection_g=LEFT -gSelectBitsPerStage_g=2 -gSignExtend_g=false" \
  "-gDirection_g=LEFT -gSelectBitsPerStage_g=3 -gSignExtend_g=false" \
  "-gDirection_g=RIGHT -gSelectBitsPerStage_g=2 -gSignExtend_g=false" \
  "-gDirection_g=RIGHT -gSelectBitsPerStage_g=2 -gSignExtend_g=true" \
  "-gDirection_g=LEFT -gSelectBitsPerStage_g=2 -gSignExtend_g=true"
add_tb_run
