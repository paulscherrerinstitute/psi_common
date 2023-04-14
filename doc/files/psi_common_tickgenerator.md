<img align="right" src="../psi_logo.png">

***

[**component list**](../README.md)

# psi_common_tickgenerator
 - VHDL source: [psi_common_tickgenerator](../../hdl/psi_common_tickgenerator.vhd)
 - Testbench source: [psi_common_tickgenerator_tb.vhd](../../testbench/psi_common_tickgenerator_tb/psi_common_tickgenerator_tb.vhd)

### Description

This component generated pulses at the commonly used time bases in a system (second, millisecond, microsecond) based on the clock frequency. The width of the tick-pulses is configurable.

### Generics
| Name                     | type    | Description                                                                                        |
|:-------------------------|:--------|:---------------------------------------------------------------------------------------------------|
| clk_in_mhz_g             | integer | clock frequency in MHz                                                                             |
| tick_width_g             | integer | pulse length                                                                                       |
| sim_sec_speedup_factor_g | integer | set to 1 for implementation!!! speedup factor for simulation, does only apply to sec, not to us/ms |

### Interfaces
| Name       | In/Out   |   Length | Description   |
|:-----------|:---------|---------:|:--------------|
|clock\_i     |Input      |1      |Clock input
|tick1us\_o   |Output     |1      |Microsecond tick output
|tick1ms\_o   |Output     |1      |Millisecond tick output
|tick1sec\_o  |Output     |1      |Second tick output
