<img align="right" src="../doc/psi_logo.png">
***

# psi_common_trigger_digital
 - VHDL source: [psi_common_trigger_digital](C:/Users/stef_b/git/GFA/Libraries/Firmware/VHDL/psi_common/hdl/psi_common_trigger_digital.vhd)
 - Testbench source: [psi_common_trigger_digital_tb.vhd](../testbench/psi_common_trigger_digital_tb/psi_common_trigger_digital_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name                   | type      | Description                      |
|:-----------------------|:----------|:---------------------------------|
| digital_input_number_g | integer   | number of digital trigger inputs |
| rst_pol_g              | std_logic | reset polarity                   |

### Interfaces
| Name                     | In/Out   | Length                  | Description                                                                                                                                  |
|:-------------------------|:---------|:------------------------|:---------------------------------------------------------------------------------------------------------------------------------------------|
| clk_i                    | i        | 1                       | clk in $$ type=clk; freq=100.0 $$                                                                                                            |
| rst_i                    | i        | 1                       | rst in $$ type=rst; clk=clk_i $$                                                                                                             |
| trg_arm_cfg_i            | i        | 1                       | N.A                                                                                                                                          |
| trg_digital_source_cfg_i | i        | digital_input_number_g) | trigger source configuration register                                                                                                        |
| digital_trg_i            | i        | digital_input_number_g  | digital trigger input                                                                                                                        |
| ext_disarm_i             | i        | 1                       | if different trigger causes are armed at the same time for a single trigger all the other cause must be disarmed once a trigger is generated |
| trg_is_armed_o           | o        | 1                       | N.A                                                                                                                                          |
| trigger_o                | o        | 1                       | trigger output                                                                                                                               |