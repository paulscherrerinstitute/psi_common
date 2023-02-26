<img align="right" src="../doc/psi_logo.png">
***

# psi_common_dyn_sft
 - VHDL source: [psi_common_dyn_sft](C:/Users/stef_b/git/GFA/Libraries/Firmware/VHDL/psi_common/hdl/psi_common_dyn_sft.vhd)
 - Testbench source: [psi_common_dyn_sft_tb.vhd](../testbench/psi_common_dyn_sft_tb/psi_common_dyn_sft_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name                | type      | Description                     |
|:--------------------|:----------|:--------------------------------|
| direction_g         | string    | $$ export=true $$ left or right |
| sel_bit_per_stage_g | positive  | $$ export=true $$               |
| max_shift_g         | positive  | $$ constant=20 $$               |
| width_g             | positive  | $$ constant=32 $$               |
| sign_extend_g       | boolean   | $$ export=true $$               |
| rst_pol_g           | std_logic | N.A                             |

### Interfaces
| Name    | In/Out   | Length      | Description                |
|:--------|:---------|:------------|:---------------------------|
| clk_i   | i        | 1           | $$ type=clk; freq=100e6 $$ |
| rst_i   | i        | 1           | $$ type=rst; clk=clk $$    |
| vld_i   | i        | 1           | N.A                        |
| shift_i | i        | max_shift_g | N.A                        |
| dat_i   | i        | width_g     | N.A                        |
| vld_o   | o        | 1           | N.A                        |
| dat_o   | o        | width_g     | N.A                        |