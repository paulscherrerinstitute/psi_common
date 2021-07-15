<img align="right" src="../psi_logo.png">

***
# psi_common_min_max_mean

- VHDL source: [psi_common_min_max_mean.vhd](../../hdl/psi_common_min_max_mean.vhd)
- Testbench:  [psi_common_min_max_mean_tb.vhd](../../testbench/psi_common_min_max_mean_tb/psi_common_min_max_mean_tb.vhd)

### Description
This component provides for a given time period **clock_cycle_g**, the minimum, the maximum and the accumulator of a single channel data stream. The stream can be synchronized with external input. In order to get average/mean value, output vector sum needs to be divided by the number required data sample; **clock_cycle_g** defines the number of samples.

<p align="center"><img src="ch11_17_fig56.png"> </p>

### Generics

Generics        | Description
----------------------|------------------------------
**rst\_pol\_g** 			| reset polarity ('1' or '0')
**data\_length\_g** 	| Width of the data in bits
**signed\_data\_g**   | true=signed   false=unsigned
**accu_length\_g**	 	| length for vector sum/accumulator output, must be care that output vector is wide enough
**clock_cycle\_g**	 	| number of sample prior to give the data stream results   

### Interfaces

Signal  |Direction  |Width        |Description
--------|-----------|-------------|---------------------------------
clk_i  	|Input      |1            |Clock
rst_i  	|Input      |1            |Reset
data_i  |Input      |data_length_g|data stream input
str_i   |Input      |1			      |strobe input
sync_i 	|Input 			|1			      |synchronize internal counter
str_o   |Input 		  |1 			 			|strobe output
min_o   |Input 		  |data_length_g|min output result
max_o   |Input 		  |data_length_g|max output result
mean_o  |Input 		|accu_length_g|vector sum, accumulator output


[Index](../psi_common_index.md) **|** Previous: [Misc > find min manx](../ch11_misc/ch11_16_find_min_max.md)
