<img align="right" src="../psi_logo.png">

***

# psi_common_sdp_ram

- VHDL source: [psi_common_sdp_ram.vhd](../../hdl/psi_common_sdp_ram.vhd)
- Testbench: **_not applicable_**
-
## Description

This component implements a simple dual port RAM. It has one write port
and one read port and both ports are running at the same clock. The RAM
is described in a way that it utilizes RAM resources (Block-RAM and
Distributed-RAM) available in FPGAs with commonly used tools.

The RAM is a synchronous RAM, so data is available at the read port one
clock cycle after applying the address.

The RAM behavior (read-before-write or write-before-read) can be
selected. This allows efficiently implementing RAMs for different
technologies (some technologies implement one, some the other behavior).

## Generics

Generics                | Description
------------------------|---------
**Depth\_g** 						| Depth of the memory
**Width\_g** 						| Width of the memory
**IsAsync\_g** 					| **true** = Memory is asynchronous, *Clk* is used for write, *RdClk* for read. 	**false** = Memory is synchronous, *Clk* is used for read and write
**RamStyle\_g**					| **"auto"** (default) Automatic choice of block- or distributed-RAM, **"distributed"** Use distributed RAM (LUT-RAM), **"block"** Use block RAM
**Behavior\_g** 				| **"RBW"** Read-before-write implementation, **"WBR"** Write-before-read implementation

## Interfaces

  Signal                 |Direction | Width                  |  Description
  -----------------------|----------|:----------------------:|-----------------------------------------------
  Clk                    | Input    |   1                    |  Clock
  RdClk                  | Input    |   1                    |  Read clock (only used if *IsAsync\_g* = true)
  Wr                     | Input    |   1                    |  Write enable (active high)
  WrAddr                 | Input    |   ceil(log2(Depth\_g)) |  Write address
  RdAddr                 | Input    |   ceil(log2(Depth\_g)) |  Read address
  WrData                 | Input    |   Width\_g             |  Write data
  RdData                 | Output   |   Width\_g             |  Read data
  Rd                     | Input    |   1                    |  Read enable (active high)


[Index](../psi_common_index.md) **|** Previous: [Packages](../ch2_packages/ch2_packages.md) **|** Next: [Memories > sdp ram be](../ch3_memories/ch3_2_sp_ram_be.md)
