<img align="right" src="../doc/psi_logo.png">
***

# psi_common_delay_cfg
 - VHDL source: [psi_common_delay_cfg](C:/Users/stef_b/git/GFA/Libraries/Firmware/VHDL/psi_common/hdl/psi_common_delay_cfg.vhd)
 - Testbench source: [psi_common_delay_cfg_tb.vhd](../testbench/psi_common_delay_cfg_tb/psi_common_delay_cfg_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name            | type      | Description                                              |
|:----------------|:----------|:---------------------------------------------------------|
| generic(width_g | positive  | data vector width                                        |
| max_delay_g     | positive  | maximum delay wanted                                     |
| rst_pol_g       | std_logic | reset polarity                                           |
| ram_behavior_g  | string    | "rbw" = read-before-write, "wbr" = write-before-read     |
| hold_g          | boolean   | holding value at output when delay increase is performed |

### Interfaces
| Name   | In/Out   | Length       | Description               |
|:-------|:---------|:-------------|:--------------------------|
| clk_i  | i        | 1            | system clock              |
| rst_i  | i        | 1            | system reset              |
| dat_i  | i        | width_g      | data input                |
| str_i  | i        | 1            | valid/strobe signal input |
| del_i  | i        | max_delay_g) | delay parameter input     |
| dat_o  | o        | width_g      | data output               |