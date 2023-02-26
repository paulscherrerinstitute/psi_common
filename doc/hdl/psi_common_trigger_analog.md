<img align="right" src="../doc/psi_logo.png">
***

# psi_common_trigger_analog
 - VHDL source: [psi_common_trigger_analog](C:/Users/stef_b/git/GFA/Libraries/Firmware/VHDL/psi_common/hdl/psi_common_trigger_analog.vhd)
 - Testbench source: [psi_common_trigger_analog_tb.vhd](../testbench/psi_common_trigger_analog_tb/psi_common_trigger_analog_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name               | type      | Description                             |
|:-------------------|:----------|:----------------------------------------|
| anl_input_number_g | integer   | number of analog trigger inputs         |
| anl_input_width_g  | integer   | analog trigger input signals width      |
| anl_trg_signed_g   | boolean   | analog trigger input signals are signed |
| rst_pol_g          | std_logic | reset polarity                          |

### Interfaces
| Name               | In/Out   | Length              | Description                                                                                                                                  |
|:-------------------|:---------|:--------------------|:---------------------------------------------------------------------------------------------------------------------------------------------|
| clk_i              | i        | 1                   | clk in $$ type=clk; freq=100.0 $$                                                                                                            |
| rst_i              | i        | 1                   | rst in $$ type=rst; clk=clk_i $$                                                                                                             |
| trg_arm_cfg_i      | i        | 1                   | N.A                                                                                                                                          |
| trg_anlg_src_cfg_i | i        | anl_input_number_g) | trigger source configuration register                                                                                                        |
| anl_th_trig_i      | i        | anl_input_width_g   | analog trigger threshold value                                                                                                               |
| anl_trig_i         | i        | anl_input_number_g  | analog input values                                                                                                                          |
| ext_disarm_i       | i        | 1                   | if different trigger causes are armed at the same time for a single trigger all the other cause must be disarmed once a trigger is generated |
| trg_is_armed_i     | o        | 1                   | N.A                                                                                                                                          |
| trig_o             | o        | 1                   | trigger output                                                                                                                               |