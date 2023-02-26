<img align="right" src="../doc/psi_logo.png">
***

# psi_common_debouncer
 - VHDL source: [psi_common_debouncer](C:/Users/stef_b/git/GFA/Libraries/Firmware/VHDL/psi_common/hdl/psi_common_debouncer.vhd)
 - Testbench source: [psi_common_debouncer_tb.vhd](../testbench/psi_common_debouncer_tb/psi_common_debouncer_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name               | type      | Description           |
|:-------------------|:----------|:----------------------|
| generic(dbnc_per_g | real      | filter time in sec    |
| freq_clk_g         | real      | clock frequency in hz |
| rst_pol_g          | std_logic | polarity reset        |
| len_g              | positive  | vector input lenght   |
| in_pol_g           | std_logic | active high or low    |
| out_pol_g          | std_logic | active high or low    |
| sync_g             | boolean   | add 2 dff input sync  |

### Interfaces
| Name   | In/Out   | Length   | Description   |
|:-------|:---------|:---------|:--------------|
| clk_i  | i        | 1        | N.A           |
| rst_i  | i        | 1        | N.A           |
| dat_i  | i        | len_g    | N.A           |
| dat_o  | o        | len_g    | N.A           |