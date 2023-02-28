<img align="right" src="../psi_logo.png">

***

[**component list**](../README.md)

# psi_common_multi_pl_stage
 - VHDL source: [psi_common_multi_pl_stage](../../psi_common/hdl/psi_common_multi_pl_stage.vhd)
 - Testbench source: [psi_common_multi_pl_stage_tb.vhd](../../testbench/psi_common_multi_pl_stage_tb/psi_common_multi_pl_stage_tb.vhd)

### Description
 This entity implements multiple pipeline stages with handshaking (AXI-S RDY/VLD). The pipeline stage ensures all signals are registered in both  directions (including RDY). This is important to break long logic chains that can occur in the RDY paths because Rdy is often forwarded asynchronously.

### Generics
| Name      | type      | Description   									 |
|:----------|:----------|:---------------------------------|
| width_g   | positive  | vector length 									 |
| use_rdy_g | boolean   | use ready signal to push back    |
| stages_g  | natural   | number of pipe         					 |
| rst_pol_g | std_logic | '1' active high, '0' active low  |

### Interfaces
| Name     | In/Out   | Length   | Description                |
|:---------|:---------|:---------|:---------------------------|
| clk_i    | i        | 1        | system clock 							|
| rst_i    | i        | 1        | system rst    							|
| vld_i    | i        | 1        | valid input signal         |
| rdy_in_o | o        | 1        | ready signal output        |
| dat_i    | i        | width_g  | data input                 |
| vld_o    | o        | 1        | valid output signal        |
| rdy_out_i| i        | 1        | ready signal input  				|
| dat_o    | o        | width_g  | data output                |


[**component list**](../README.md)
