<img align="right" src="../doc/psi_logo.png">
***

# psi_common_tdm_par
 - VHDL source: [psi_common_tdm_par](C:/Users/stef_b/git/GFA/Libraries/Firmware/VHDL/psi_common/hdl/psi_common_tdm_par.vhd)
 - Testbench source: [psi_common_tdm_par_tb.vhd](../testbench/psi_common_tdm_par_tb/psi_common_tdm_par_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name            | type      | Description      |
|:----------------|:----------|:-----------------|
| channel_count_g | natural   | $$ constant=3 $$ |
| channel_width_g | natural   | $$ constant=8 $$ |
| rst_pol_g       | std_logic | N.A              |

### Interfaces
| Name       | In/Out   | Length          | Description                |
|:-----------|:---------|:----------------|:---------------------------|
| clk_i      | i        | 1               | $$ type=clk; freq=100e6 $$ |
| rst_i      | i        | 1               | $$ type=rst; clk=clk $$    |
| dat_i      | i        | channel_width_g | N.A                        |
| vld_i      | i        | 1               | N.A                        |
| rdy_o      | o        | 1               | N.A                        |
| dat_o      | o        | channel_count_g | N.A                        |
| vld_o      | o        | 1               | N.A                        |
| par_keep_o | o        | channel_count_g | N.A                        |
| par_last_o | o        | 1               | N.A                        |