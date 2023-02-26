<img align="right" src="../doc/psi_logo.png">
***

# psi_common_pl_stage
 - VHDL source: [psi_common_pl_stage](C:/Users/stef_b/git/GFA/Libraries/Firmware/VHDL/psi_common/hdl/psi_common_pl_stage.vhd)
 - Testbench source: [psi_common_pl_stage_tb.vhd](../testbench/psi_common_pl_stage_tb/psi_common_pl_stage_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name      | type      | Description   |
|:----------|:----------|:--------------|
| width_g   | integer   | N.A           |
| use_rdy_g | boolean   | N.A           |
| rst_pol_g | std_logic | N.A           |

### Interfaces
| Name   | In/Out   | Length   | Description                |
|:-------|:---------|:---------|:---------------------------|
| clk_i  | i        | 1        | $$ type=clk; freq=100e6 $$ |
| rst_i  | i        | 1        | $$ type=rst; clk=clk $$    |
| vld_i  | i        | 1        | N.A                        |
| rdy_o  | o        | 1        | N.A                        |
| dat_i  | i        | width_g  | N.A                        |
| vld_o  | o        | 1        | N.A                        |
| dat_o  | o        | width_g  | N.A                        |