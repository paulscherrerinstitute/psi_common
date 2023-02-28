<img align="right" src="../psi_logo.png">

***

[**component list**](../README.md)

# psi_common_delay
 - VHDL source: [psi_common_delay](../../psi_common/hdl/psi_common_delay.vhd)
 - Testbench source: [psi_common_delay_tb.vhd](../../testbench/psi_common_delay_tb/psi_common_delay_tb.vhd)

### Description

This component is an efficient implementation for delay chains. It uses FPGA memory resources (Block-RAM and distributed RAM resp. SRLs) for implementing the delays (instead of many FFs). The last delay stage is always implemented in FFs to ensure good timing (RAM outputs are usually slow).

One Problem with using RAM resources to implement delays is that they don't have a reset, so the content of the RAM persists after resetting the logic. The *psi\_common\_delay* entity works around this issue by some logic that ensures that any persisting data is replaced by zeros after a reset. The replacement is done at the output of the *psi\_common\_delay*, so no time to overwrite memory cells after a reset is required and the entity is ready to operate on the first clock cycle after the reset.

If the delay is implemented using a RAM, the behavior of the RAM (read-before-write or write-before-read) can be selected to allow efficient implementation independently of the target technology.

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
| clk_i  | i        | 1        | system Clock		  			  	|
| rst_i  | i        | 1        | system reset               |
| dat_i  | i        | width_g  | data output                |
| vld_i  | i        | 1        | valid input                |
| dat_o  | o        | width_g  | data output                |
| vld_o  | o			  | 1        | valid outputs						  |


[**component list**](../README.md)
