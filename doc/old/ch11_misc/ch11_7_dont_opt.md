<img align="right" src="../psi_logo.png">

***
# psi_common_dont_opt

- VHDL source: [psi_common_dont_opt.vhd](../../hdl/psi_common_dont_opt.vhd)
- Testbench:  **_not applicable_**

### Description

This component is used to do test-implementations (to check timing or
resource consumption) for entities that have more I/Os than any
available chip. All I/Os of the component to do the test-implementation
are connected to *psi\_common\_dont\_opt* entity ("Virtual Pin"). The
*psi\_common\_dont\_opt* entity itself has four pins that must be routed
to I/Os. The logic inside *psi\_common\_dont\_opt* prevents any I/Os of
the component under test to be optimized away by the synthesis tools.

### Generics

generics						| Description
--------------------|---------------------------
**FromDutWidth\_g** |Number of device under test output bits (going to *psi\_common\_dont\_opt*)\
**ToDutWidth\_g** | Number of device under test input bits (connected to *psi\_common\_dont\_opt*)

### Interfaces

Signal                      |Direction  |Width            |Description
----------------------------|-----------|-----------------|----------------------------------------------
***Control Signals***       |           |                 |
Clk                         |Input      |1                |Clock
***Device I/Os required***  |           |                 |
IoPins                      |Bidir      |4                |I/O pins required to prevent optimization
***DUT Connection***        |           |                 |
FromDut                     |Input      |FromDutWidth\_g  |Signals from DUT to *psi\_common\_dont\_opt*
ToDut                       |Output     |ToDutWidth\_g    |Signals from *psi\_common\_dont\_opt to DUT*


***
[Index](../psi_common_index.md) **|** Previous: [Misc > watchdog](../ch11_misc/ch11_6_watchdog.md) **|** Next: [Misc > debouncer](../ch11_misc/ch11_8_debouncer.md)
