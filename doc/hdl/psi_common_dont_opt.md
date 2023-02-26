<img align="right" src="../doc/psi_logo.png">
***

# psi_common_dont_opt
 - VHDL source: [psi_common_dont_opt](C:/Users/stef_b/git/GFA/Libraries/Firmware/VHDL/psi_common/hdl/psi_common_dont_opt.vhd)
 - Testbench source: [psi_common_dont_opt_tb.vhd](../testbench/psi_common_dont_opt_tb/psi_common_dont_opt_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name             | type     | Description   |
|:-----------------|:---------|:--------------|
| from_dut_width_g | positive | N.A           |
| to_dut_width_g   | positive | N.A           |

### Interfaces
| Name   | In/Out   | Length           | Description                |
|:-------|:---------|:-----------------|:---------------------------|
| clk_i  | i        | 1                | && type=clk; freq=100e6 && |
| pin_io | i        | 3                | N.A                        |
| dat_o  | o        | to_dut_width_g   | N.A                        |
| dat_i  | i        | from_dut_width_g | N.A                        |