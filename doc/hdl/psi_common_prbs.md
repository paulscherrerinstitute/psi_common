<img align="right" src="../doc/psi_logo.png">
***

# psi_common_prbs
 - VHDL source: [psi_common_prbs](C:/Users/stef_b/git/GFA/Libraries/Firmware/VHDL/psi_common/hdl/psi_common_prbs.vhd)
 - Testbench source: [psi_common_prbs_tb.vhd](../testbench/psi_common_prbs_tb/psi_common_prbs_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name            | type      | Description    |
|:----------------|:----------|:---------------|
| generic(width_g | natural   | i/o data width |
| rst_pol_g       | std_logic | reset polarity |

### Interfaces
| Name   | In/Out   | Length   | Description   |
|:-------|:---------|:---------|:--------------|
| rst_i  | i        | 1        | input reset   |
| clk_i  | i        | 1        | input clock   |
| strb_i | i        | 1        | input strobe  |
| seed_i | i        | width_g  | input seed    |
| strb_o | o        | 1        | output strobe |
| data_o | o        | width_g  | output data   |