<img align="right" src="../psi_logo.png">

***

# psi_common_strobe_generator

- VHDL source: [psi_common_strobe_generator.vhd](../../hdl/psi_common_strobe_generator.vhd)
- Testbench: [psi_common_strobe_generator_tb.vhd](../../testbench/psi_common_strobe_generator_tb/psi_common_strobe_generator_tb.vhd)

### Description

This component generates a strobe (pulse signal with 1 clock cycle pulse-width) at a compile-time configurable frequency. Clock frequency and strobe frequency can be passed as generics.

Optionally the strobe generation can be synchronized to an external signal.

### Generics

Generics            | Description		
--------------------|-----------------------------
**freq\_clock\_g** 	| Frequency of the clock in Hz\
**freq\_strobe\_g** | Frequency of the strobe output in Hz\
**rst\_pol\_g** 		| Reset polarity ('1' = high active)

### Interfaces

Signal  | Direction | Width | Description
--------|-----------|-------|-----------------------------------
InClk   | Input     | 1     | Clock
InRst   | Input     | 1     | Reset input
InSync  | Input     | 1     | Synchronization signal (optional)
OutVld  | Output    | 1     | Strobe output


### Synchronization

The strobe synchronization is optional. If no synchronization is required, *sync\_i* can be left unconnected or tied to '0'.

When strobe synchronization is used, the strobe signal is synchronized to rising edges detected on the *sync\_i* input. If a rising edge is
detected on the *sync\_i* input, a strobe is generated in the next cycle. From there, the strobe is running at the normal frequency.

The figure below shows the behavior of strobe synchronization for a strobe output at ¼ of the clock frequency.

<p align="center">
<img src="ch6_1_fig10.png">
</p>

***
[Index](../psi_common_index.md) **|** Previous: [cdc > bit cc](../ch5_cc/ch5_6_bit_cc.md) **|** Next: [timing > strobe divider](../ch6_timing/ch6_2_strobe_divider.md)
