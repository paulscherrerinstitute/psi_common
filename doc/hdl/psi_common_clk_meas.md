<img align="right" src="../doc/psi_logo.png">
***

# psi_common_clk_meas
 - VHDL source: [psi_common_clk_meas](C:/Users/stef_b/git/GFA/Libraries/Firmware/VHDL/psi_common/hdl/psi_common_clk_meas.vhd)
 - Testbench source: [psi_common_clk_meas_tb.vhd](../testbench/psi_common_clk_meas_tb/psi_common_clk_meas_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name                        | type     | Description          |
|:----------------------------|:---------|:---------------------|
| generic( master_frequency_g | positive | $$ constant=125e6 $$ |
| max_meas_frequency_g        | positive | $$ constant=250e6 $$ |

### Interfaces
| Name           | In/Out   |   Length | Description                   |
|:---------------|:---------|---------:|:------------------------------|
| clk_master_i   | i        |        1 | $$ type=clk; freq=125e6 $$    |
| rst_i          | i        |        1 | $$ type=rst; clk=clkmaster $$ |
| frequency_hz_o | o        |       31 | synchronous to clkmaster      |
| vld_o          | o        |        1 | pulse when frequency is valid |
| clk_test_i     | i        |        1 | $$ type=clk; freq=101.35e6 $$ |