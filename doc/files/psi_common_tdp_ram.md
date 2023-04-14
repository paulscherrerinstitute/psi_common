<img align="right" src="../psi_logo.png">

***

[**component list**](../README.md)

# psi_common_tdp_ram
 - VHDL source: [psi_common_tdp_ram](../../psi_common/hdl/psi_common_tdp_ram.vhd)
 - Testbench source: N.A

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

| Name       | type     | Description                                          |
|:-----------|:---------|:-----------------------------------------------------|
| depth_g    | positive | mem depth in samples                                 |
| width_g    | positive | data vector width in bits                            |
| behavior_g | string   | "RBW" = read-before-write, "WBR" = write-before-read |

### Interfaces
| Name    | In/Out   | Length   | Description   |
|:--------|:---------|:---------|:--------------|
| a_clk_i    | i    |   1|     port a clock
| a_addr_i   | i    |    log2(depth)  |  port a addr
| a_wr_i     | i    |  1           |  port a write enable acitve high
| a_dat_i    | i    |   width          |  port a data input
| a_dat_o    | o    |    width         |  port a data output               
| b_clk_i    | i    |     1        |  port b clock
| b_addr_i   | i    |     log2(depth)        |  port b addr
| b_wr_i     | i    | 1            |  port b write enable active high                    
| b_dat_i    | i    |  width           |  port b data input
| b_dat_o    | o    |       width      |  port b data output


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

[**component list**](../README.md)
