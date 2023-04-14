<img align="right" src="../psi_logo.png">

***

[**component list**](../README.md)

# psi_common_axi_multi_pl_stage
 - VHDL source: [psi_common_axi_multi_pl_stage](../../hdl/psi_common_axi_multi_pl_stage.vhd)
 - Testbench source: [psi_common_axi_multi_pl_stage_tb.vhd](../../testbench/psi_common_axi_multi_pl_stage_tb/psi_common_axi_multi_pl_stage_tb.vhd)

### Description

 This entity implements multiple pipeline stages for an axi mm slave interface.

### Generics
| Name         | type      | Description   			 |
|:-------------|:----------|:--------------------|
| addr_width_g | positive  | address width       |
| data_width_g | positive  | data width          |
| stages_g     | positive  | number pl           |
| rst_pol_g    | std_logic | polarity reset      |

### Interfaces
| Name        | In/Out   | Length       | Description                  |
|:------------|:---------|:-------------|:-----------------------------|
| clk_i       | i        | 1            | clock system 								 |
| rst_i       | i        | 1            | reset system      					 |
***AXI  Interface***  |          |                                     |
|\_Axi\_\*    |\*        |\*                            |AXI signals, see AXI specification

[**component list**](../README.md)
