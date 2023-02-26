<img align="right" src="../doc/psi_logo.png">
***

# psi_common_find_min_max
 - VHDL source: [psi_common_find_min_max](C:/Users/stef_b/git/GFA/Libraries/Firmware/VHDL/psi_common/hdl/psi_common_find_min_max.vhd)
 - Testbench source: [psi_common_find_min_max_tb.vhd](../testbench/psi_common_find_min_max_tb/psi_common_find_min_max_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name              | type      | Description     |
|:------------------|:----------|:----------------|
| generic(rst_pol_g | std_logic | rst pol select  |
| length_g          | natural   | data lenght     |
| signed_g          | boolean   | signed/unsigned |
| mode_g            | string    | mode select     |

### Interfaces
| Name      | In/Out   | Length   | Description         |
|:----------|:---------|:---------|:--------------------|
| clk_i     | i        | 1        | clock               |
| rst_i     | i        | 1        | sync reset          |
| str_i     | i        | 1        | strobe in           |
| raz_i     | i        | 1        | reset output        |
| dat_i     | i        | length_g | data input          |
| str_o     | o        | 1        | strobe output       |
| dat_o     | o        | length_g | data output         |
| run_dat_o | o        | length_g | data output running |
| run_str_o | o        | 1        | N.A                 |