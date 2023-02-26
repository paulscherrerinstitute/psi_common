<img align="right" src="../doc/psi_logo.png">
***

# psi_common_min_max_sum
 - VHDL source: [psi_common_min_max_sum](C:/Users/stef_b/git/GFA/Libraries/Firmware/VHDL/psi_common/hdl/psi_common_min_max_sum.vhd)
 - Testbench source: [psi_common_min_max_sum_tb.vhd](../testbench/psi_common_min_max_sum_tb/psi_common_min_max_sum_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name                  | type      | Description                      |
|:----------------------|:----------|:---------------------------------|
| generic(clock_cycle_g | positive  | clock cycle for accumulator time |
| signed_data_g         | boolean   | data signed/unsigned             |
| data_length_g         | natural   | data length                      |
| accu_length_g         | natural   | mean output length               |
| rst_pol_g             | std_logic | polarity reset                   |

### Interfaces
| Name   | In/Out   | Length          | Description               |
|:-------|:---------|:----------------|:--------------------------|
| clk_i  | i        | 1               | clock                     |
| rst_i  | i        | 1               | reset                     |
| str_i  | i        | 1               | input strobe/valid        |
| sync_i | i        | 1               | input to sync measurement |
| dat_i  | i        | data_length_g   | input data                |
| str_o  | o        | 1               | output strobe/valid       |
| min_o  | o        | data_length_g   | output min val            |
| max_o  | o        | data_length_g   | output max val            |
| sum_o  | o        | accu_length_g-1 | output vector sum         |