<img align="right" src="../psi_logo.png">

***
# psi_common_arb_round_robin

- VHDL source: [psi_common_arb_round_robin.vhd](../../hdl/psi_common_arb_round_robin.vhd)
- Testbench: [psi_common_arb_round_robin_tb.vhd](../../testbench/psi_common_arb_round_robin_tb/psi_common_arb_round_robin.vhd)]

### Description

This entity implements a round-robin arbiter. If multiple bits are
asserted in the request vector, the left-most bit is forwarded to the
grant vector first. Next, the second left-most bit that is set is
forwarded etc. Whenever at least one bit in the *Grant* vector is
asserted, the *Grant\_Vld* handshaking signal is asserted to signal that
a request was granted. The consumer of the *Grant* vector signalizes
that the granted access was executed by pulling *Grant\_Rdy* high.

Note that the round-robin arbiter is implemented without an output
register. Therefore combinatorial paths between input and output exist
and it is recommended to add a register-stage to the output as early as
possible.

<p align="center"><img src="ch9_2_fig22.png"></p>

Especially interesting is the part in orange. At this point the arbiter
does not grant access to bit 3 because it already granted this request
in the clock cycle before. However, it continues to grant access to the
highest-priority (i.e. left-most) bit of the request vector that is
still left of the bit set in the last *Grant* output. If the request
vector asserts a higher priority this change is directly forwarded to
the output. This is shown in the orange section of the waveform.

### Generics

generics		| Description
------------|---------------------------------------------------
**Size\_g** |Size of the arbiter (number of input/output bits)

### Interfaces

Signal              | Direction | Width     | Description         
--------------------|-----------|-----------|---------------------
Clk                 | Input     | 1         | Clock               
Rst                 | Input     | 1         | Reset (high active)
Request             | Input     | *Size\_g* | Request input signals, The highest(left-most) bit has highest priority    
Grant               | Output    | *Size\_g* | Grant output signal
Grant\_Vld          | Outpu     | 1         | AXI-S handshaking signal, Asserted whenever Grant != 0   
Grant\_Rdy          | Input     | 1         | AXI-S handshaking signal The state of the  arbiter is updated  upon *Grant\_Rdy =   '1'*

***
[Index](../psi_common_index.md) **|** Previous: [Arbiters > arb priority](../ch9_arbiters/ch9_1_arb_priority.md) **|** Next: [Interfaces > spi master](../ch10_interfaces/ch10_1_spi_master.md)
