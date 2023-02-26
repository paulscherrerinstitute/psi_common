<img align="right" src="../doc/psi_logo.png">
***

# psi_common_sync_fifo
 - VHDL source: [psi_common_sync_fifo](C:/Users/stef_b/git/GFA/Libraries/Firmware/VHDL/psi_common/hdl/psi_common_sync_fifo.vhd)
 - Testbench source: [psi_common_sync_fifo_tb.vhd](../testbench/psi_common_sync_fifo_tb/psi_common_sync_fifo_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name              | type      | Description                                                                                        |
|:------------------|:----------|:---------------------------------------------------------------------------------------------------|
| width_g           | positive  | width                                                                                              |
| depth_g           | positive  | depth                                                                                              |
| alm_full_on_g     | boolean   | almost full signal active                                                                          |
| alm_full_level_g  | natural   | almost full level threshold val                                                                    |
| alm_empty_on_g    | boolean   | almost empty signal active                                                                         |
| alm_empty_level_g | natural   | almost empty level threshold val                                                                   |
| ram_style_g       | string    | ram style selected -> "auto" choose depedning size block-ram or dist-ram | "distributed" | "block" |
| ram_behavior_g    | string    | "rbw" = read-before-write, "wbr" = write-before-read                                               |
| rdy_rst_state_g   | std_logic | use '1' for minimal logic on rdy path                                                              |
| rst_pol_g         | std_logic | N.A                                                                                                |

### Interfaces
| Name        | In/Out   | Length   | Description                           |
|:------------|:---------|:---------|:--------------------------------------|
| clk_i       | i        | 1        | clock in                              |
| rst_i       | i        | 1        | system reset                          |
| dat_i       | i        | width_g  | data input                            |
| vld_i       | i        | 1        | axi-s handshaking signal | strobe in  |
| rdy_o       | o        | 1        | axi-s handshaking signal | not full   |
| dat_o       | o        | width_g  | read data                             |
| vld_o       | o        | 1        | axi-s handshaking signal | strobe out |
| rdy_i       | i        | 1        | axi-s handshaking signal | not empty  |
| full_o      | o        | 1        | fifo full                             |
| alm_full_o  | o        | 1        | fifo almost full                      |
| in_level_o  | o        | depth_g  | fifo in level                         |
| empty_o     | o        | 1        | fifo empty                            |
| alm_empty_o | o        | 1        | fifo almost empty                     |
| out_level_o | o        | depth_g  | fifo out leve                         |