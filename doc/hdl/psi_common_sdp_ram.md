<img align="right" src="../doc/psi_logo.png">
***

# psi_common_sdp_ram
 - VHDL source: [psi_common_sdp_ram](C:/Users/stef_b/git/GFA/Libraries/Firmware/VHDL/psi_common/hdl/psi_common_sdp_ram.vhd)
 - Testbench source: [psi_common_sdp_ram_tb.vhd](../testbench/psi_common_sdp_ram_tb/psi_common_sdp_ram_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name           | type     | Description                                                  |
|:---------------|:---------|:-------------------------------------------------------------|
| depth_g        | positive | N.A                                                          |
| width_g        | positive | N.A                                                          |
| is_async_g     | boolean  | true = separate rd clock is used (clk is wrclk in this case) |
| ram_style_g    | string   | "auto", "distributed" or "block"                             |
| ram_behavior_g | string   | "rbw" = read-before-write, "wbr" = write-before-read         |

### Interfaces
| Name     | In/Out   | Length   | Description   |
|:---------|:---------|:---------|:--------------|
| rd_dat_o | o        | width_g  | N.A           |