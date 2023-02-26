<img align="right" src="../doc/psi_logo.png">
***

# psi_common_wconv_n2xn
 - VHDL source: [psi_common_wconv_n2xn](C:/Users/stef_b/git/GFA/Libraries/Firmware/VHDL/psi_common/hdl/psi_common_wconv_n2xn.vhd)
 - Testbench source: [psi_common_wconv_n2xn_tb.vhd](../testbench/psi_common_wconv_n2xn_tb/psi_common_wconv_n2xn_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name        | type      | Description       |
|:------------|:----------|:------------------|
| width_in_g  | natural;  | $$ constant=4 $$  |
| width_out_g | natural;  | $$ constant=16 $$ |
| rst_pol_g   | std_logic | N.A               |

### Interfaces
| Name     | In/Out   | Length      | Description                |
|:---------|:---------|:------------|:---------------------------|
| clk_i    | i        | 1           | $$ type=clk; freq=100e6 $$ |
| rst_i    | i        | 1           | $$ type=rst; clk=clk $$    |
| vld_i    | i        | 1           | N.A                        |
| rdy_in_i | o        | 1           | N.A                        |
| dat_i    | i        | width_in_g  | N.A                        |
| vld_o    | o        | 1           | N.A                        |
| dat_o    | o        | width_out_g | N.A                        |
| last_o   | o        | 1           | N.A                        |
| we_o     | o        | width_out_g | N.A                        |