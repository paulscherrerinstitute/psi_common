<img align="right" src="../psi_logo.png">

***

[**component list**](../README.md)

# psi_common_dont_opt
 - VHDL source: [psi_common_dont_opt](../../hdl/psi_common_dont_opt.vhd)
 - Testbench source: [psi_common_dont_opt_tb.vhd](../../testbench/psi_common_dont_opt_tb/psi_common_dont_opt_tb.vhd)

### Description

This component is used to do test-implementations (to check timing or resource consumption) for entities that have more I/Os than any
available chip. All I/Os of the component to do the test-implementation are connected to *psi\_common\_dont\_opt* entity ("Virtual Pin"). The
*psi\_common\_dont\_opt* entity itself has four pins that must be routed to I/Os. The logic inside *psi\_common\_dont\_opt* prevents any I/Os of
the component under test to be optimized away by the synthesis tools.

### Generics
| Name             | type     | Description   |
|:-----------------|:---------|:--------------|
| from_dut_width_g | positive | Number of device under test output bits (going to *psi\_common\_dont\_opt*)        |
| to_dut_width_g   | positive | Number of device under test input bits (connected to *psi\_common\_dont\_opt*)     |

### Interfaces
| Name   | In/Out   | Length           | Description                |
|:-------|:---------|:-----------------|:---------------------------|
| clk_i  | i        | 1                | system Clock							  |
| pin_io | i        | 4                | I/O pins required to prevent optimization             |
| dat_o  | o        | to_dut_width_g   | Signals from DUT to *psi\_common\_dont\_opt*          |
| dat_i  | i        | from_dut_width_g | Signals from *psi\_common\_dont\_opt to DUT*          |


[**component list**](../README.md)
