<img align="right" src="../psi_logo.png">

***
# psi_common_multi_pl_stage

- VHDL source: [psi_common_multi_pl_stage.vhd](../../hdl/psi_common_multi_pl_stage.vhd)
- Testbench: [psi_common_multi_pl_stage_tb.vhd](../../testbench/psi_common_multi_pl_stage_tb/psi_common_multi_pl_stage_tb.vhd)

### Description

This component implements allows easily adding multiple pipeline stages
to a signal path and maintain full AXI-S handshaking including
back-pressure. It does so by chaining multiple *psi\_common\_pl\_stage*
(see 11.2) entities.

### Generics

Generics			| Description
--------------|----------------------
**Width\_g** 	|Width of the data signal\
**UseRdy\_g** | **True** Backpressure is handled (*Rdy* is used and pipelined), **False** Backpressure is not handled (*Rdy* is not connected at all in this case)
**Stages\_g** | Number of pipeline stages

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
[Index](../psi_common_index.md) **|** Previous: [Misc > pl stage](../ch11_misc/ch11_2_pl_stage.md) **|** Next: [Misc > ping pong](../ch11_misc/ch11_4_ping_pong.md)
