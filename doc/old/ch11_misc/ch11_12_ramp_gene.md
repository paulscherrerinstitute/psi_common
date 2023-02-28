<img align="right" src="../psi_logo.png">

***
# psi_common_pulse_generator

- VHDL source: [psi_common_ramp_gene.vhd](../../hdl/psi_common_ramp_gene.vhd)
- Testbench:  [psi_common_ramp_gene_tb.vhd](../../testbench/psi_common_ramp_gene_tb/psi_common_ramp_gene_tb.vhd)

### Description
This component implements a ramp generator where the user can set the target level to reach and the step number prior to reach this level. It can from a certain value either continue ramping up either ramping down as the figure below shows. The direction is selected with the next value to reach, if current value is higher than previous one then it ramps up and opposite.
Orignally the block handled only unsigned value and now can asapt to signed via generics.

<p align="center"><img src="ch11_12_fig50.png"></p>

### Generics


Generics        | Description
----------------|-------------------------------------------------
**rst\_pol\_g** | reset polarity ('1' or '0')
**width\_g** 		| Width of the data in bits
**is\_sign\_g** | sign = True / unsign = False
**init\_val\_g**| init value integer


### Interfaces

Signal  |Direction  |Width   |Description
--------|-----------|--------|---------------------------------
clk_i  			|Input      |1          |Clock
rst_i  			|Input      |1          |Reset
str_i  	    |Input      |1  		    |strobe input
tgt_lvl_i   |Input      | width_g   | set the level to reach (usign)
ramp_inc_i 	|Input 			| width_g   | ramp increment
ramp_cmd_i 	|Input 	  	|1 			    | initiate a ramp up or down
init_cmd_i  |Input 		  |1 			    | stop pulse and set output to zero
sts_o  			| output    | 2   	    | status indicator of the internal sequencer   
str_o  			| output    | 1   	    |  strobe Output
puls_o  		| output    | width_g   |  data output

[Index](../psi_common_index.md) **|** Previous: [Misc > dynamic shifter](../ch11_misc/ch11_11_dyn_sft.md) **|** Next: [Misc > Pulse generator ctrl static](../ch11_misc/ch11_13_pulse_generator_ctrl_static.md)
