<img align="right" src="../doc/psi_logo.png">

***


[**component list**](../README.md)

# psi_common_sdp_ram
 - VHDL source: [psi_common_sdp_ram](../../hdl/psi_common_sdp_ram.vhd)
 - Testbench source: N.A

### Description


This component implements a simple dual port RAM. It has one write port and one read port and both ports are running at the same clock. The RAM is described in a way that it utilizes RAM resources (Block-RAM and Distributed-RAM) available in FPGAs with commonly used tools.

The RAM is a synchronous RAM, so data is available at the read port one clock cycle after applying the address.

The RAM behavior (read-before-write or write-before-read) can be selected. This allows efficiently implementing RAMs for different technologies (some technologies implement one, some the other behavior).

### Generics
Generics                | Description
------------------------|---------
depth_g									| Depth of the memory
width_g									| Width of the memory
is_async_g 							| **true** = Memory is asynchronous, *Clk* is used for write, *RdClk* for read. 	**false** = Memory is synchronous, *Clk* is used for read and write
ram_style_g							| **"auto"** (default) Automatic choice of block- or distributed-RAM, **"distributed"** Use distributed RAM (LUT-RAM), **"block"** Use block RAM
ram_behavior_g					| **"RBW"** Read-before-write implementation, **"WBR"** Write-before-read implementation

## Interfaces
Signal                 |Direction | Width                  |  Description
-----------------------|----------|:----------------------:|-----------------------------------------------
wr_clk_i               | Input    |   1                    |  Clock
rd_clk_i               | Input    |   1                    |  Read clock (only used if *IsAsync\_g* = true)
wr_i                   | Input    |   1                    |  Write enable (active high)
wr_addr_i              | Input    |   ceil(log2(Depth\_g)) |  Write address
rd_addr_i              | Input    |   ceil(log2(Depth\_g)) |  Read address
wr_dat_i               | Input    |   Width\_g             |  Write data
rd_dat_o               | Output   |   Width\_g             |  Read data
rd_i                   | Input    |   1                    |  Read enable (active high)

[**component list**](../README.md)
