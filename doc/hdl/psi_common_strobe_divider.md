<img align="right" src="../doc/psi_logo.png">
***

# psi_common_strobe_divider
 - VHDL source: [psi_common_strobe_divider](C:/Users/stef_b/git/GFA/Libraries/Firmware/VHDL/psi_common/hdl/psi_common_strobe_divider.vhd)
 - Testbench source: [psi_common_strobe_divider_tb.vhd](../testbench/psi_common_strobe_divider_tb/psi_common_strobe_divider_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name      | type      | Description                               |
|:----------|:----------|:------------------------------------------|
| length_g  | natural   | ratio division bit width $$ constant=4 $$ |
| rst_pol_g | std_logic | reset polarity                            |

### Interfaces
| Name    | In/Out   | Length   | Description                                                 |
|:--------|:---------|:---------|:------------------------------------------------------------|
| clk_i   | i        | 1        | clk in $$ type=clk; freq=100e6; $$                          |
| rst_i   | i        | 1        | synchornous reset $$ type=rst; clk=clk_i; lowactive=true $$ |
| vld_i   | i        | if       | strobe in (if not strobe an edge detection is done)         |
| ratio_i | i        | length_g | parameter ratio for division                                |
| vld_o   | o        | 1        | strobe output                                               |