<img align="right" src="../psi_logo.png">

***

[**component list**](../README.md)

# psi_common_par_tdm_cfg
 - VHDL source: [psi_common_par_tdm_cfg](../../hdl/psi_common_par_tdm_cfg.vhd)
 - Testbench source: [psi_common_par_tdm_cfg_tb.vhd](../../testbench/psi_common_par_tdm_cfg_tb/psi_common_par_tdm_cfg_tb.vhd)

### Description

This entity is very similar to [psi_common_par_tdm](psi_common_par_tdm.md). The only differences are:
- psi_common_par_tdm_cfg produces a Last flag on the last word of a TDM packet while [psi_common_par_tdm](psi_common_par_tdm.md) does not.
- psi_common_par_tdm_cfg allows configuring the number of inputs to serialize at runtime while [psi_common_par_tdm](psi_common_par_tdm.md) does not.

The N lowest channels (input index N*ChannelWidth_g-1 downto 0) are serialized

### Generics
| Name            | type      | Description      |
|:----------------|:----------|:-----------------|
| ch_count_g | natural   | Maximum number of channels|
| ch_width_g | natural   | Number of bits per channel |
| rst_pol_g       | std_logic |'1' active high, '0' active low              |

### Interfaces
| Name   | In/Out   | Length          | Description                |
|:-------|:---------|:----------------|:---------------------------|
| clk_i  | i        | 1               | system clock |
| rst_i  | i        | 1               | system reset  |
| enabled_ch_i   | i  |  1 |  Number of enabled output channels (starting from index 0)                       |
| dat_i  | i        | ch_count_g | DATA big vector interpreted as // input
| vld_i  | i        | 1               | valid input                      |
| dat_o  | o        | ch_width_g | DATa output in TDM fashion                    |
| last_o | o        | 1               | AXI-S TLAST signal, set for the last transfer in a packet                      |
| vld_o  | o        | 1               |AXI-S handshaking signal                      |

[**component list**](../README.md)
