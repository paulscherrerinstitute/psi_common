<img align="right" src="../doc/psi_logo.png">
***

# psi_common_sync_cc_xn2n
 - VHDL source: [psi_common_sync_cc_xn2n](C:/Users/stef_b/git/GFA/Libraries/Firmware/VHDL/psi_common/hdl/psi_common_sync_cc_xn2n.vhd)
 - Testbench source: [psi_common_sync_cc_xn2n_tb.vhd](../testbench/psi_common_sync_cc_xn2n_tb/psi_common_sync_cc_xn2n_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name            | type      | Description   |
|:----------------|:----------|:--------------|
| generic(width_g | integer   | N.A           |
| in_rst_pol_g    | std_logic | N.A           |
| out_rst_pol_g   | std_logic | N.A           |

### Interfaces
| Name      | In/Out   | Length   | Description                |
|:----------|:---------|:---------|:---------------------------|
| in_clk_i  | i        | 1        | $$ type=clk; freq=200e6 $$ |
| in_rst_i  | i        | 1        | $$ type=rst; clk=inclk $$  |
| vld_i     | i        | 1        | N.A                        |
| in_rdy_o  | o        | 1        | N.A                        |
| dat_i     | i        | width_g  | N.A                        |
| out_clk_i | i        | 1        | $$ type=clk; freq=100e6 $$ |
| vld_o     | o        | 1        | N.A                        |
| dat_o     | o        | width_g  | N.A                        |