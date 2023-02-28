<img align="right" src="../psi_logo.png">

***

[**component list**](../README.md)

# psi_common_tickgenerator
 - VHDL source: [psi_common_tickgenerator](../../hdl/psi_common_tickgenerator.vhd)
 - Testbench source: [psi_common_tickgenerator_tb.vhd](../../testbench/psi_common_tickgenerator_tb/psi_common_tickgenerator_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name                     | type    | Description                                                                                        |
|:-------------------------|:--------|:---------------------------------------------------------------------------------------------------|
| clk_in_mhz_g             | integer | N.A                                                                                                |
| tick_width_g             | integer | N.A                                                                                                |
| sim_sec_speedup_factor_g | integer | set to 1 for implementation!!! speedup factor for simulation, does only apply to sec, not to us/ms |

### Interfaces
| Name       | In/Out   |   Length | Description   |
|:-----------|:---------|---------:|:--------------|
| clock_i    | i        |        1 | N.A           |
| tick1us_o  | o        |        1 | N.A           |
| tick1ms_o  | o        |        1 | N.A           |
| tick1sec_o | o        |        1 | N.A           |
