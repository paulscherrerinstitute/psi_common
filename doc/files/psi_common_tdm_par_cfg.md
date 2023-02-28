<img align="right" src="../psi_logo.png">

***

[**component list**](../README.md)

# psi_common_tdm_par_cfg
 - VHDL source: [psi_common_tdm_par_cfg](../../hdl/psi_common_tdm_par_cfg.vhd)
 - Testbench source: [psi_common_tdm_par_cfg_tb.vhd](../../testbench/psi_common_tdm_par_cfg_tb/psi_common_tdm_par_cfg_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name            | type      | Description      |
|:----------------|:----------|:-----------------|
| channel_count_g | natural   | $$ constant=3 $$ |
| channel_width_g | natural   | $$ constant=8 $$ |
| rst_pol_g       | std_logic | N.A              |

### Interfaces
| Name   | In/Out   | Length          | Description                |
|:-------|:---------|:----------------|:---------------------------|
| clk_i  | i        | 1               | $$ type=clk; freq=100e6 $$ |
| rst_i  | i        | 1               | $$ type=rst; clk=clk $$    |
| dat_i  | i        | channel_width_g | N.A                        |
| vld_i  | i        | 1               | N.A                        |
| last_i | i        | 1               | N.A                        |
| dat_o  | o        | channel_count_g | N.A                        |
| vld_o  | o        | 1               | N.A                        |


[**component list**](../README.md)
