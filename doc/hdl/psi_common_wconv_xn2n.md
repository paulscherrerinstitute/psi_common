<img align="right" src="../doc/psi_logo.png">
***

# psi_common_wconv_xn2n
 - VHDL source: [psi_common_wconv_xn2n](C:/Users/stef_b/git/GFA/Libraries/Firmware/VHDL/psi_common/hdl/psi_common_wconv_xn2n.vhd)
 - Testbench source: [psi_common_wconv_xn2n_tb.vhd](../testbench/psi_common_wconv_xn2n_tb/psi_common_wconv_xn2n_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name        | type     | Description       |
|:------------|:---------|:------------------|
| in_width_g  | natural; | $$ constant=16 $$ |
| out_width_g | natural  | $$ constant=4 $$  |

### Interfaces
| Name   | In/Out   | Length      | Description                |
|:-------|:---------|:------------|:---------------------------|
| clk_i  | i        | 1           | $$ type=clk; freq=100e6 $$ |
| rst_i  | i        | 1           | $$ type=rst; clk=clk $$    |
| vld_i  | i        | 1           | N.A                        |
| rdy_o  | o        | 1           | N.A                        |
| dat_i  | i        | in_width_g  | N.A                        |
| vld_o  | o        | 1           | N.A                        |
| dat_o  | o        | out_width_g | N.A                        |
| last_o | o        | 1           | N.A                        |