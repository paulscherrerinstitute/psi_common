<img align="right" src="../doc/psi_logo.png">
***

# psi_common_pulse_cc
 - VHDL source: [psi_common_pulse_cc](C:/Users/stef_b/git/GFA/Libraries/Firmware/VHDL/psi_common/hdl/psi_common_pulse_cc.vhd)
 - Testbench source: [psi_common_pulse_cc_tb.vhd](../testbench/psi_common_pulse_cc_tb/psi_common_pulse_cc_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name         | type      | Description   |
|:-------------|:----------|:--------------|
| num_pulses_g | positive  | N.A           |
| a_rst_pol_g  | std_logic | N.A           |
| b_rst_pol_g  | std_logic | N.A           |

### Interfaces
| Name    | In/Out   | Length       | Description   |
|:--------|:---------|:-------------|:--------------|
| a_clk_i | i        | 1            | N.A           |
| a_rst_i | i        | 1            | N.A           |
| a_rst_o | o        | 1            | N.A           |
| a_dat_i | i        | num_pulses_g | N.A           |
| b_clk_i | i        | 1            | N.A           |
| b_rst_i | i        | 1            | N.A           |
| b_rst_o | o        | 1            | N.A           |
| b_dat_o | o        | num_pulses_g | N.A           |