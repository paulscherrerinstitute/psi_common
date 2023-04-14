<img align="right" src="../psi_logo.png">

***

[**component list**](../README.md)

# psi_common_clk_meas
 - VHDL source: [psi_common_clk_meas](../../hdl/psi_common_clk_meas.vhd)
 - Testbench source: [psi_common_clk_meas_tb.vhd](../../testbench/psi_common_clk_meas_tb/psi_common_clk_meas_tb.vhd)

### Description

 This entity measures the frequency of a clock under the assumption that the frequency of the main-clock is exactly correct. Generally the system cock comes from PS, the block is useful to verify if other clock are set the correct frequency

### Generics
| Name                        | type     | Description          									|
|:----------------------------|:---------|:---------------------------------------|
| master_frequency_g				  | positive | clock frequency in Hz for system clock |
| max_meas_frequency_g        | positive | clock frequency in Hz for system clock |
| rst_pol_g					          | std_logic| '1' active high, '0' active low				|  

### Interfaces
| Name           | In/Out   |   Length | Description                   |
|:---------------|:---------|---------:|:------------------------------|
| clk_master_i   | i        |        1 | system clock								   |
| rst_i          | i        |        1 | system reset									 |
| frequency_hz_o | o        |       32 | synchronous to clk_master     |
| vld_o          | o        |        1 | pulse when frequency is valid |
| clk_test_i     | i        |        1 | clock to be tested 					 |

[**component list**](../README.md)
