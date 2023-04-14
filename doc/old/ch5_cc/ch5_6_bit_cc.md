
<img align="right" src="../psi_logo.png">

***
# psi_common_bit_cc_n2xn

- VHDL source: [psi_common_bit_cc.vhd](../../hdl/psi_common_bit_cc.vhd)
- Testbench: **not applicable**

### Description

This component implements a clock crossing for multiple independent single-bit signals. It contains double-stage synchronizers and sets all the attributes required for proper synthesis.

Note that this clock crossing does not guarantee that all bits arrive in the same clock cycle at the destination clock domain, therefore it can only be used for independent single-bit signals.

### Generics

Generics       | Description
---------------|------------
**NumBits\_g** | Number of data bits to implement the clock crossing for

### Interfaces

Signal        |Direction  |Width       |Description
--------------|-----------|------------|-------------------
BitsA         |Input      |NumBits\_g  |Input signals
ClkB          |Input      |1           |Destination clock
BitsB         |Output     |NumBits\_g  |Output signals

### Constraints

No special constraints are required (only the period of the output clock.

***
[Index](../psi_common_index.md) **|** Previous: [cdc > sync cc xn2n](../ch5_cc/ch5_5_sync_cc_xn2n.md) **|** Next: [timing > strobe generator](../ch6_timing/ch6_1_strobe_generator.md)
