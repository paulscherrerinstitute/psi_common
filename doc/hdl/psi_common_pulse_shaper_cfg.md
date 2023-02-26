<img align="right" src="../doc/psi_logo.png">
***

# psi_common_pulse_shaper_cfg
 - VHDL source: [psi_common_pulse_shaper_cfg](C:/Users/stef_b/git/GFA/Libraries/Firmware/VHDL/psi_common/hdl/psi_common_pulse_shaper_cfg.vhd)
 - Testbench source: [psi_common_pulse_shaper_cfg_tb.vhd](../testbench/psi_common_pulse_shaper_cfg_tb/psi_common_pulse_shaper_cfg_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name             | type      | Description                                                                                    |
|:-----------------|:----------|:-----------------------------------------------------------------------------------------------|
| generic(holdin_g | boolean   | hold input pulse to the output                                                                 |
| hold_off_ena_g   | boolean   | hold off capability enable if true, if false stuck to '0' the corresponding input              |
| max_hold_off_g   | natural   | minimum number of clock cycles between input pulses, if pulses arrive faster, they are ignored |
| max_duration_g   | positive  | maximum duratio                                                                                |
| rst_pol_g        | std_logic | polarity reset                                                                                 |

### Interfaces
| Name    | In/Out   | Length           | Description                           |
|:--------|:---------|:-----------------|:--------------------------------------|
| clk_i   | i        | 1                | system clock                          |
| rst_i   | i        | 1                | system reset                          |
| width_i | i        | max_duration_g)  | output pulse duration in clock cycles |
| hold_i  | i        | max_hold_off_g), | N.A                                   |
| dat_i   | i        | 1                | pulse/str/vld input                   |
| dat_o   | o        | 1                | pulse/str/vld input                   |