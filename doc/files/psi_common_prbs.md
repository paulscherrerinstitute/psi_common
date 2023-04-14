<img align="right" src="../psi_logo.png">

***

[**component list**](../README.md)

# psi_common_prbs
 - VHDL source: [psi_common_prbs](../../hdl/psi_common_prbs.vhd)
 - Testbench source: [psi_common_prbs_tb.vhd](../../testbench/psi_common_prbs_tb/psi_common_prbs_tb.vhd)

### Description

This component generates a pseudorandom binary sequence based (PRBS) on a logic feed-back shift register (LFSR) method, considering a data width of 2-bit up to 32-bit, therefore the necessary polynoms (aiming the maximum cycle possible) are stored into a vector at *psi\_common\_prbs\_pkg*.

In order to feed the component with seed it is necessary to activate the reset signal. Seeds with all *zeros* are illegal and will produce a "lock-up" state.

### Generics
| Name            | type      | Description    |
|:----------------|:----------|:---------------|
| width_g 				| natural   | i/o data width |
| rst_pol_g       | std_logic | reset polarity |

### Interfaces
| Name   | In/Out   | Length   | Description   |
|:-------|:---------|:---------|:--------------|
| rst_i  | i        | 1        | input reset   |
| clk_i  | i        | 1        | input clock   |
| vld_i  | i        | 1        | input strobe  
| seed_i | i        | width_g  | input seed    |
| vld_o  | o        | 1        | output strobe |
| dat_o  | o        | width_g  | output data   |


[**component list**](../README.md)
