<img align="right" src="../doc/psi_logo.png">
***

# psi_common_sp_ram_be
 - VHDL source: [psi_common_sp_ram_be](C:/Users/stef_b/git/GFA/Libraries/Firmware/VHDL/psi_common/hdl/psi_common_sp_ram_be.vhd)
 - Testbench source: [psi_common_sp_ram_be_tb.vhd](../testbench/psi_common_sp_ram_be_tb/psi_common_sp_ram_be_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name           | type     | Description                                          |
|:---------------|:---------|:-----------------------------------------------------|
| depth_g        | positive | N.A                                                  |
| width_g        | positive | N.A                                                  |
| ram_behavior_g | string   | "rbw" = read-before-write, "wbr" = write-before-read |

### Interfaces
| Name   | In/Out   | Length   | Description   |
|:-------|:---------|:---------|:--------------|
| dat_o  | o        | width_g  | N.A           |