<img align="right" src="../psi_logo.png">

***
# psi_common_par_tdm_cfg

- VHDL source: [psi_common_par_tdm_cfg.vhd](../../hdl/psi_common_par_tdm_cfg.vhd)
- Testbench: [psi_common_par_tdm_cfg_tb.vhd](../../testbench/psi_common_par_tdm_cfg_tb/psi_common_par_tdm_cfg_tb.vhd)

### Description

This entity is very similar to psi_common_par_tdm. The only differences are:
- psi_common_par_tdm_cfg produces a Last flag on the last word of a TDM packet while
psi_common_par_tdm does not.
- psi_common_par_tdm_cfg allows configuring the number of inputs to serialize at runtime while
psi_common_par_tdm does not.

The N lowest channels (input index N*ChannelWidth_g-1 downto 0) are serialized


### Generics
Generics            | Description
--------------------|-------------------------
**ChannelCount_g**	| Maximum number of channels
**ChannelWidth_g**  | Number of bits per channel

### Interfaces

Signal                 |Direction  |Width                      |Description
-----------------------|-----------|---------------------------|-------------------------------------------------------------
Clk                  |Input      |1                          |Clock
Rst                  |Input      |1                          |Reset
ParallelVld 				 | Input 		 |1													 | AXI-S handshaking signal
Parallel						 | Input 		 | ChannelCount_g*ChannelWidth_g | Data of all channels in parallel. Channel0 is in the lowest bit and played out first.
EnabledChannels | Input |  Integer | Number of channels to parallelize
TdmVld | Output | 1 | AXI-S handshaking signal
TdmLast | Output | 1 | AXI-S TLAST signal, set for the last transfer in a packet
Tdm | Output | ChannelWidth | Data signal output

***
[Index](../psi_common_index.md) **|** Previous: [TDM hanlding > tdm mux](../ch8_tdm_handling/ch8_4_tdm_mux.md) **|** Next: [Arbiters > arb priority](../ch9_arbiters/ch9_1_arb_priority.md)

