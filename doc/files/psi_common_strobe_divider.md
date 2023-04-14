<img align="right" src="../psi_logo.png">

***


[**component list**](../README.md)

# psi_common_strobe_divider
 - VHDL source: [psi_common_strobe_divider](../../hdl/psi_common_strobe_divider.vhd)
 - Testbench source: [psi_common_strobe_divider_tb.vhd](../../testbench/psi_common_strobe_divider_tb/psi_common_strobe_divider_tb.vhd)

### Description

This component divides the rate of a strobe signal. Only every N strobe signal is forwarded to the output. If the input is not a single cycle strobe signal, a rising edge detection is done (strobe is detected on the first cycle the input is high).

The division ratio is selectable at runtime.

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


[**component list**](../README.md)
