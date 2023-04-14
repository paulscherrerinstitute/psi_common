<img align="right" src="../psi_logo.png">

***

[**component list**](../README.md)

# psi_common_find_min_max
 - VHDL source: [psi_common_find_min_max](../../hdl/psi_common_find_min_max.vhd)
 - Testbench source: [psi_common_find_min_max_tb.vhd](../../testbench/psi_common_find_min_max_tb/psi_common_find_min_max_tb.vhd)

### Description
This entity is a sub component of  _psi_common_min_max_mean_ and allow detecting maximum number for

### Generics
| Name              | type      | Description     |
|:------------------|:----------|:----------------|
| generic(rst_pol_g | std_logic | rst pol select  |
| length_g          | natural   | data length     |
| signed_g          | boolean   | signed/unsigned |
| mode_g            | string    | mode select     |

### Interfaces
| Name      | In/Out   | Length   | Description          |
|:----------|:---------|:---------|:---------------------|
| clk_i     | i        | 1        | clock                |
| rst_i     | i        | 1        | sync reset           |
| str_i     | i        | 1        | strobe in            |
| raz_i     | i        | 1        | reset output         |
| dat_i     | i        | length_g | data input           |
| str_o     | o        | 1        | strobe output        |
| dat_o     | o        | length_g | data output          |
| run_dat_o | o        | length_g | data output running  |
| run_str_o | o        | 1        | strobe output running|


[**component list**](../README.md)
