<img align="right" src="../psi_logo.png">

***
# psi_common_dyn_sft

- VHDL source: [psi_common_dyn_sft.vhd](../../hdl/psi_common_dyn_sft.vhd)
- Testbench:  [psi_common_dyn_sft_tb.vhd](../../testbench/psi_common_dyn_sft_tb/psi_common_dyn_sft_tb.vhd)

### Description
This component implements a dynamic shifter (barrel-shifter). The shift operation is distributed over multiple clock cycles to avoid timing issues with large multiplexers.

### Generics


Generics        | Description
----------------|-------------------------------------------------
**Direction\_g**|Direction of the shift, must be "LEFT" or "RIGHT"
**SelectBitsPerStage\_g**|Each pipeline stage shifts by _2^SelectBitsPerStage_g_  bits
**Width\_g** 		|Width of the data in bits
**SignExtend\_g** |For right shifts, the output can be sign extended (arithmetic shift) or not (logical shift). Use _true_ for sign extension

### Interfaces

Signal  |Direction  |Width   |Description
--------|-----------|--------|---------------------------------
Clk  |Input      |1       |Clock
Rst  |Input      |1       |Reset (high active)
InVld  |Input      |1  |AXI-S handshaking signal for input
InShift  |Input     |_ceil(log2(MaxShift_g+1))_  |Number of bits to shift
InData |Input |_Width_g_ |Data Input
OutVld |Output |1 |AXI-S handshaking signal for output
OutData |Output |_Width\_g_ |Data Output

[Index](../psi_common_index.md) **|** Previous: [Misc > trigger digital](../ch11_misc/ch11_10_trigger_digital.md) **|** Next: [Misc > pulse generator](../ch11_misc/ch11_12_pulse_generator.md)
