<img align="right" src="../psi_logo.png">

***

[**component list**](../README.md)

# psi_common_pl_stage
 - VHDL source: [psi_common_pl_stage](../../hdl/psi_common_pl_stage.vhd)
 - Testbench source: [psi_common_pl_stage_tb.vhd](../../testbench/psi_common_pl_stage_tb/psi_common_pl_stage_tb.vhd)

### Description
 This entity implements a pipeline stage with handshaking (AXI-S RDY/VLD). The pipeline stage ensures all signals are registered in both directions (including RDY). This is important to break long logic chains that can occur in the RDY paths because Rdy is often forwarded asynchronously.

### Generics
| Name      | type      | Description                      |
|:----------|:----------|:---------------------------------|
| width_g   | integer   | data vector length          		 |
| use_rdy_g | boolean   | use ready push back signals      |
| rst_pol_g | std_logic | '1' active high, '0' active low  |

### Interfaces

| Name   | In/Out   | Length   | Description                |
|:-------|:---------|:---------|:---------------------------|
| clk_i  | i        | 1        | system clock 							|
| rst_i  | i        | 1        | system reset 							|
| vld_i  | i        | 1        | valid input								|
| rdy_o  | o        | 1        | rdy output - push back 		|
| dat_i  | i        | width_g  | data input 								|
| vld_o  | o        | 1        | valid output 							|
| rdy_i  | i        | 1        | rdy input - push back 			|
| dat_o  | o        | width_g  | data output							  |


[**component list**](../README.md)
