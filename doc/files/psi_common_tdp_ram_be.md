<img align="right" src="../psi_logo.png">

***

[**component list**](../README.md)

# psi_common_tdp_ram_be
 - VHDL source: [psi_common_tdp_ram_be](../../hdl/psi_common_tdp_ram_be.vhd)
 - Testbench source: [psi_common_tdp_ram_be_tb.vhd](../../testbench/psi_common_tdp_ram_be_tb/psi_common_tdp_ram_be_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name       | type     | Description                                          |
|:-----------|:---------|:-----------------------------------------------------|
| depth_g    | positive | N.A                                                  |
| width_g    | positive | N.A                                                  |
| behavior_g | string   | "rbw" = read-before-write, "wbr" = write-before-read |

### Interfaces
| Name    | In/Out   | Length   | Description   |
|:--------|:---------|:---------|:--------------|
| a_dat_o | o        | width_g  | N.A           |
| b_dat_o | o        | width_g  | N.A           |
