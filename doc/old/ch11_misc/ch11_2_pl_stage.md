<img align="right" src="../psi_logo.png">

***

# psi_common_pl_stage

- VHDL source: [psi_common_pl_stage.vhd](../../hdl/psi_common_pl_stage.vhd)
- Testbench: [psi_common_pl_stage_tb.vhd](../../testbench/psi_common_pl_stage_tb/psi_common_pl_stage_tb.vhd)


### Description

This component implements a pipeline stage that supports full AXI-S
handshaking (including the handling of back-pressure). The pipeline
breaks any combinatorial paths on all lines (*Rdy, Vld* and *Data*). So
not only the forward signals *Vld* and *Data* are registered but also
*Rdy*. This is important since long combinatorial paths are common to
occur on the *Rdy* signal (it is often handled combinatorial).

Correct handling of the *Rdy* signal requires some additional resources.
Therefore the handling of *Rdy* can be disabled using a generic to
reduce resource usage if back-pressure must not be handled.

### Generics

Generics 			| Description
--------------|-----------------------------
**Width\_g** 	|Width of the data signal
**UseRdy\_g** |**True** Backpressure is handled (*Rdy* is used and pipelined), **False** Backpressure is not handled (*Rdy* is not connected at all in this case)

### Interfaces

Signal                 |Direction  |Width     |Description
-----------------------|-----------|----------|--------------------------
Clk                    |Input      |1         |Clock
Rst                    |Input      |1         |Reset (high active)
InVld                  |Input      |1         |AXI-S handshaking signal
InRdy                  |Output     |1         |AXI-S handshaking signal
InData                 |Input      |Width\_g  |Data input
OutVld                 |Output     |1         |AXI-S handshaking signal
OutRdy                 |Input      |1         |AXI-S handshaking signal
OutData                |Output     |Width\_g  |Data output

***
[Index](../psi_common_index.md) **|** Previous: [Misc > delay](../ch11_misc/ch11_1_delay.md) **|** Next: [Misc > multi pl](../ch11_misc/ch11_3_multi_pl_stage.md)
