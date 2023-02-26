<img align="right" src="../doc/psi_logo.png">
***

# psi_common_watchdog
 - VHDL source: [psi_common_watchdog](C:/Users/stef_b/git/GFA/Libraries/Firmware/VHDL/psi_common/hdl/psi_common_watchdog.vhd)
 - Testbench source: [psi_common_watchdog_tb.vhd](../testbench/psi_common_watchdog_tb/psi_common_watchdog_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name               | type      | Description                     |
|:-------------------|:----------|:--------------------------------|
| generic(freq_clk_g | real      | clock frequency in hz           |
| freq_act_g         | real      | event frequency in hz           |
| thld_fault_total_g | positive  | threshold for total errors      |
| thld_warn_g        | positive  | threshold for warning           |
| thld_fault_succ_g  | integer   | threshold for successive errors |
| length_g           | integer   | data input length               |
| rst_pol_g          | std_logic | polarity reset                  |

### Interfaces
| Name    | In/Out   | Length              | Description     |
|:--------|:---------|:--------------------|:----------------|
| clk_i   | i        | 1                   | clock           |
| rst_i   | i        | 1                   | reset           |
| dat_i   | i        | length_g            | input data      |
| warn_o  | o        | 1                   | warning flag    |
| miss_o  | o        | thld_fault_total_g) | missing counter |
| fault_o | o        | 1                   | fault flag      |