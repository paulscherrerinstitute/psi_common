<img align="right" src="../doc/psi_logo.png">
***

# psi_common_strobe_generator
 - VHDL source: [psi_common_strobe_generator](C:/Users/stef_b/git/GFA/Libraries/Firmware/VHDL/psi_common/hdl/psi_common_strobe_generator.vhd)
 - Testbench source: [psi_common_strobe_generator_tb.vhd](../testbench/psi_common_strobe_generator_tb/psi_common_strobe_generator_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name          | type      | Description                              |
|:--------------|:----------|:-----------------------------------------|
| freq_clock_g  | real      | clock frequency in hz $$ export=true $$  |
| freq_strobe_g | real      | strobe frequency in hz $$ export=true $$ |
| rst_pol_g     | std_logic | reset polarity                           |

### Interfaces
| Name   | In/Out   |   Length | Description                         |
|:-------|:---------|---------:|:------------------------------------|
| clk_i  | i        |        1 | clk in $$ type=clk; freq=253.0e6 $$ |
| rst_i  | i        |        1 | rst sync $$ type=rst; clk=clk_i $$  |
| vld_o  | o        |        1 | output strobe                       |