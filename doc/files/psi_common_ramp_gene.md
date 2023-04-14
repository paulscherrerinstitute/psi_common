<img align="right" src="../doc/psi_logo.png">

***

[**component list**](../README.md)

# psi_common_ramp_gene
 - VHDL source: [psi_common_ramp_gene](../../hdl/psi_common_ramp_gene.vhd)
 - Testbench source: [psi_common_ramp_gene_tb.vhd](../../testbench/psi_common_ramp_gene_tb/psi_common_ramp_gene_tb.vhd)

### Description

This component implements a ramp generator where the user can set the target level to reach and the step number prior to reach this level. It can from a certain value either continue ramping up either ramping down as the figure below shows. The direction is selected with the next value to reach, if current value is higher than previous one then it ramps up and opposite.
Orignally the block handled only unsigned value and now can asapt to signed via generics.

<p align="center"><img src="psi_common_ramp_gene_fig0.png"></p>

### Generics
| Name            | type      | Description                   |
|:----------------|:----------|:------------------------------|
| generic(width_g | natural   | accumulator width             |
| is_sign_g       | boolean   | sign / unsign                 |
| rst_pol_g       | std_logic | polarity reset                |
| init_val_g      | integer   | init output value at start-up |

### Interfaces
| Name       | In/Out   | Length    | Description                                             |
|:-----------|:---------|:----------|:--------------------------------------------------------|
| clk_i      | i        | 1         | system clock                                            |
| rst_i      | i        | 1         | sync reset                                              |
| str_i      | i        | 1         | strobe input                                            |
| tgt_lvl_i  | i        | width_g   | target pulse level                                      |
| ramp_inc_i | i        | positive, | steepness of the ramp (positive, also for ramping down) |
| ramp_cmd_i | i        | 1         | start ramping                                           |
| init_cmd_i | i        | 1         | go to init whatever state                               |
| sts_o      | o        | 1         | fsm status                                              |
| str_o      | o        | 1         | pulse strobe output                                     |
| puls_o     | o        | width_g   | pulse value                                             |


[**component list**](../README.md)
