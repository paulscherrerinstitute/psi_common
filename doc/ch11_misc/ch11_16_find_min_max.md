<img align="right" src="../psi_logo.png">

***
# psi_common_find_min_max

- VHDL source: [psi_common_find_min_max.vhd](../../hdl/psi_common_find_min_max.vhd)
- Testbench:  [psi_common_find_min_max_tb.vhd](../../testbench/psi_common_find_min_max_tb/psi_common_find_min_max_tb.vhd)

### Description
This component allows finding minimum value or maximum value for a given stream data.
The raz_i signal reset results.


### Generics

Generics        | Description
----------------|------------------------------
**rst\_pol\_g** |reset polarity ('1' or '0')
**length\_g** 	|Width of the data in bits
**signed\_g**   |true=signed   false=unsigned
**mode\_g**	 	  | string "MIN" or "MAX"  


### Interfaces

Signal  |Direction  |Width   |Description
--------|-----------|--------|---------------------------------
clk_i  	|Input      |1       |Clock
rst_i  	|Input      |1       |Reset
data_i  |Input      |length_g|data vector input to serialize
str_i   |Input      |1			 |strobe input
raz_i 	|Input 			|1			 |reset output and results
dat_o 	|Input 	  	|1			 |data output
str_o   |Input 		  |1 			 |strobe output

[Index](../psi_common_index.md) **|** Previous: [Misc > Serial to parallel](../ch11_misc/ch11_15_ser_par.md) **|** Next: [Misc > min max mean](../ch11_misc/ch11_17_min_max_mean.md) 
