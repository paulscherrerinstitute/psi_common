<img align="right" src="../psi_logo.png">

***
# psi_common_prbs

- VHDL source: [psi_common_prbs.vhd](../../hdl/psi_common_prbs.vhd)
- Testbench: [psi_common_prbs_tb.vhd](../../testbench/psi_common_prbs_tb/psi_common_prbs_tb.vhd)

### Description

This component generates a pseudorandom binary sequence based (PRBS) on a 
logic feed-back shift register (LFSR) method, considering a data width of 
2-bit up to 32-bit, therefore the necessary polynoms (aiming the maximum 
cycle possible) are stored into a vector at *psi\_common\_prbs\_pkg*.

In order to feed the component with seed it is necessary to activate the
reset signal. Seeds with all *zeros* are illegal and will prosuce a 
"lock-up" state.


### Polynoms

Bit 	|Taps 		   |	|Bit 	|Taps 		   |	|Bit    |Taps          |	|Bit    |Taps          |
--------|--------------|	|-------|--------------|	|-------|--------------|	|-------|--------------|	
2 		|2, 1 		   |	|12		|12, 6, 4, 1   | 	|22		|22, 21        |	|32		|32, 22, 2, 1  |
3		|3, 2 		   |	|13		|13, 4, 3, 1   | 	|23		|23, 18        |	|-		|			   |
4		|4, 3 		   |	|14		|14, 5, 3, 1   |	|24		|24, 23, 22, 17|	|-		|			   |
5		|5, 3 		   |	|15		|15, 14        |	|25		|25, 22        |	|-		|			   |
6		|6, 5 		   |	|16		|16, 15, 13, 4 |	|26		|26, 6, 2, 1   |	|-		|			   |
7		|7, 6 		   |	|17		|17, 14        |	|27		|27, 5, 2, 1   |	|-		|			   |
8		|8, 6, 5, 4    |	|18		|18, 11        |	|28		|28, 25        |	|-		|			   |
9		|9, 5 		   |	|19		|19, 6, 2, 1   |	|29		|29, 27        |	|-		|			   |
10		|10, 7 		   |	|20		|20, 17        |	|30		|30, 6, 4, 1   |	|-		|			   |
11		|11, 9 		   |	|21		|21, 19        |	|31		|31, 28        |	|-		|			   |	

Note that the established literature describes the outputs of LFSRs as 
Q1 to Qn and **not** Q0 to Qn-1.

### Generics

Generics             | Description
---------------------|-------------------------------------------------------
**width\_g**         |I/O data width
**rst\_pol\_g**      |Reset polariy

### Interfaces

Signal                 |Direction  |Width     |Description
-----------------------|-----------|----------|------------------------------------------------
rst_i                  |Input      |1         |Reset (rst\_pol\_g active)
clk_i                  |Input      |1         |Clock
str_i                  |Input      |1         |Input strobe, controls the registers chip enables
seed_i                 |Input      |Width\_g  |Data input
data_o                 |Output     |Width\_g  |Data output


[Index](../psi_common_index.md) **|** 
