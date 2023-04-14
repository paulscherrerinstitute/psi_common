<img align="right" src="../psi_logo.png">

***

[**component list**](../README.md)

# psi_common_pulse_cc
 - VHDL source: [psi_common_pulse_cc](../../hdl/psi_common_pulse_cc.vhd)
 - Testbench source: N.A

### Description

This component implements a clock crossing for transferring single pulses from one clock domain to another (completely asynchronous clocks).

The entity shall only be used for single-cycle pulses and the pulse frequency must be lower than the frequency of the slower clock for it to work correctly.

The entity does only guarantee that all pulses arrive at the destination clock domain. It does not guarantee that pulses that occur in the same clock cycle on the source clock domain, occur on the target clock domain in the same clock cycle. As a result it should only be used to do
clock-crossings for individual pulses.

This entity does also do the clock-crossing for the reset by using "asynchronously assert, synchronously de-assert" synchronizer chains and applying all attributes to synthesize them correctly.


### Generics
| Name         | type      | Description   |
|:-------------|:----------|:--------------|
| num_pulses_g | positive  | N.A           |
| a_rst_pol_g  | std_logic | N.A           |
| b_rst_pol_g  | std_logic | N.A           |

### Interfaces
| Name    | In/Out   | Length       | Description   |
|:--------|:---------|:-------------|:--------------|
| a_clk_i | i        | 1            | Clock A           |
| a_rst_i | i        | 1            | Clock domain A reset input           |
| a_rst_o | o        | 1            |  Clock domain A reset output, active if *a_rst_i* or *b_rst_i* is asserted, de-asserted synchronously to *a_clk_i*         |
| a_dat_i | i        | num_pulses_g | input          		|
| b_clk_i | i        | 1            | Clock B         	|
| b_rst_i | i        | 1            | Clock domain B reset input        |
| b_rst_o | o        | 1            | Clock domain B reset output, active if *a_rst_i* or *b_rst_i* is asserted, de-asserted synchronously to *b_clk_i*       |
| b_dat_o | o        | num_pulses_g | Output of the pulse signals          |

### Architecture

The figure below shows how the pulses are transferred from one clock domain to the other.

<p align="center"> <img src="psi_common_pulse_cc_fig0.png"> </p>

Since each pulse is handled separately, the pulse alignment may change because of the clock crossing. This is shown in the figure below.

<p align="center"> <img src="psi_common_pulse_cc_fig1.png"> </p>

The figure below shows how the reset signal is transferred from one clock domain to the other. This concept is used to transfer resets in both directions between the clock domains but for simplicity only one direction is shown in the figure.

<p align="center"> <img src="psi_common_pulse_cc_fig2.png"> </p>

### Constraints

This entity does not require any constraints
[**component list**](../README.md)
