<img align="right" src="../psi_logo.png">

***

# psi_common_tdp_ram

- VHDL source: [psi_common_tdp_ram.vhd](../../hdl/psi_common_tdp_ram_.vhd)
- Testbench: **_not applicable_**

### Description

This component implements a true dual port RAM. It has one write port
and one read port and both ports can be running at different clocks
(completely asynchronous clocks are allowed). The RAM is described in a
way that it utilizes RAM resources (Block-RAM) available in FPGAs with
commonly used tools.

The RAM is a synchronous RAM, so data is available at the read port one
clock cycle after applying the address.

The RAM behavior (read-before-write or write-before-read) can be
selected. This allows efficiently implementing RAMs for different
technologies (some technologies implement one, some the other behavior).

### Generics
Generics                | Description
------------------------|------------
**Depth\_g**						|	Depth of the memory
**Width\_g** 						| Width of the memory
**Behavior\_g** 				| **"RBW"** Read-before-write implementation, **"WBR"** Write-before-read implementation

### Interfaces

Signal                 |Direction  | Width                 | Description
-----------------------|-----------|---------------------- |-----------------------------------
Clk                    | Input     |  1                    |  Clock
ClkA                   | Input     |  1                    |  Port A clock
AddrA                  | Input     |  ceil(log2(Depth\_g)) |  Port A address
WrA                    | Input     |  1                    |  Port A write enable (active high)
DinA                   | Input     |  Width\_g             |  Port A write data
DoutA                  | Output    |  Width\_g             |  Port A read data
ClkB  								 | Input     |  1                    |  Port B clock  
DinB  								 | Input     | Width\_g              |  Port B write data
ClkB                   | Input     |  1                    |  Port B clock  
DoutB                  | Output    |  Width\_g             |  Port B read data
WrB                    | Input     |  1                    |  Port B write enable (active high)

### Constraints

For the RAM to work correctly, signals from one clock domain to the
other must be constrained to have not more delay that one clock cycle of
the faster clock.

Example with a 100 MHz clock (10.0 ns period) and a 33.33 MHz clock (30
ns period) for Vivado:

```tcl
set_max_delay --datapath_only --from <ClkA> -to <ClkB> 10.0
set_max_delay --datapath_only --from <ClkB> -to <ClkA> 10.0
````

***

[Index](../psi_common_index.md) **|** Previous: [Memories > sp ram be](../ch3_memories/ch3_2_sp_ram_be.md) **|** Next: [Memories > tdp ram be](../ch3_memories/ch3_4_tdp_ram_be.md)
