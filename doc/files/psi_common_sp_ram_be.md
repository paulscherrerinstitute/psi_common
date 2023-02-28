<img align="right" src="../psi_logo.png">

***


[**component list**](../README.md)

# psi_common_sp_ram_be
 - VHDL source: [psi_common_sp_ram_be](../../hdl/psi_common_sp_ram_be.vhd)
 - Testbench source: [psi_common_sp_ram_be_tb.vhd](../../testbench/psi_common_sp_ram_be_tb/psi_common_sp_ram_be_tb.vhd)

### Description

This component implements a single port RAM with byte enables. The RAM
is described in a way that it utilizes RAM resources (Block-RAM and
Distributed-RAM) available in FPGAs with commonly used tools.

The RAM is a synchronous RAM, so data is available at the read port one
clock cycle after applying the address.

The RAM behavior (read-before-write or write-before-read) can be
selected. This allows efficiently implementing RAMs for different
technologies (some technologies implement one, some the other behavior).

### Generics
| Name           | type     | Description                                          |
|:---------------|:---------|:-----------------------------------------------------|
| depth_g        | positive |memory depth in sample                                |
| width_g        | positive | data width in bit                                    |
| ram_behavior_g | string   | "rbw" = read-before-write, "wbr" = write-before-read |

### Interfaces

Signal                 | Direction  | Width                |  Description
-----------------------| -----------|----------------------| --------------------------------------------------
clk_i                  | I          | 1                    |  Clock
addr_i                 | I          | log2(Depth)          |  Access address
be_i                   | I          |1                     |  Byte enables (Be\[0\] corresponds do Din\[7:0\])
wr_i                   | I          | Width\_g/8           |  Write enables (active enable)
dat_i                  | I          | Width\_g             |  Write data
dat_o                  | O          | Width\_g             |  Read data


[**component list**](../README.md)
