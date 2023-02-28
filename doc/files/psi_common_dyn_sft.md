<img align="right" src="../psi_logo.png">

***

[**component list**](../README.md)

# psi_common_dyn_sft
 - VHDL source: [psi_common_dyn_sft](../../hdl/psi_common_dyn_sft.vhd)
 - Testbench source: [psi_common_dyn_sft_tb.vhd](../../testbench/psi_common_dyn_sft_tb/psi_common_dyn_sft_tb.vhd)

### Description

This entity implements a dynamic shift implemented in multiple stages in order to achieve good timing.

### Generics
| Name                | type      | Description                     |
|:--------------------|:----------|:--------------------------------|
| direction_g         | string    | left or right 									|
| sel_bit_per_stage_g | positive  | shift size 1, 2..n bits         |
| max_shift_g         | positive  | number of maximum shift         |
| width_g             | positive  | length of data input            |
| sign_extend_g       | boolean   | extend sign or not              |
| rst_pol_g           | std_logic | reset polarity                  |

### Interfaces
| Name    | In/Out   | Length      | Description                |
|:--------|:---------|:------------|:---------------------------|
| clk_i   | i        | 1           | system clock								|
| rst_i   | i        | 1           | system reset						    |
| vld_i   | i        | 1           | strobe input               |
| shift_i | i        | max_shift_g | parameter shift             |
| dat_i   | i        | width_g     | data input                 |
| vld_o   | o        | 1           | strobe output              |
| dat_o   | o        | width_g     |data output                 |


[**component list**](../README.md)
