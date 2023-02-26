<img align="right" src="../doc/psi_logo.png">
***

# psi_common_ser_par
 - VHDL source: [psi_common_ser_par](C:/Users/stef_b/git/GFA/Libraries/Firmware/VHDL/psi_common/hdl/psi_common_ser_par.vhd)
 - Testbench source: [psi_common_ser_par_tb.vhd](../testbench/psi_common_ser_par_tb/psi_common_ser_par_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name              | type      | Description      |
|:------------------|:----------|:-----------------|
| generic(rst_pol_g | std_logic | reset polarity   |
| length_g          | natural   | vector width     |
| msb_g             | boolean   | msb first = true |

### Interfaces
| Name   | In/Out   | Length   | Description                   |
|:-------|:---------|:---------|:------------------------------|
| clk_i  | i        | 1        | clock system                  |
| rst_i  | i        | 1        | reset system                  |
| dat_i  | i        | 1        | data in                       |
| ld_i   | i        | 1        | load in                       |
| vld_i  | i        | 1        | valid/strobe                  |
| dat_o  | o        | length_g | data out                      |
| err_o  | o        | 1        | error out when input too fast |
| vld_o  | o        | 1        | valid/strobe                  |