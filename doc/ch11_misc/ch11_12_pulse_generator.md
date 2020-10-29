<img align="right" src="../psi_logo.png">

***
# psi_common_pulse_generator

- VHDL source: [psi_common_pulse_generator.vhd](../../hdl/psi_common_pulse_generator.vhd)
- Testbench:  [psi_common_pulse_generator_tb.vhd](../../testbench/psi_common_pulse_generator/psi_common_pulse_generator_tb.vhd)

### Description
This component implements a ramp generator where the user can set the target the level to reach and number the step prior to reach this level. it can from a certain value reach either continue ramping up either ramping down as the figure below shows.

<p align="center"><img src="ch11_12_fig50.png"></p>

### Generics


Generics        | Description
----------------|-------------------------------------------------
**rst\_pol\_g** |reset polarity ('1' or '0')
**width\_g** 		|Width of the data in bits


### Interfaces

Signal  |Direction  |Width   |Description
--------|-----------|--------|---------------------------------
clk_i  			|Input      |1       |Clock
rst_i  			|Input      |1       |Reset
str_i  	    |Input      |1  		 |strobe input
tgt_lvl_i   |Input      | width_g| set the level to reach (usgin)
ramp_inc_i 	|Input 			| width_g| ramp increment
ramp_cmd_i 	|Input 	  	|1 			 | initiate a ramp up or down
init_cmd_i  |Input 		  |1 			 | stop pulse and set output to zero
sts_o  			| output    | 2   	 | status indicator of the internal sequencer   
str_o  			| output    | 1   	 |  strobe Output
puls_o  		| output    | width_g   |  data output

[Index](../psi_common_index.md) **|** Previous: [Misc > trigger digital](../ch11_misc/ch11_10_trigger_digital.md)
