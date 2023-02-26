<img align="right" src="../doc/psi_logo.png">
***

# psi_common_delay
 - VHDL source: [psi_common_delay](C:/Users/stef_b/git/GFA/Libraries/Firmware/VHDL/psi_common/hdl/psi_common_delay.vhd)
 - Testbench source: [psi_common_delay_tb.vhd](../testbench/psi_common_delay_tb/psi_common_delay_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name             | type     | Description                                                                          |
|:-----------------|:---------|:-------------------------------------------------------------------------------------|
| width_g          | positive | vector length                                                                        |
| delay_g          | positive | delay                                                                                |
| resource_g       | string   | auto, srl or bram                                                                    |
| bram_threshold_g | positive | number of delay taps to start using bram from (if resource_g = auto)                 |
| rst_state_g      | boolean  | true = '0' is outputted after reset, '1' after reset the existing state is outputted |
| ram_behavior_g   | string   | "rbw" = read-before-write, "wbr" = write-before-read                                 |

### Interfaces
| Name   | In/Out   | Length   | Description                |
|:-------|:---------|:---------|:---------------------------|
| clk_i  | i        | 1        | $$ type=clk; freq=100e6 $$ |
| rst_i  | i        | 1        | N.A                        |
| dat_i  | i        | width_g  | N.A                        |
| vld_i  | i        | 1        | N.A                        |
| dat_o  | o        | width_g  | N.A                        |