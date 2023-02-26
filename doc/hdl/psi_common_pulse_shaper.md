<img align="right" src="../doc/psi_logo.png">
***

# psi_common_pulse_shaper
 - VHDL source: [psi_common_pulse_shaper](C:/Users/stef_b/git/GFA/Libraries/Firmware/VHDL/psi_common/hdl/psi_common_pulse_shaper.vhd)
 - Testbench source: [psi_common_pulse_shaper_tb.vhd](../testbench/psi_common_pulse_shaper_tb/psi_common_pulse_shaper_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name       | type      | Description                                                                                                      |
|:-----------|:----------|:-----------------------------------------------------------------------------------------------------------------|
| duration_g | positive  | output pulse duration in clock cycles                                                                            |
| hold_in_g  | boolean   | hold input pulse to the output                                                                                   |
| hold_off_g | natural   | minimum number of clock cycles between input pulses, if pulses arrive faster, they are ignored $$ constant=20 $$ |
| rst_pol_g  | std_logic | reset polarity select                                                                                            |

### Interfaces
| Name   | In/Out   |   Length | Description                             |
|:-------|:---------|---------:|:----------------------------------------|
| clk_i  | i        |        1 | system clock $$ type=clk; freq=100e6 $$ |
| rst_i  | i        |        1 | system reset $$ type=rst; clk=clk $$    |
| dat_i  | i        |        1 | data in                                 |
| dat_o  | o        |        1 | data out                                |