<img align="right" src="../doc/psi_logo.png">
***

# psi_common_par_tdm
 - VHDL source: [psi_common_par_tdm](C:/Users/stef_b/git/GFA/Libraries/Firmware/VHDL/psi_common/hdl/psi_common_par_tdm.vhd)
 - Testbench source: [psi_common_par_tdm_tb.vhd](../testbench/psi_common_par_tdm_tb/psi_common_par_tdm_tb.vhd)

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
| dat_i  | i        | channel_count_g | N.A                        |
| vld_i  | i        | 1               | N.A                        |
| rdy_o  | o        | 1               | N.A                        |
| dat_o  | o        | channel_width_g | N.A                        |
| vld_o  | o        | 1               | N.A                        |
| last_o | o        | 1               | N.A                        |