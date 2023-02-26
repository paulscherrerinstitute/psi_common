<img align="right" src="../doc/psi_logo.png">
***

# psi_common_pulse_generator_ctrl_static
 - VHDL source: [psi_common_pulse_generator_ctrl_static](C:/Users/stef_b/git/GFA/Libraries/Firmware/VHDL/psi_common/hdl/psi_common_pulse_generator_ctrl_static.vhd)
 - Testbench source: [psi_common_pulse_generator_ctrl_static_tb.vhd](../testbench/psi_common_pulse_generator_ctrl_static_tb/psi_common_pulse_generator_ctrl_static_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name              | type      | Description                             |
|:------------------|:----------|:----------------------------------------|
| generic(rst_pol_g | std_logic | N.A                                     |
| length_g          | natural   | output data vector length               |
| clk_freq_g        | real      | clock frequency in hz                   |
| str_freq_g        | real      | strobe output || increment strobe in hz |
| nb_step_up_g      | integer   | ramp up param step in str               |
| nb_step_dw_g      | integer   | ramp down param step in str             |
| nb_step_flh_g     | integer   | flat level param step in str            |
| nb_step_fll_g     | integer   | low level param step in str             |

### Interfaces
| Name   | In/Out   | Length     | Description                                          |
|:-------|:---------|:-----------|:-----------------------------------------------------|
| clk_i  | i        | 1          | clock                                                |
| rst_i  | i        | 1          | reset                                                |
| trig_i | i        | 1          | trigger a new pulse                                  |
| stop_i | i        | 1          | abort pulse                                          |
| busy_o | o        | 1          | pulse in action                                      |
| dat_o  | o        | length_g-1 | pulse output                                         |
| str_o  | o        | 1          | pulse strobe                                         |
| dbg_o  | o        | 1          | use for tb purpose and avoid using externalname ghdl |